---
layout: post
title: "Build a News recommendation app from python with Vespa: Part 3"
date: '2021-05-20'
tags: []
author: thigm85
image: assets/2021-05-20-news-recommendation-with-parent-child-relationship/figure_1.jpg
image_credit: 'Photo by <a href="https://unsplash.com/@freegraphictoday?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">AbsolutVision</a> on <a href="https://unsplash.com/photos/bSlHKWxxXak?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>'
skipimage: true
excerpt: Part 3 - Efficient use of click-through rate via parent-child relationship.
---

**Part 3 - Efficient use of click-through rate via parent-child relationship.**

**UPDATE 2023-02-14:** Code examples are updated to work with the latest releases of
[pyvespa](https://pyvespa.readthedocs.io/en/latest/index.html).

This part of the series introduces a new ranking signal: category click-through rate (CTR). The idea is that we can recommend popular content for users that don’t have a click history yet. Rather than just recommending based on articles, we recommend based on categories. However, these global CTR values can often change continuously, so we need an efficient way to update this value for all documents. We’ll do that by introducing parent-child relationships between documents in Vespa. We will also use sparse tensors directly in ranking. This post replicates [this more detailed Vespa tutorial](https://docs.vespa.ai/en/tutorials/news-7-recommendation-with-parent-child.html).

![Decorative image](/assets/2021-05-20-news-recommendation-with-parent-child-relationship/figure_1.jpg)
<p class="image-credit">Photo by <a href="https://unsplash.com/@freegraphictoday?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">AbsolutVision</a> on <a href="https://unsplash.com/s/photos/news?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a></p>


We assume that you have followed the [part2 of the news recommendation tutorial](https://blog.vespa.ai/build-news-recommendation-app-from-python-with-vespa/). Therefore, you should have an `app_package` variable holding the news app definition and a Docker container named `news` running the application fed with data from the demo version of the MIND dataset.

## Setting up a global category CTR document

If we add a `category_ctr` field in the `news` document, we would have to update all the sport's documents every time there is a change in the sport's CTR statistic. If we assume that the category CTR will change often, this turns out to be inefficient.

For these cases, Vespa introduced [the parent-child relationship](https://docs.vespa.ai/en/parent-child.html). Parents are global documents, which are automatically distributed to all content nodes. Other documents can reference these parents and “import” values for use in ranking. The benefit is that the global category CTR values only need to be written to one place: the global document.


```python
from vespa.package import Schema, Document, Field

app_package.add_schema(
    Schema(
        name="category_ctr",
        global_document=True,
        document=Document(
            fields=[
                Field(
                    name="ctrs", 
                    type="tensor<float>(category{})", 
                    indexing=["attribute"], 
                    attribute=["fast-search"]
                ), 
            ]
        )
    )
)
```

We implement that by creating a new `category_ctr` schema and setting `global_document=True` to indicate that we want Vespa to keep a copy of these documents on all content nodes. Setting a document to be global is required for using it in a parent-child relationship. Note that we use a tensor with a single sparse dimension to hold the `ctrs` data.

Sparse tensors have strings as dimension addresses rather than a numeric index. More concretely, an example of such a tensor is (using the [tensor literal form](https://docs.vespa.ai/en/reference/tensor.html#tensor-literal-form)):

```
{
    {category: entertainment}: 0.2 }, 
    {category: news}: 0.3 },
    {category: sports}: 0.5 },
    {category: travel}: 0.4 },
    {category: finance}: 0.1 },
    ...
}
```

This tensor holds all the CTR scores for all the categories. When updating this tensor, we can update individual cells, and we don’t need to update the whole tensor. This operation is called [tensor modify](https://docs.vespa.ai/en/reference/document-json-format.html#tensor-modify) and can be helpful when you have large tensors.

## Importing parent values in child documents

We need to set up two things to use the `category_ctr` tensor for ranking `news` documents. We need to reference the parent document (`category_ctr` in this case) and import the `ctrs` from the referenced parent document.


```python
app_package.get_schema("news").add_fields(
    Field(
        name="category_ctr_ref",
        type="reference<category_ctr>",
        indexing=["attribute"],
    )
)
```

The field `category_ctr_ref` is a field of type reference of the `category_ctr` document type. When feeding this field, Vespa expects the fully qualified document id. For instance, if our global CTR document has the id `id:category_ctr:category_ctr::global`, that is the value that we need to feed to the `category_ctr_ref` field. A document can reference many parent documents.


```python
from vespa.package import ImportedField

app_package.get_schema("news").add_imported_field(
    ImportedField(
        name="global_category_ctrs",
        reference_field="category_ctr_ref",
        field_to_import="ctrs",
    )
)
```

The imported field defines that we should import the `ctrs` field from the document referenced in the `category_ctr_ref` field. We name this as `global_category_ctrs`, and we can reference this as `attribute(global_category_ctrs)` during ranking.

## Tensor expressions in ranking

Each `news` document has a `category` field of type `string` indicating which category the document belongs to. We want to use this information to select the correct CTR score stored in the `global_category_ctrs`. Unfortunately, tensor expressions only work on tensors, so we need to add a new field of type `tensor` called `category_tensor` to hold category information in a way that can be used in a tensor expression:


```python
app_package.get_schema("news").add_fields(
    Field(
        name="category_tensor",
        type="tensor<float>(category{})",
        indexing=["attribute"],
    )
)
```

With the `category_tensor` field as defined above, we can use the tensor expression `sum(attribute(category_tensor) * attribute(global_category_ctrs))` to select the specific CTR related to the category of the document being ranked. We implement this expression as a `Function` in the rank-profile below:


```python
from vespa.package import Function

app_package.get_schema("news").add_rank_profile(
    RankProfile(
        name="recommendation_with_global_category_ctr", 
        inherits="recommendation",
        functions=[
            Function(
                name="category_ctr", 
                expression="sum(attribute(category_tensor) * attribute(global_category_ctrs))"
            ),
            Function(
                name="nearest_neighbor", 
                expression="closeness(field, embedding)"
            )
            
        ],
        first_phase="nearest_neighbor * category_ctr",
        summary_features=[
            "attribute(category_tensor)", 
            "attribute(global_category_ctrs)", 
            "category_ctr", 
            "nearest_neighbor"
        ]
    )
)
```

In the new rank-profile, we have added a first phase ranking expression that multiplies the nearest-neighbor score with the category CTR score, implemented with the functions `nearest_neighbor` and `category_ctr`, respectively. As a first attempt, we just multiply the nearest-neighbor with the category CTR score, which might not be the best way to combine those two values.

## Deploy

We can reuse the same container named `news` created in the first part of this tutorial.


```python
from vespa.deployment import VespaDocker

vespa_docker = VespaDocker.from_container_name_or_id("news")
app = vespa_docker.deploy(application_package=app_package)
```

    Waiting for configuration server, 0/300 seconds...
    Waiting for configuration server, 5/300 seconds...
    Waiting for application status, 0/300 seconds...
    Waiting for application status, 5/300 seconds...
    Waiting for application status, 10/300 seconds...
    Finished deployment.



## Feed

Next, we will download the global category CTR data, already parsed in the format that is expected by a sparse tensor with the category dimension.


```python
import requests, json

global_category_ctr = json.loads(
    requests.get("https://data.vespa.oath.cloud/blog/news/global_category_ctr_parsed.json").text
)
global_category_ctr
```

    {
        'ctrs': {
            'cells': [
                {'address': {'category': 'entertainment'}, 'value': 0.029266420380943244},
                {'address': {'category': 'autos'}, 'value': 0.028475809103747123},
                {'address': {'category': 'tv'}, 'value': 0.05374837981352176},
                {'address': {'category': 'health'}, 'value': 0.03531784305129329},
                {'address': {'category': 'sports'}, 'value': 0.05611187986670051},
                {'address': {'category': 'music'}, 'value': 0.05471192953054426},
                {'address': {'category': 'news'}, 'value': 0.04420778372641991},
                {'address': {'category': 'foodanddrink'}, 'value': 0.029256852366228187},
                {'address': {'category': 'travel'}, 'value': 0.025144552013730358},
                {'address': {'category': 'finance'}, 'value': 0.03231013195899643},
                {'address': {'category': 'lifestyle'}, 'value': 0.04423279317474416},
                {'address': {'category': 'video'}, 'value': 0.04006693315980292},
                {'address': {'category': 'movies'}, 'value': 0.03335647459420146},
                {'address': {'category': 'weather'}, 'value': 0.04532171803495617},
                {'address': {'category': 'northamerica'}, 'value': 0.0},
                {'address': {'category': 'kids'}, 'value': 0.043478260869565216}
            ]
        }
    }



We can feed this data point to the document defined in the `category_ctr`. We will assign the `global` id to this document. Reference to this document can be done by using the Vespa id `id:category_ctr:category_ctr::global`.


```python
response = app.feed_data_point(schema="category_ctr", data_id="global", fields=global_category_ctr)
```

We need to perform a partial update on the `news` documents to include information about the reference field `category_ctr_ref` and the new `category_tensor` that will have the value `1.0` for the specific category associated with each document.


```python
news_category_ctr = json.loads(
    requests.get("https://data.vespa.oath.cloud/blog/news/news_category_ctr_update_parsed.json").text
)
news_category_ctr[0]
```

    {
        'id': 'N3112',
        'fields': {
            'category_ctr_ref': 'id:category_ctr:category_ctr::global',
            'category_tensor': {
                'cells': [
                    { 'address': {'category': 'lifestyle'}, 'value': 1.0}
                ]
            }
        }
    }


This takes ten minutes or so:

```python
for data_point in news_category_ctr:
    response = app.update_data(schema="news", data_id=data_point["id"], fields=data_point["fields"])
```

## Testing the new rank-profile

We will redefine the `query_user_embedding` function defined in the second part of this tutorial and use it to make a query involving the user `U33527` and the `recommendation_with_global_category_ctr` rank-profile.


```python
def parse_embedding(hit_json):
    embedding_json = hit_json["fields"]["embedding"]["values"]
    embedding_vector = [0.0] * len(embedding_json)
    i=0
    for val in embedding_json:
        embedding_vector[i] = val
        i+=1
    return embedding_vector

def query_user_embedding(user_id):
    result = app.query(body={"yql": "select * from sources user where user_id contains '{}'".format(user_id)})
    embedding = parse_embedding(result.hits[0])
    return embedding
```


```python
yql = "select * from sources news where " \
      "({targetHits:10}nearestNeighbor(embedding, user_embedding))"
result = app.query(
    body={
        "yql": yql,        
        "hits": 10,
        "ranking.features.query(user_embedding)": str(query_user_embedding(user_id="U33527")),
        "ranking.profile": "recommendation_with_global_category_ctr"
    }
)
```

The first hit below is a sports article. The global CTR document is also listed here, and the CTR score for the sports category is `0.0561`. Thus, the result of the category_ctr function is `0.0561` as intended. The nearest_neighbor score is `0.149`, and the resulting relevance score is `0.00836`. So, this worked as expected.


```python
result.hits[0]
```

    {
        'id': 'id:news:news::N5316',
        'relevance': 0.008369192847921151,
        'source': 'news_content',
        'fields': {
            'sddocname': 'news',
            'documentid': 'id:news:news::N5316',
            'news_id': 'N5316',
            'category': 'sports',
            'subcategory': 'football_nfl',
            'title': "Matthew Stafford's status vs. Bears uncertain, Sam Martin will play",
            'abstract': "Stafford's start streak could be in jeopardy, according to Ian Rapoport.",
            'url': "https://www.msn.com/en-us/sports/football_nfl/matthew-stafford's-status-vs.-bears-uncertain,-sam-martin-will-play/ar-BBWwcVN?ocid=chopendata",
            'date': 20191112,
            'clicks': 0,
            'impressions': 1,
            'summaryfeatures': {
                'attribute(category_tensor)': {
                    'type': 'tensor<float>(category{})',
                    'cells': [
                        {'address': {'category': 'sports'}, 'value': 1.0}
                    ]
                },
                'attribute(global_category_ctrs)': {
                    'type': 'tensor<float>(category{})',
                    'cells': [
                        {'address': {'category': 'entertainment'}, 'value': 0.029266420751810074},
                        {'address': {'category': 'autos'}, 'value': 0.0284758098423481},
                        {'address': {'category': 'tv'}, 'value': 0.05374838039278984},
                        {'address': {'category': 'health'}, 'value': 0.03531784191727638},
                        {'address': {'category': 'sports'}, 'value': 0.05611187964677811},
                        {'address': {'category': 'music'}, 'value': 0.05471193045377731},
                        {'address': {'category': 'news'}, 'value': 0.04420778527855873},
                        {'address': {'category': 'foodanddrink'}, 'value': 0.029256852343678474},
                        {'address': {'category': 'travel'}, 'value': 0.025144552811980247},
                        {'address': {'category': 'finance'}, 'value': 0.032310131937265396},
                        {'address': {'category': 'lifestyle'}, 'value': 0.044232793152332306},
                        {'address': {'category': 'video'}, 'value': 0.040066931396722794},
                        {'address': {'category': 'movies'}, 'value': 0.033356472849845886},
                        {'address': {'category': 'weather'}, 'value': 0.045321717858314514},
                        {'address': {'category': 'northamerica'}, 'value': 0.0},
                        {'address': {'category': 'kids'}, 'value': 0.043478261679410934}
                    ]
                },
                'rankingExpression(category_ctr)': 0.05611187964677811,
                'rankingExpression(nearest_neighbor)': 0.14915188666574342,
                'vespa.summaryFeatures.cached': 0.0
            }
        }
    }



## Conclusion

This tutorial introduced parent-child relationships and demonstrated it through a global CTR feature we used in ranking. We also introduced ranking with (sparse) tensor expressions.

Clean up Docker container instances:
```python
vespa_docker.container.stop()
vespa_docker.container.remove()
```

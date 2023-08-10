---
layout: post
title: "Build a News recommendation app from python with Vespa: Part 2"
date: '2021-03-29'
tags: []
author: thigm85
image: assets/2021-03-29-build-news-recommendation-app-from-python-with-vespa/figure_1.jpg
image_credit: 'Photo by <a href="https://unsplash.com/@mattpopovich?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Matt Popovich</a> on <a href="https://unsplash.com/photos/wajusTqz_FI?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>'
skipimage: true
excerpt: Part 2 - From news search to news recommendation with embeddings.
---

**Part 2 - From news search to news recommendation with embeddings.**

**UPDATE 2023-02-14:** Code examples are updated to work with the latest releases of
[pyvespa](https://pyvespa.readthedocs.io/en/latest/index.html).

In this part, we'll start transforming our application from news search to news recommendation using the embeddings created in [this tutorial](https://docs.vespa.ai/en/tutorials/news-4-embeddings.html). An embedding vector will represent each user and news article. We will make the embeddings used available for download to make it easier to follow this post along. When a user comes, we retrieve his embedding and use it to retrieve the closest news articles via an approximate nearest neighbor (ANN) search. We also show that Vespa can jointly apply general filtering and ANN search, unlike competing alternatives available in the market.

![Decorative image](/assets/2021-03-29-build-news-recommendation-app-from-python-with-vespa/figure_1.jpg)
<p class="image-credit">Photo by <a href="https://unsplash.com/@mattpopovich?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Matt Popovich</a> on <a href="https://unsplash.com/s/photos/good-news-is-coming?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a></p>

We assume that you have followed [the news search tutorial](https://blog.vespa.ai/build-news-search-app-from-python-with-vespa/). Therefore, you should have an `app_package` variable holding the news search app definition and a Docker container named `news` running a search application fed with news articles from the demo version of the MIND dataset.

## Add a user schema

We need to add another document type to represent a user. We set up the schema to search for a `user_id` and retrieve the user’s embedding vector.


```python
from vespa.package import Schema, Document, Field

app_package.add_schema(
    Schema(
        name="user", 
        document=Document(
            fields=[
                Field(
                    name="user_id", 
                    type="string", 
                    indexing=["summary", "attribute"], 
                    attribute=["fast-search"]
                ), 
                Field(
                    name="embedding", 
                    type="tensor<float>(d0[51])", 
                    indexing=["summary", "attribute"]
                )
            ]
        )
    )
)
```

We build an index for the attribute field `user_id` by specifying the `fast-search` attribute. Remember that attribute fields are held in memory and are not indexed by default.

The embedding field is a tensor field. Tensors in Vespa are flexible multi-dimensional data structures and, as first-class citizens, can be used in queries, document fields, and constants in ranking. Tensors can be either dense or sparse or both and can contain any number of dimensions. Please see the [tensor user guide](https://docs.vespa.ai/en/tensor-user-guide.html) for more information. Here we have defined a dense tensor with a single dimension (`d0` - dimension 0), representing a vector. 51 is the size of the embeddings used in this post.

We now have one schema for the `news` and one schema for the `user`.


```python
[schema.name for schema in app_package.schemas]
```




    ['news', 'user']



### Index news embeddings

Similarly to the user schema, we will use a dense tensor to represent the news embeddings. But unlike the user embedding field, we will index the news embedding by including `index` in the `indexing` argument and specify that we want to build the index using the HNSW (hierarchical navigable small world) algorithm. The distance metric used is euclidean. Read [this blog post](https://blog.vespa.ai/approximate-nearest-neighbor-search-in-vespa-part-1/) to know more about Vespa’s journey to implement ANN search.


```python
from vespa.package import Field, HNSW

app_package.get_schema(name="news").add_fields(
    Field(
        name="embedding", 
        type="tensor<float>(d0[51])", 
        indexing=["attribute", "index"],
        ann=HNSW(distance_metric="euclidean")
    )
)
```

## Recommendation using embeddings

Here, we’ve added a ranking expression using the closeness ranking feature, which calculates the euclidean distance and uses that to rank the news articles. This rank-profile depends on using the nearestNeighbor search operator, which we’ll get back to below when searching. But for now, this expects a tensor in the query to use as the initial search point.


```python
from vespa.package import RankProfile

app_package.get_schema(name="news").add_rank_profile(
    RankProfile(
        name="recommendation", 
        inherits="default", 
        first_phase="closeness(field, embedding)"
    )
)
```

## Query Profile Type

The recommendation rank profile above requires that we send a tensor along with the query. For Vespa to bind the correct types, it needs to know the expected type of this query parameter.


```python
from vespa.package import QueryTypeField

app_package.query_profile_type.add_fields(
    QueryTypeField(
        name="ranking.features.query(user_embedding)",
        type="tensor<float>(d0[51])"
    )
)
```

This query profile type instructs Vespa to expect a float tensor with dimension `d0[51]` when the query parameter ranking.features.query(user_embedding) is passed. We’ll see how this works together with the nearestNeighbor search operator below.

## Redeploy the application

We made all the required changes to turn our news search app into a news recommendation app. We can now redeploy the `app_package` to our running container named `news`.


```python
from vespa.deployment import VespaDocker

vespa_docker = VespaDocker.from_container_name_or_id("news")
app = vespa_docker.deploy(application_package=app_package)
```

    Waiting for configuration server, 0/300 seconds...
    Waiting for configuration server, 5/300 seconds...
    Waiting for application status, 0/300 seconds...
    Waiting for application status, 5/300 seconds...
    Finished deployment.


```python
app.deployment_message
```




    ["Uploading application '/app/application' using http://localhost:19071/application/v2/tenant/default/session",
     "Session 7 for tenant 'default' created.",
     'Preparing session 7 using http://localhost:19071/application/v2/tenant/default/session/7/prepared',
     "WARNING: Host named 'news' may not receive any config since it is not a canonical hostname. Disregard this warning when testing in a Docker container.",
     "Session 7 for tenant 'default' prepared.",
     'Activating session 7 using http://localhost:19071/application/v2/tenant/default/session/7/active',
     "Session 7 for tenant 'default' activated.",
     'Checksum:   62d964000c4ff4a5280b342cd8d95c80',
     'Timestamp:  1616671116728',
     'Generation: 7',
     '']



## Feeding and partial updates: news and user embeddings

To keep this tutorial easy to follow, we make the parsed embeddings available for download. To build them yourself, please follow [this tutorial](https://docs.vespa.ai/en/tutorials/news-4-embeddings.html).


```python
import requests, json

user_embeddings = json.loads(
    requests.get("https://thigm85.github.io/data/mind/mind_demo_user_embeddings_parsed.json").text
)
news_embeddings = json.loads(
    requests.get("https://thigm85.github.io/data/mind/mind_demo_news_embeddings_parsed.json").text
)
```

We just created the `user` schema, so we need to feed user data for the first time.


```python
for user_embedding in user_embeddings:
    response = app.feed_data_point(
        schema="user", 
        data_id=user_embedding["user_id"], 
        fields=user_embedding
    )
```

For the news documents, we just need to update the `embedding` field added to the `news` schema.
This takes ten minutes or so:

```python
for news_embedding in news_embeddings:
    response = app.update_data(
        schema="news", 
        data_id=news_embedding["news_id"], 
        fields={"embedding": news_embedding["embedding"]}
    )
```

## Fetch the user embedding

Next, we create a `query_user_embedding` function to retrieve the user `embedding` by the `user_id`. Of course, you could do this more efficiently using a Vespa Searcher as described [here](https://docs.vespa.ai/en/tutorials/news-6-recommendation-with-searchers.html), but keeping everything in python at this point makes learning easier.


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

The function will query Vespa, retrieve the embedding and parse it into a list of floats. Here are the first five elements of the user `U63195`'s embedding.


```python
query_user_embedding(user_id="U63195")[:5]
```

    [
        0.0,
        -0.1694680005311966,
        -0.0703359991312027,
        -0.03539799898862839,
        0.14579899609088898
    ]



## Get recommendations

### ANN search

The following `yql` instructs Vespa to select the `title` and the `category` from the ten news documents closest to the user embedding.


```python
yql = "select title, category from sources news where ({targetHits:10}nearestNeighbor(embedding, user_embedding))" 
```

We also specify that we want to rank those documents by the `recommendation` rank-profile that we defined earlier and send the user embedding via the query profile type `ranking.features.query(user_embedding)` that we also defined in our `app_package`.  


```python
result = app.query(
    body={
        "yql": yql,        
        "hits": 10,
        "ranking.features.query(user_embedding)": str(query_user_embedding(user_id="U63195")),
        "ranking.profile": "recommendation"
    }
)
```

Here are the first two hits out of the ten returned.


```python
result.hits[0:2]
```

    [
        {
            'id': 'index:news_content/0/aca03f4ba2274dd95b58db9a',
            'relevance': 0.1460561756063909,
            'source': 'news_content',
            'fields': {
                'category': 'music',
                'title': 'Broadway Star Laurel Griggs Suffered Asthma Attack Before She Died at Age 13'
            }
        },
        {
            'id': 'index:news_content/0/bd02238644c604f3a2d53364',
            'relevance': 0.14591827245062294,
            'source': 'news_content',
            'fields': {
                'category': 'tv',
                'title': "Rip Taylor's Cause of Death Revealed, Memorial Service Scheduled for Later This Month"
            }
        }
    ]



### Combine ANN search with query filters

Vespa ANN search is fully integrated into the Vespa query tree. This integration means that we can include query filters and the ANN search will be applied only to documents that satisfy the filters. No need to do pre- or post-processing involving filters.

The following `yql`  search over news documents that have `sports` as their category.


```python
yql = "select title, category from sources news where " \
      "({targetHits:10}nearestNeighbor(embedding, user_embedding)) AND " \
      "category contains 'sports'"
```


```python
result = app.query(
    body={
        "yql": yql,        
        "hits": 10,
        "ranking.features.query(user_embedding)": str(query_user_embedding(user_id="U63195")),
        "ranking.profile": "recommendation"
    }
)
```

Here are the first two hits out of the ten returned. Notice the `category` field.


```python
result.hits[0:2]
```

    [
        {
            'id': 'index:news_content/0/375ea340c21b3138fae1a05c',
            'relevance': 0.14417346200569972,
            'source': 'news_content',
            'fields': {
                'category': 'sports',
                'title': 'Charles Rogers, former Michigan State football, Detroit Lions star, dead at 38'
            }
        },
        {
            'id': 'index:news_content/0/2b892989020ddf7796dae435',
            'relevance': 0.14404365847394848,
            'source': 'news_content',
            'fields': {
                'category': 'sports',
                'title': "'Monday Night Football' commentator under fire after belittling criticism of 49ers kicker for missed field goal"
            }
        }
    ]



## Next steps
See [conclusion](https://blog.vespa.ai/news-recommendation-with-parent-child-relationship#conclusion)
for how to clean up the Docker container instances,
or step to [part 3](https://blog.vespa.ai/news-recommendation-with-parent-child-relationship/).

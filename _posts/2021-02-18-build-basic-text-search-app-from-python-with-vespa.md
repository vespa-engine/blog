---
layout: post
title: "Build a basic text search application from python with Vespa"
date: '2021-02-18'
tags: []
author: thigm85
image: assets/2021-02-18-build-basic-text-search-app-from-python-with-vespa/figure_1.jpg
skipimage: true
excerpt: Introducing pyvespa simplified API. Build Vespa application from python with few lines of code.
---

**Introducing pyvespa simplified API. Build Vespa application from python with few lines of code.**

This post will introduce you to the simplified `pyvespa` API that allows us to build a basic text search application from scratch with just a few code lines from python. Follow-up posts will add layers of complexity by incrementally building on top of the basic app described here.

![Decorative image](/assets/2021-02-18-build-basic-text-search-app-from-python-with-vespa/figure_1.jpg)
<p class="image-credit">Photo by <a href="https://unsplash.com/@sarahdorweiler?utm_source=unsplash&amp;utm_medium=referral&amp;utm_content=creditCopyText">Sarah Dorweiler</a> on <a href="https://unsplash.com/s/photos/simple?utm_source=unsplash&amp;utm_medium=referral&amp;utm_content=creditCopyText">Unsplash</a></p>

`pyvespa` exposes a subset of [Vespa](https://vespa.ai/) API in python. The library’s primary goal is to allow for faster prototyping and facilitate Machine Learning experiments for Vespa applications. I have written about how we can use it to [connect and interact with running Vespa applications](https://towardsdatascience.com/how-to-connect-and-interact-with-search-applications-from-python-520118139f69) and [evaluate Vespa ranking functions from python](https://towardsdatascience.com/how-to-evaluate-vespa-ranking-functions-from-python-7749650f6e1a). This time, we focus on building and deploying applications from scratch.

## Install

The pyvespa simplified API introduced here was released in version `0.2.0`

`pip3 install pyvespa>=0.2.0`

## Define the application

As an example, we will build an application to search through
<a href="https://ir.nist.gov/covidSubmit/data.html" data-proofer-ignore>CORD19 sample data</a>.

### Create an application package

The first step is to create a Vespa [ApplicationPackage](https://pyvespa.readthedocs.io/en/latest/reference-api.html#vespa.package.ApplicationPackage):


```python
from vespa.package import ApplicationPackage

app_package = ApplicationPackage(name="cord19")
```

### Add fields to the Schema

We can then add [fields](https://pyvespa.readthedocs.io/en/latest/reference-api.html#vespa.package.Field) to the application's [Schema](https://pyvespa.readthedocs.io/en/latest/reference-api.html#vespa.package.Schema) created by default in `app_package`.


```python
from vespa.package import Field

app_package.schema.add_fields(
    Field(
        name = "cord_uid", 
        type = "string", 
        indexing = ["attribute", "summary"]
    ),
    Field(
        name = "title", 
        type = "string", 
        indexing = ["index", "summary"], 
        index = "enable-bm25"
    ),
    Field(
        name = "abstract", 
        type = "string", 
        indexing = ["index", "summary"], 
        index = "enable-bm25"
    )
)
```

* `cord_uid` will store the cord19 document ids, while `title` and `abstract` are self explanatory. 

* All the fields, in this case, are of type `string`. 

* Including `"index"` in the `indexing` list means that Vespa will create a searchable index for `title` and `abstract`. You can read more about which options is available for `indexing` in the [Vespa documentation](https://docs.vespa.ai/en/reference/schema-reference.html#indexing). 

* Setting `index = "enable-bm25"` makes Vespa pre-compute quantities to make it fast to compute the bm25 score. We will use BM25 to rank the documents retrieved.

### Search multiple fields when querying

A [Fieldset](https://pyvespa.readthedocs.io/en/latest/reference-api.html#vespa.package.FieldSet) groups fields together for searching. For example, the `default` fieldset defined below groups `title` and `abstract` together.


```python
from vespa.package import FieldSet

app_package.schema.add_field_set(
    FieldSet(name = "default", fields = ["title", "abstract"])
)
```

### Define how to rank the documents matched

We can specify how to rank the matched documents by defining a [RankProfile](https://pyvespa.readthedocs.io/en/latest/reference-api.html#vespa.package.RankProfile). In this case, we defined the `bm25` rank profile that combines that BM25 scores computed over the `title` and `abstract` fields. 


```python
from vespa.package import RankProfile

app_package.schema.add_rank_profile(
    RankProfile(
        name = "bm25", 
        first_phase = "bm25(title) + bm25(abstract)"
    )
)
```

## Deploy your application

We have now defined a basic text search app containing relevant fields, a fieldset to group fields together, and a rank profile to rank matched documents. It is time to deploy our application. We can locally deploy our `app_package` using Docker without leaving the notebook, by creating an instance of [VespaDocker](https://pyvespa.readthedocs.io/en/latest/reference-api.html#vespa.package.VespaDocker), as shown below:


```python
from vespa.package import VespaDocker

vespa_docker = VespaDocker(port=8080)

app = vespa_docker.deploy(
    application_package = app_package,
    disk_folder="/Users/username/cord19_app"
)
```

    Waiting for configuration server.
    Waiting for configuration server.
    Waiting for configuration server.
    Waiting for configuration server.
    Waiting for configuration server.
    Waiting for configuration server.
    Waiting for application status.


`app` now holds a [Vespa](https://pyvespa.readthedocs.io/en/latest/reference-api.html#vespa.application.Vespa) instance, which we are going to use to interact with our application. Congratulations, you now have a Vespa application up and running.

It is important to know that `pyvespa` simply provides a convenient API to define Vespa application packages from python. `vespa_docker.deploy` export Vespa configuration files to the `disk_folder` defined above. Going through those files is an excellent way to start learning about Vespa syntax.

## Feed some data

Our first action after deploying a Vespa application is usually to feed some data to it. To make it easier to follow, we have prepared a `DataFrame` containing 100 rows and the `cord_uid`, `title`, and `abstract` columns required by our schema definition.


```python
from pandas import read_csv

parsed_feed = read_csv(
    "https://thigm85.github.io/data/cord19/parsed_feed_100.csv"
)
```


```python
parsed_feed
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>cord_uid</th>
      <th>title</th>
      <th>abstract</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>ug7v899j</td>
      <td>Clinical features of culture-proven Mycoplasma...</td>
      <td>OBJECTIVE: This retrospective chart review des...</td>
    </tr>
    <tr>
      <th>1</th>
      <td>02tnwd4m</td>
      <td>Nitric oxide: a pro-inflammatory mediator in l...</td>
      <td>Inflammatory diseases of the respiratory tract...</td>
    </tr>
    <tr>
      <th>2</th>
      <td>ejv2xln0</td>
      <td>Surfactant protein-D and pulmonary host defense</td>
      <td>Surfactant protein-D (SP-D) participates in th...</td>
    </tr>
    <tr>
      <th>3</th>
      <td>2b73a28n</td>
      <td>Role of endothelin-1 in lung disease</td>
      <td>Endothelin-1 (ET-1) is a 21 amino acid peptide...</td>
    </tr>
    <tr>
      <th>4</th>
      <td>9785vg6d</td>
      <td>Gene expression in epithelial cells in respons...</td>
      <td>Respiratory syncytial virus (RSV) and pneumoni...</td>
    </tr>
    <tr>
      <th>...</th>
      <td>...</td>
      <td>...</td>
      <td>...</td>
    </tr>
    <tr>
      <th>95</th>
      <td>63bos83o</td>
      <td>Global Surveillance of Emerging Influenza Viru...</td>
      <td>BACKGROUND: Effective influenza surveillance r...</td>
    </tr>
    <tr>
      <th>96</th>
      <td>hqc7u9w3</td>
      <td>Transmission Parameters of the 2001 Foot and M...</td>
      <td>Despite intensive ongoing research, key aspect...</td>
    </tr>
    <tr>
      <th>97</th>
      <td>87zt7lew</td>
      <td>Efficient replication of pneumonia virus of mi...</td>
      <td>Pneumonia virus of mice (PVM; family Paramyxov...</td>
    </tr>
    <tr>
      <th>98</th>
      <td>wgxt36jv</td>
      <td>Designing and conducting tabletop exercises to...</td>
      <td>BACKGROUND: Since 2001, state and local health...</td>
    </tr>
    <tr>
      <th>99</th>
      <td>qbldmef1</td>
      <td>Transcript-level annotation of Affymetrix prob...</td>
      <td>BACKGROUND: The wide use of Affymetrix microar...</td>
    </tr>
  </tbody>
</table>
<p>100 rows × 3 columns</p>
</div>



We can then iterate through the `DataFrame` above and feed each row by using the [app.feed_data_point](https://pyvespa.readthedocs.io/en/latest/reference-api.html#vespa.application.Vespa.feed_data_point) method: 

* The schema name is by default set to be equal to the application name, which is `cord19` in this case.

* When feeding data to Vespa, we must have a unique id for each data point. We will use `cord_uid` here.


```python
for idx, row in parsed_feed.iterrows():
    fields = {
        "cord_uid": str(row["cord_uid"]),
        "title": str(row["title"]),
        "abstract": str(row["abstract"])
    }
    response = app.feed_data_point(
        schema = "cord19",
        data_id = str(row["cord_uid"]),
        fields = fields,
    )
```

You can also inspect the response to each request if desired.


```python
response.json()
```




    {'pathId': '/document/v1/cord19/cord19/docid/qbldmef1',
     'id': 'id:cord19:cord19::qbldmef1'}



## Query your application

With data fed, we can start to query our text search app. We can use the [Vespa Query language](https://docs.vespa.ai/en/query-language.html) directly by sending the required parameters to the body argument of the [app.query](https://pyvespa.readthedocs.io/en/latest/reference-api.html#vespa.application.Vespa.query) method.


```python
query = {
    'yql': 'select * from sources * where userQuery();',
    'query': 'What is the role of endothelin-1',
    'ranking': 'bm25',
    'type': 'any',
    'presentation.timing': True,
    'hits': 3
}
```


```python
res = app.query(body=query)
res.hits[0]
```




    {'id': 'id:cord19:cord19::2b73a28n',
     'relevance': 20.79338929607865,
     'source': 'cord19_content',
     'fields': {'sddocname': 'cord19',
      'documentid': 'id:cord19:cord19::2b73a28n',
      'cord_uid': '2b73a28n',
      'title': 'Role of endothelin-1 in lung disease',
      'abstract': 'Endothelin-1 (ET-1) is a 21 amino acid peptide with diverse biological activity that has been implicated in numerous diseases. ET-1 is a potent mitogen regulator of smooth muscle tone, and inflammatory mediator that may play a key role in diseases of the airways, pulmonary circulation, and inflammatory lung diseases, both acute and chronic. This review will focus on the biology of ET-1 and its role in lung disease.'}}



We can also define the same query by using the [QueryModel](https://pyvespa.readthedocs.io/en/latest/reference-api.html#vespa.query.QueryModel) abstraction that allows us to specify how we want to match and rank our documents. In this case, we defined that we want to:

* match our documents using the `OR` operator, which matches all the documents that share at least one term with the query.
* rank the matched documents using the `bm25` rank profile defined in our application package.


```python
from vespa.query import QueryModel, RankProfile as Ranking, OR

res = app.query(
    query="What is the role of endothelin-1", 
    query_model=QueryModel(
        match_phase = OR(),
        rank_profile = Ranking(name="bm25")
    )
    
)
res.hits[0]
```




    {'id': 'id:cord19:cord19::2b73a28n',
     'relevance': 20.79338929607865,
     'source': 'cord19_content',
     'fields': {'sddocname': 'cord19',
      'documentid': 'id:cord19:cord19::2b73a28n',
      'cord_uid': '2b73a28n',
      'title': 'Role of endothelin-1 in lung disease',
      'abstract': 'Endothelin-1 (ET-1) is a 21 amino acid peptide with diverse biological activity that has been implicated in numerous diseases. ET-1 is a potent mitogen regulator of smooth muscle tone, and inflammatory mediator that may play a key role in diseases of the airways, pulmonary circulation, and inflammatory lung diseases, both acute and chronic. This review will focus on the biology of ET-1 and its role in lung disease.'}}



Using the Vespa Query Language as in our first example gives you the full power and flexibility that Vespa can offer. In contrast, the QueryModel abstraction focuses on specific use cases and can be more useful for ML experiments, but this is a future post topic.

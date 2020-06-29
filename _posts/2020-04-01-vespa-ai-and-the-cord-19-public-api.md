---
layout: post
title: Vespa.ai and the CORD-19 public API
excerpt: The Vespa team has been working non-stop to put together the cord19.vespa.ai search app based on the COVID-19 Open Research Dataset (CORD-19) released by the Allen Institute for AI.
date: '2020-04-01T00:00:00-00:00'
tags: [Search Engines, Covid 19, Artificial Intelligence, Machine Learning, NLP]
---

_This post was first published at
[Vespa.ai and the CORD-19 public API](https://towardsdatascience.com/vespa-ai-and-the-cord-19-public-api-a714b942172f)._

The Vespa team has been working non-stop to put together the
[cord19.vespa.ai](https://cord19.vespa.ai/) search app
based on the COVID-19 Open Research Dataset (CORD-19) released by the
[Allen Institute for AI](https://allenai.org/).
Both [the frontend](https://github.com/vespa-engine/cord-19/blob/master/README.md) and
[the backend](https://github.com/vespa-engine/sample-apps/tree/master/vespa-cloud/cord-19-search)
are 100% open-sourced.
The backend is based on [vespa.ai](https://vespa.ai/), a powerful and open-sourced computation engine.
_Since everything is open-sourced, you can contribute to the project in multiple ways._

As a user, you can either search for articles by using the [frontend](http://cord19.vespa.ai/)
or perform advanced search by using the
[public search API](https://github.com/vespa-engine/cord-19/blob/master/cord-19-queries.md).
As a developer, you can contribute by improving the existing application through pull requests to
[the backend](https://github.com/vespa-engine/sample-apps/tree/master/vespa-cloud/cord-19-search) and
[frontend](https://github.com/vespa-engine/cord-19/blob/master/README.md)
or you can fork and create your own application,
either [locally](https://docs.vespa.ai/documentation/vespa-quick-start.html)
or through [Vespa Cloud](https://cloud.vespa.ai/getting-started.html),
to experiment with [different ways to match and rank the CORD-19 articles](https://towardsdatascience.com/learning-from-unlabelled-data-with-covid-19-open-research-dataset-cded4979f1cf?source=friends_link&sk=44fd9519db937036659d0e43c87310c5).
_My goal here with this piece is to give you an overview of what can be accomplished with Vespa
by using the cord19 search app public API.
This only scratches the surface
but I hope it can help direct you to the right places to learn more about what is possible._



## Simple query language
The cord19.vespa.ai query interface supports the Vespa
[simple query language](https://docs.vespa.ai/documentation/reference/simple-query-language-reference.html)
that allows you to quickly perform simple queries. Examples:
* [+covid-19 +temperature impact on viral transmission](https://cord19.vespa.ai/search?query=%2Bcovid-19+%2Btemperature+impact+on+viral+transmission):
  If you click on this link you are going to search for articles containing the words covid-19,
  temperature and the phrase impact on viral transmission.
* [+title:”reproduction number” +abstract:MERS](https://cord19.vespa.ai/search?query=%2Btitle%3A%22reproduction+number%22+%2Babstract%3AMERS):
  This link will return articles that contains the phrase reproduction number in the title
  and the word MERS in the abstract.
* [+authors.last:knobel](https://cord19.vespa.ai/search?query=authors.last%3Aknobel):
  Return articles that have at least one author with last name knobel.

Additional resources:
* More cord19 specific examples can be found in
  [cord19 API doc](https://github.com/vespa-engine/cord-19/blob/master/cord-19-queries.md).
* The [simple query language](https://docs.vespa.ai/documentation/reference/simple-query-language-reference.html)
  doc is the place to go for the query syntax.



## Vespa Search API
In addition to the simple query language,
Vespa has also a more powerful [search API](https://docs.vespa.ai/documentation/search-api.html)
that gives full control in terms of search experience through the
[Vespa query language](https://docs.vespa.ai/documentation/query-language.html) called YQL.
We can then send a wide range of queries by sending a POST request to the search end-point of _cord19.vespa.ai_.
Following are python code illustrating the API:
```
import requests # Install via 'pip install requests'

endpoint = 'https://api.cord19.vespa.ai/search/'
response = requests.post(endpoint, json=body)
```


### Search by query terms
Let’s break down one example to give you a hint of what is possible to do with Vespa search API:
```
body = {
  'yql'    : 'select title, abstract from sources * where userQuery() and has_full_text=true and timestamp > 1577836800;',
  'hits'   : 5,
  'query'  : 'coronavirus temperature sensitivity',
  'type'   : 'any',
  'ranking': 'bm25'
}
```

**The match phase:**
The body parameter above will select the title and the abstract fields for all articles that match
any (`'type': 'any'`) of the `'query'` terms
and that has full text available (`has_full_text=true`) and timestamp greater than 1577836800.

**The ranking phase:**
After matching the articles by the criteria described above, Vespa will rank them according to their 
[BM25 scores](https://docs.vespa.ai/documentation/reference/bm25.html) (`'ranking': 'bm25'`)
and return the top 5 articles (`'hits': 5`) according to this rank criteria.

The example above gives only a taste of what is possible with the search API.
We can tailor both the match phase and ranking phase to our needs.
For example, we can use more complex match operators such as the Vespa weakAND,
we can restrict the search to look for a match only in the abstract by adding `'default-index': 'abstract'` in the _body_ above.
We can experiment with different ranking function at query time
by changing the `'ranking'` parameter to one of the [rank-profiles](https://docs.vespa.ai/documentation/ranking.html) available in the
[search definition file](https://github.com/vespa-engine/sample-apps/blob/master/vespa-cloud/cord-19-search/src/main/application/searchdefinitions/doc.sd).

Additional resources:
* The Vespa text search tutorial shows how to create a text search app on a step-by-step basis.
  [Part 1](https://docs.vespa.ai/documentation/tutorials/text-search.html)
  shows how to create a basic app from scratch.
  [Part 2](https://docs.vespa.ai/documentation/tutorials/text-search-ml.html)
  shows how to collect training data from Vespa and improve the application with ML models.
  [Part 3](https://docs.vespa.ai/documentation/tutorials/text-search-semantic.html)
  shows how to get started with semantic search by using pre-trained sentence embeddings.
* More YQL examples specific to the cord19 app can be found in
  [cord19 API doc](https://github.com/vespa-engine/cord-19/blob/master/cord-19-queries.md).


### Search by semantic relevance
In addition to searching by query terms, Vespa supports semantic search.
```
body = {
    'yql': 'select * from sources * where  ([{"targetNumHits":100}]nearestNeighbor(title_embedding, vector));',
    'hits': 5,
    'ranking.features.query(vector)': embedding.tolist(),
    'ranking.profile': 'semantic-search-title',
}
```

**The match phase:**
In the query above we match at least 100 articles (`[{"targetNumHits":100}]`)
which have the smallest (euclidean) distance between the `title_embedding`
and the query embedding `vector` by using the [nearestNeighbor operator](https://docs.vespa.ai/documentation/reference/query-language-reference.html#nearestneighbor).

**The ranking phase:**
After matching we can rank the documents in a variety of ways.
In this case, we use a specific rank-profile named `'semantic-search-title'`
that was pre-defined to order the matched articles the distance between title and query embeddings.

The title embeddings have been created while feeding the documents to Vespa
while the query embedding is created at query time and sent to Vespa by the `ranking.features.query(vector)` parameter.
This [Kaggle notebook](https://www.kaggle.com/jkb123/semantic-search-using-vespa-ai-s-cord19-index)
illustrates how to perform a semantic search in the cord19 app by using the
[SCIBERT-NLI model](https://huggingface.co/gsarti/scibert-nli).

Additional resources:
* [Part 3](https://docs.vespa.ai/documentation/tutorials/text-search-semantic.html) of the text search tutorial
  shows how to get started with semantic search by using pre-trained sentence embeddings.
* Go to the [Ranking page](https://docs.vespa.ai/documentation/ranking.html)
  to know more about ranking in general and how to deploy ML models in Vespa (including TensorFlow, XGBoost, etc).

WRITTEN BY: Thiago G. Martins. Working on Vespa.ai. Follow me on Twitter @Thiagogm.

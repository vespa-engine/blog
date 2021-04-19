---
layout: post
title: "Build sentence/paragraph level QA application from python with Vespa"
date: '2021-04-15'
tags: []
author: thigm85
image: assets/2021-04-19-build-qa-app-from-python-with-vespa/figure_1.jpg
skipimage: true
excerpt: Retrieve paragraph and sentence level information with sparse and dense ranking features.
---

**Retrieve paragraph and sentence level information with sparse and dense ranking features.**

We will walk through the steps necessary to create a question answering (QA) application that can retrieve sentence or paragraph level answers based on a combination of semantic and/or term-based search. We start by discussing the dataset used and the question and sentence embeddings generated for semantic search. We then include the steps necessary to create and deploy a Vespa application to serve the answers. We make all the required data available to feed the application and show how to query for sentence and paragraph level answers based on a combination of semantic and term-based search.

![Decorative image](/assets/2021-04-19-build-qa-app-from-python-with-vespa/figure_1.jpg)
<p class="image-credit">Photo by <a href="https://unsplash.com/@brett_jordan?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Brett Jordan</a> on <a href="https://unsplash.com/s/photos/ask?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a></p>

This tutorial is based on [earlier work](https://docs.vespa.ai/en/semantic-qa-retrieval.html) by the Vespa team to reproduce the results of the paper [ReQA: An Evaluation for End-to-End Answer Retrieval Models](https://arxiv.org/abs/1907.04780) by Ahmad Et al. using the Stanford Question Answering Dataset (SQuAD) v1.1 dataset.

## About the data

We are going to use the Stanford Question Answering Dataset (SQuAD) v1.1 dataset. The data contains paragraphs (denoted here as context), and each paragraph has questions that have answers in the associated paragraph. We have parsed the dataset and organized the data that we will use in this tutorial to make it easier to follow along.

### Paragraph


```python
import requests, json

context_data = json.loads(
    requests.get("https://data.vespa.oath.cloud/remote_dir/qa_squad_context_data.json").text
)
```

Each `context` data point contains a `context_id` that uniquely identifies a paragraph, a `text` field holding the paragraph string, and a `questions` field holding a list of question ids that can be answered from the paragraph text. We also include a `dataset` field to identify the data source if we want to index more than one dataset in our application.


```python
context_data[0]
```




    {'text': 'Architecturally, the school has a Catholic character. Atop the Main Building\'s gold dome is a golden statue of the Virgin Mary. Immediately in front of the Main Building and facing it, is a copper statue of Christ with arms upraised with the legend "Venite Ad Me Omnes". Next to the Main Building is the Basilica of the Sacred Heart. Immediately behind the basilica is the Grotto, a Marian place of prayer and reflection. It is a replica of the grotto at Lourdes, France where the Virgin Mary reputedly appeared to Saint Bernadette Soubirous in 1858. At the end of the main drive (and in a direct line that connects through 3 statues and the Gold Dome), is a simple, modern stone statue of Mary.',
     'dataset': 'squad',
     'questions': [0, 1, 2, 3, 4],
     'context_id': 0}



### Questions

According to the data point above, `context_id = 0` can be used to answer the questions with `id = [0, 1, 2, 3, 4]`. We can load the file containing the questions and display those first five questions.


```python
from pandas import read_csv

# Note that squad_queries.txt has approx. 1 Gb due to the 512-sized question embeddings
questions = read_csv(
    filepath_or_buffer="https://data.vespa.oath.cloud/remote_dir/squad_queries.txt", 
    sep="\t", 
    names=["question_id", "question", "number_answers", "embedding"]
)
```


```python
questions[["question_id", "question"]].head()
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
      <th>question_id</th>
      <th>question</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>0</td>
      <td>To whom did the Virgin Mary allegedly appear i...</td>
    </tr>
    <tr>
      <th>1</th>
      <td>1</td>
      <td>What is in front of the Notre Dame Main Building?</td>
    </tr>
    <tr>
      <th>2</th>
      <td>2</td>
      <td>The Basilica of the Sacred heart at Notre Dame...</td>
    </tr>
    <tr>
      <th>3</th>
      <td>3</td>
      <td>What is the Grotto at Notre Dame?</td>
    </tr>
    <tr>
      <th>4</th>
      <td>4</td>
      <td>What sits on top of the Main Building at Notre...</td>
    </tr>
  </tbody>
</table>
</div>



### Paragraph sentences

To build a more accurate application, we can break the paragraphs down into sentences. For example, the first sentence below comes from the paragraph with `context_id = 0` and can answer the question with `question_id = 4`.


```python
# Note that qa_squad_sentence_data.json has approx. 1 Gb due to the 512-sized sentence embeddings
sentence_data = json.loads(
    requests.get("https://data.vespa.oath.cloud/remote_dir/qa_squad_sentence_data.json").text
)
```


```python
{k:sentence_data[0][k] for k in ["text", "dataset", "questions", "context_id"]}
```




    {'text': "Atop the Main Building's gold dome is a golden statue of the Virgin Mary.",
     'dataset': 'squad',
     'questions': [4],
     'context_id': 0}



### Embeddings

We want to combine semantic (dense) and term-based (sparse) signals to answer the questions sent to our application. We have generated embeddings for both the questions and the sentences to implement the semantic search, each having size equal to 512.


```python
questions[["question_id", "embedding"]].head(1)
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
      <th>question_id</th>
      <th>embedding</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>0</td>
      <td>[-0.025649750605225563, -0.01708591915667057, ...</td>
    </tr>
  </tbody>
</table>
</div>




```python
sentence_data[0]["sentence_embedding"]["values"][0:5] # display the first five elements
```




    [-0.005731593817472458,
     0.007575507741421461,
     -0.06413306295871735,
     -0.007967847399413586,
     -0.06464996933937073]



Here is [the script](https://github.com/vespa-engine/sample-apps/blob/master/semantic-qa-retrieval/bin/convert-to-vespa-squad.py) containing the code that we used to generate the sentence and questions embeddings. We used [Google's Universal Sentence Encoder](https://tfhub.dev/google/universal-sentence-encoder) at the time but feel free to replace it with embeddings generated by your preferred model.

## Create and deploy the application

We can now build a sentence-level Question answering application based on the data described above.

### Schema to hold context information

The `context` schema will have a document containing the four relevant fields described in the data section. We create an index for the `text` field and use `enable-bm25` to pre-compute data required to speed up the use of BM25 for ranking. The `summary` indexing indicates that all the fields will be included in the requested context documents. The `attribute` indexing store the fields in memory as an attribute for sorting, querying, and grouping.


```python
from vespa.package import Document, Field

context_document = Document(
    fields=[
        Field(name="questions", type="array<int>", indexing=["summary", "attribute"]),
        Field(name="dataset", type="string", indexing=["summary", "attribute"]),
        Field(name="context_id", type="int", indexing=["summary", "attribute"]),        
        Field(name="text", type="string", indexing=["summary", "index"], index="enable-bm25"),                
    ]
)
```

The default fieldset means query tokens will be matched against the `text` field by default. We defined two rank-profiles (`bm25` and `nativeRank`) to illustrate that we can define and experiment with as many rank-profiles as we want. You can create different ones using [the ranking expressions and features](https://docs.vespa.ai/en/ranking-expressions-features.html) available.


```python
from vespa.package import Schema, FieldSet, RankProfile

context_schema = Schema(
    name="context",
    document=context_document, 
    fieldsets=[FieldSet(name="default", fields=["text"])], 
    rank_profiles=[
        RankProfile(name="bm25", inherits="default", first_phase="bm25(text)"), 
        RankProfile(name="nativeRank", inherits="default", first_phase="nativeRank(text)")]
)
```

### Schema to hold sentence information

The document of the `sentence` schema will inherit the fields defined in the `context` document to avoid unnecessary duplication of the same field types. Besides, we add the `sentence_embedding` field defined to hold a one-dimensional tensor of floats of size 512. We will store the field as an attribute in memory and build an ANN `index` using the `HNSW` (hierarchical navigable small world) algorithm. Read [this blog post](https://blog.vespa.ai/approximate-nearest-neighbor-search-in-vespa-part-1/) to know more about Vespa’s journey to implement ANN search and the [documentation](https://docs.vespa.ai/documentation/approximate-nn-hnsw.html) for more information about the HNSW parameters.


```python
from vespa.package import HNSW

sentence_document = Document(
    inherits="context", 
    fields=[
        Field(
            name="sentence_embedding", 
            type="tensor<float>(x[512])", 
            indexing=["attribute", "index"], 
            ann=HNSW(
                distance_metric="euclidean", 
                max_links_per_node=16, 
                neighbors_to_explore_at_insert=500
            )
        )
    ]
)
```

For the `sentence` schema, we define three rank profiles. The `semantic-similarity` uses the Vespa `closeness` ranking feature, which is defined as `1/(1 + distance)` so that sentences with embeddings closer to the question embedding will be ranked higher than sentences that are far apart. The `bm25` is an example of a term-based rank profile, and `bm25-semantic-similarity` combines both term-based and semantic-based signals as an example of a hybrid approach.


```python
sentence_schema = Schema(
    name="sentence", 
    document=sentence_document, 
    fieldsets=[FieldSet(name="default", fields=["text"])], 
    rank_profiles=[
        RankProfile(
            name="semantic-similarity", 
            inherits="default", 
            first_phase="closeness(sentence_embedding)"
        ),
        RankProfile(
            name="bm25", 
            inherits="default", 
            first_phase="bm25(text)"
        ),
        RankProfile(
            name="bm25-semantic-similarity", 
            inherits="default", 
            first_phase="bm25(text) + closeness(sentence_embedding)"
        )
    ]
)
```

### Build the application package

We can now define our `qa` application by creating an application package with both the `context_schema` and the `sentence_schema` that we defined above. In addition, we need to inform Vespa that we plan to send a query ranking feature named `query_embedding` with the same type that we used to define the `sentence_embedding` field.


```python
from vespa.package import ApplicationPackage, QueryProfile, QueryProfileType, QueryTypeField

app_package = ApplicationPackage(
    name="qa", 
    schema=[context_schema, sentence_schema], 
    query_profile=QueryProfile(),
    query_profile_type=QueryProfileType(
        fields=[
            QueryTypeField(
                name="ranking.features.query(query_embedding)", 
                type="tensor<float>(x[512])"
            )
        ]
    )
)
```

### Deploy the application

We can deploy the `app_package` in a Docker container (or to [Vespa Cloud](https://cloud.vespa.ai/)):


```python
from vespa.package import VespaDocker

vespa_docker = VespaDocker(
    port=8081, 
    container_memory="8G", 
    disk_folder="/Users/username/qa_app" # requires absolute path
)
app = vespa_docker.deploy(application_package=app_package)
```

    Waiting for configuration server.
    Waiting for configuration server.
    Waiting for configuration server.
    Waiting for configuration server.
    Waiting for configuration server.
    Waiting for application status.
    Waiting for application status.
    Finished deployment.





    Vespa(http://localhost, 8081)



## Feed the data

Once deployed, we can use the `Vespa` instance `app` to interact with the application. We can start by feeding context and sentence data.


```python
for idx, sentence in enumerate(sentence_data):
    app.feed_data_point(schema="sentence", data_id=idx, fields=sentence)
```


```python
for context in context_data:
    app.feed_data_point(schema="context", data_id=context["context_id"], fields=context)
```

## Sentence level retrieval

The query below sends the first question embedding (`questions.loc[0, "embedding"]`) through the `ranking.features.query(query_embedding)` parameter and use the `nearestNeighbor` search operator to retrieve the closest 100 sentences in embedding space using Euclidean distance as configured in the `HNSW` settings. The sentences returned will be ranked by the `semantic-similarity` rank profile defined in the `sentence` schema.


```python
result = app.query(body={
  'yql': 'select * from sources sentence where ([{"targetNumHits":100}]nearestNeighbor(sentence_embedding,query_embedding));',
  'hits': 100,
  'ranking.features.query(query_embedding)': questions.loc[0, "embedding"],
  'ranking.profile': 'semantic-similarity' 
})
```


```python
result.hits[0]
```




    {'id': 'id:sentence:sentence::2',
     'relevance': 0.5540203635649571,
     'source': 'qa_content',
     'fields': {'sddocname': 'sentence',
      'documentid': 'id:sentence:sentence::2',
      'questions': [0],
      'dataset': 'squad',
      'context_id': 0,
      'text': 'It is a replica of the grotto at Lourdes, France where the Virgin Mary reputedly appeared to Saint Bernadette Soubirous in 1858.'}}



## Sentence level hybrid retrieval

In addition to sending the query embedding, we can send the question string (`questions.loc[0, "question"]`) via the `query` parameter and use the `or` operator to retrieve documents that satisfy either the semantic operator `nearestNeighbor` or the term-based operator `userQuery`. Choosing `type` equal `any` means that the term-based operator will retrieve all the documents that match at least one query token. The retrieved documents will be ranked by the hybrid rank-profile `bm25-semantic-similarity`.


```python
result = app.query(body={
  'yql': 'select * from sources sentence  where ([{"targetNumHits":100}]nearestNeighbor(sentence_embedding,query_embedding)) or userQuery();',
  'query': questions.loc[0, "question"],
  'type': 'any',
  'hits': 100,
  'ranking.features.query(query_embedding)': questions.loc[0, "embedding"],
  'ranking.profile': 'bm25-semantic-similarity' 
})
```


```python
result.hits[0]
```




    {'id': 'id:sentence:sentence::2',
     'relevance': 44.46252359752296,
     'source': 'qa_content',
     'fields': {'sddocname': 'sentence',
      'documentid': 'id:sentence:sentence::2',
      'questions': [0],
      'dataset': 'squad',
      'context_id': 0,
      'text': 'It is a replica of the grotto at Lourdes, France where the Virgin Mary reputedly appeared to Saint Bernadette Soubirous in 1858.'}}



## Paragraph level retrieval

For paragraph-level retrieval, we use Vespa's [grouping](https://docs.vespa.ai/en/grouping.html) feature to retrieve paragraphs instead of sentences. In the sample query below, we group by `context_id` and use the paragraph’s max sentence score to represent the paragraph level score. We limit the number of paragraphs returned by 3, and each paragraph contains at most two sentences. We return all the summary features for each sentence. All those configurations can be changed to fit different use cases.


```python
result = app.query(body={
  'yql': ('select * from sources sentence where ([{"targetNumHits":10000}]nearestNeighbor(sentence_embedding,query_embedding)) |' 
          'all(group(context_id) max(3) order(-max(relevance())) each( max(2) each(output(summary())) as(sentences)) as(paragraphs));'),
  'hits': 0,
  'ranking.features.query(query_embedding)': questions.loc[0, "embedding"],
  'ranking.profile': 'sentence-semantic-similarity' 
})
```


```python
paragraphs = result.json["root"]["children"][0]["children"][0]
```


```python
paragraphs["children"][0] # top-ranked paragraph
```




    {'id': 'group:long:0',
     'relevance': 1.0,
     'value': '0',
     'children': [{'id': 'hitlist:sentences',
       'relevance': 1.0,
       'label': 'sentences',
       'continuation': {'next': 'BKAAAAABGBEBC'},
       'children': [{'id': 'id:sentence:sentence::2',
         'relevance': 0.5540203635649571,
         'source': 'qa_content',
         'fields': {'sddocname': 'sentence',
          'documentid': 'id:sentence:sentence::2',
          'questions': [0],
          'dataset': 'squad',
          'context_id': 0,
          'text': 'It is a replica of the grotto at Lourdes, France where the Virgin Mary reputedly appeared to Saint Bernadette Soubirous in 1858.'}},
        {'id': 'id:sentence:sentence::0',
         'relevance': 0.4668025534074384,
         'source': 'qa_content',
         'fields': {'sddocname': 'sentence',
          'documentid': 'id:sentence:sentence::0',
          'questions': [4],
          'dataset': 'squad',
          'context_id': 0,
          'text': "Atop the Main Building's gold dome is a golden statue of the Virgin Mary."}}]}]}




```python
paragraphs["children"][1] # second-ranked paragraph
```




    {'id': 'group:long:28',
     'relevance': 0.6666666666666666,
     'value': '28',
     'children': [{'id': 'hitlist:sentences',
       'relevance': 1.0,
       'label': 'sentences',
       'continuation': {'next': 'BKAAABCABGBEBC'},
       'children': [{'id': 'id:sentence:sentence::188',
         'relevance': 0.5209270028414069,
         'source': 'qa_content',
         'fields': {'sddocname': 'sentence',
          'documentid': 'id:sentence:sentence::188',
          'questions': [142],
          'dataset': 'squad',
          'context_id': 28,
          'text': 'The Grotto of Our Lady of Lourdes, which was built in 1896, is a replica of the original in Lourdes, France.'}},
        {'id': 'id:sentence:sentence::184',
         'relevance': 0.4590959251360276,
         'source': 'qa_content',
         'fields': {'sddocname': 'sentence',
          'documentid': 'id:sentence:sentence::184',
          'questions': [140],
          'dataset': 'squad',
          'context_id': 28,
          'text': 'It is built in French Revival style and it is decorated by stained glass windows imported directly from France.'}}]}]}



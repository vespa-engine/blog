--- 
layout: post
title: "Hands-On RAG guide for personal data with Vespa and LLamaIndex"
author: jobergum
date: '2023-11-30'
image: assets/2023-11-30-scaling-personal-ai-assistants-with-streaming-mode/avi-richards-Z3ownETsdNQ-unsplash.jpg
image_credit: 'Photo by <a href="https://unsplash.com/@avirichards?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Avi Richards</a> on <a href="https://unsplash.com/photos/man-sitting-on-concrete-brick-with-opened-laptop-on-his-lap-Z3ownETsdNQ?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Unsplash</a>
'  
skipimage: false
tags: [rag, vectors, streaming]
excerpt: A hands-on guide to using Vespa streaming mode with PyVespa and LLamaIndex.
---

This blog post is a hands-on RAG tutorial demonstrating how to use [Vespa streaming mode](https://docs.vespa.ai/en/streaming-search.html) for cost-efficient retrieval of personal data. You can read more about Vespa streaming search in these two blog posts:

- [Announcing vector streaming search: AI assistants at scale without breaking the bank](https://blog.vespa.ai/announcing-vector-streaming-search/)
- [Yahoo Mail turns to Vespa to do RAG at scale](https://blog.vespa.ai/yahoo-mail-turns-to-vespa-to-do-rag-at-scale/)

This blog post is also available as a runnable notebook where you can have this app up and running on
[Vespa Cloud](https://cloud.vespa.ai/) in minutes
(<a target="_blank" href="https://colab.research.google.com/github/vespa-engine/pyvespa/blob/master/docs/sphinx/source/examples/scaling-personal-ai-assistants-with-streaming-mode-cloud.ipynb">
  <img src="https://colab.research.google.com/assets/colab-badge.svg" alt="Open In Colab"/>
</a>)

The blog post covers:

- Configuring Vespa and using Vespa streaming mode with [PyVespa](https://pyvespa.readthedocs.io/en/latest/).
- Using Vespa native [built-in embedders](https://docs.vespa.ai/en/embedding.html) in combination with streaming mode.
- [Ranking in Vespa](https://docs.vespa.ai/en/ranking.html), including hybrid retrieval and ranking methods, freshness (recency) features, and Vespa [Rank Fusion](https://docs.vespa.ai/en/phased-ranking.html#cross-hit-normalization-including-reciprocal-rank-fusion).
- Query [federation](https://docs.vespa.ai/en/federation.html) and blending retrieved results from multiple sources/schemas.
- Connecting [LLamaIndex](https://docs.llamaindex.ai/en/stable/#) retrievers with a Vespa app to build generative AI pipelines.

**TLDR; Vespa streaming mode**

Vespa’s streaming search solution lets you make the user a part of the document ID so that Vespa can use it to co-locate the data of each user on a small set of nodes and the same chunk of disk. 
Streaming mode allows searching over a user’s data with low latency without keeping any user’s data in memory or paying the cost of managing indexes. 

- There is no accuracy drop for vector search as it uses exact vector search 
- Several orders of magnitude higher write throughput (No expensive index builds to support approximate search)
- Documents (including vector data) are 100% disk-based, significantly reducing deployment cost
- Queries are restricted to content by the user ID/([groupname](https://docs.vespa.ai/en/reference/query-api-reference.html#streaming.groupname)) 

Storage cost is the primary cost driver of Vespa streaming mode; no data is in memory. Avoiding memory usage lowers deployment costs significantly.
For example, Vespa Cloud allows storing streaming mode data at below 0.30$ per GB/month. Yes, that is per month.

### Getting started with LLamaIndex and PyVespa

The focus is on using the streaming mode feature in combination with multiple Vespa schemas; in our case,
we imagine building RAG over personal mail and calendar data, allowing effortless [query federation](https://docs.vespa.ai/en/federation.html) and blending
of the results from multiple data sources for a given user.  


First, we must install dependencies:

```python
! pip3 install pyvespa llama-index
```

### Synthetic Mail & Calendar Data 
There are few public email datasets because people care about their privacy, so this notebook uses synthetic data to examine how to use Vespa streaming mode. 
We create two generator functions that return Python `dict`s with synthetic mail and calendar data. 

Notice that the dict has three keys:

- `id`
- `groupname`
- `fields`

This is the expected feed format for [PyVespa](https://pyvespa.readthedocs.io/en/latest/reads-writes.html) feed operations and
where PyVespa will use these to build a Vespa [document v1 API](https://docs.vespa.ai/en/document-v1-api-guide.html) request(s). 
The `groupname` key is only relevant with streaming mode.

#### mail 

```python
from typing import List

def synthetic_mail_data_generator() -> List[dict]:
    synthetic_mails = [
        {
            "id": 1,
            "groupname": "bergum@vespa.ai",
            "fields": {
                "subject": "LlamaIndex news, 2023-11-14",
                "to": "bergum@vespa.ai",
                "body": """Hello Llama Friends 🦙 LlamaIndex is 1 year old this week! 🎉 To celebrate, we're taking a stroll down memory 
                    lane on our blog with twelve milestones from our first year. Be sure to check it out.""",
                "from": "news@llamaindex.ai",
                "display_date": "2023-11-15T09:00:00Z"
            }
        },
        {
            "id": 2,
            "groupname": "bergum@vespa.ai",
            "fields": {
                "subject": "Dentist Appointment Reminder",
                "to": "bergum@vespa.ai",
                "body": "Dear Jo Kristian ,\nThis is a reminder for your upcoming dentist appointment on 2023-12-04 at 09:30. Please arrive 15 minutes early.\nBest regards,\nDr. Dentist",
                "from": "dentist@dentist.no",
                "display_date": "2023-11-15T15:30:00Z"
            }
        },
        {
            "id": 1,
            "groupname": "giraffe@wildlife.ai",
            "fields": {
                "subject": "Wildlife Update: Giraffe Edition",
                "to": "giraffe@wildlife.ai",
                "body": "Dear Wildlife Enthusiasts 🦒, We're thrilled to share the latest insights into giraffe behavior in the wild. Join us on an adventure as we explore their natural habitat and learn more about these majestic creatures.",
                "from": "updates@wildlife.ai",
                "display_date": "2023-11-12T14:30:00Z"
        }
        },
        {
            "id": 1,
            "groupname": "penguin@antarctica.ai",
            "fields": {
                "subject": "Antarctica Expedition: Penguin Chronicles",
                "to": "penguin@antarctica.ai",
                "body": "Greetings Explorers 🐧, Our team is embarking on an exciting expedition to Antarctica to study penguin colonies. Stay tuned for live updates and behind-the-scenes footage as we dive into the world of these fascinating birds.",
                "from": "expedition@antarctica.ai",
                "display_date": "2023-11-11T11:45:00Z"
            }
        },
        {
            "id": 1,
            "groupname": "space@exploration.ai",
            "fields": {
                "subject": "Space Exploration News: November Edition",
                "to": "space@exploration.ai",
                "body": "Hello Space Enthusiasts 🚀, Join us as we highlight the latest discoveries and breakthroughs in space exploration. From distant galaxies to new technologies, there's a lot to explore!",
                "from": "news@exploration.ai",
                "display_date": "2023-11-01T16:20:00Z"
            }
         },
        {
            "id": 1,
            "groupname": "ocean@discovery.ai",
            "fields": {
                "subject": "Ocean Discovery: Hidden Treasures Unveiled",
                "to": "ocean@discovery.ai",
                "body": "Dear Ocean Explorers 🌊, Dive deep into the secrets of the ocean with our latest discoveries. From undiscovered species to underwater landscapes, our team is uncovering the wonders of the deep blue.",
                "from": "discovery@ocean.ai",
                "display_date": "2023-10-01T10:15:00Z"
            }
        }
    ]
    for mail in synthetic_mails:
        yield mail  
```

#### calendar
Similarily, for calendar data 

```python
from typing import List

def synthetic_calendar_data_generator() -> List[dict]:
    calendar_data = [
       
        {
            "id": 1,
            "groupname": "bergum@vespa.ai",
            "fields": {
                "subject": "Dentist Appointment",
                "to": "bergum@vespa.ai",
                "body": "Dentist appointment at 2023-12-04 at 09:30 - 1 hour duration",
                "from": "dentist@dentist.no",
                "display_date": "2023-11-15T15:30:00Z",
                "duration": 60,
            }
        },
         {
            "id": 2,
            "groupname": "bergum@vespa.ai",
            "fields": {
                "subject": "Public Cloud Platform Events",
                "to": "bergum@vespa.ai",
                "body": "The cloud team continues to push new features and improvements to the platform. Join us for a live demo of the latest updates",
                "from": "public-cloud-platform-events",
                "display_date": "2023-11-21T09:30:00Z",
                "duration": 60,
            }
        }
    ]
    for event in calendar_data:
        yield event
```

## Definining a Vespa application
[PyVespa](https://pyvespa.readthedocs.io/en/latest/) helps us build the [Vespa application package](https://docs.vespa.ai/en/application-packages.html). 
A Vespa application package comprises configuration files, code (plugins), and models.   

We define two [Vespa schemas](https://docs.vespa.ai/en/schemas.html) for our mail and calendar data. [PyVespa](https://pyvespa.readthedocs.io/en/latest/)
offers a programmatic API for creating the schema. Ultimately, the programmatic representation is serialized to files (`<schema-name>.sd`).  

In the following we define the fields and their type. Note that we set `mode` to `streaming`, 
which enables [Vespa streaming mode for this schema](https://docs.vespa.ai/en/streaming-search.html). 
Other valid modes are `indexed` and `store-only`. 

### mail schema
```python
from vespa.package import Schema, Document, Field, FieldSet, HNSW
mail_schema = Schema(
            name="mail",
            mode="streaming",
            document=Document(
                fields=[
                    Field(name="id", type="string", indexing=["summary", "index"]),
                    Field(name="subject", type="string", indexing=["summary", "index"]),
                    Field(name="to", type="string", indexing=["summary", "index"]),
                    Field(name="from", type="string", indexing=["summary", "index"]),
                    Field(name="body", type="string", indexing=["summary", "index"]),
                    Field(name="display_date", type="string", indexing=["summary"]),
                    Field(name="timestamp", type="long", indexing=["input display_date", "to_epoch_second", "summary", "attribute"], is_document_field=False),
                    Field(name="embedding", type="tensor<bfloat16>(x[384])",
                        indexing=["\"passage: \" . input subject .\" \". input body", "embed e5", "attribute", "index"],
                        ann=HNSW(distance_metric="angular"),
                        is_document_field=False
                    )
                ],
            ),
            fieldsets=[
                FieldSet(name = "default", fields = ["subject", "body", "to", "from"])
            ]
)
```
In the `mail` schema, we have six document fields; these are provided by us when we feed documents of type `mail` to this app. 
The [fieldset](https://docs.vespa.ai/en/schemas.html#fieldset) defines
which fields are matched against when we do not mention explicit field names when querying. We can add as many fieldsets as we like without duplicating content. 

In addition to the fields within the `document`, there are two synthetic fields in the schema, `timestamp`, and `embedding`, 
using Vespa [indexing expressions](https://docs.vespa.ai/en/reference/indexing-language-reference.html)
taking inputs from the document and performing conversions.

- the `timestamp` field takes the input `display_date` and uses the [to_epoch_second converter](https://docs.vespa.ai/en/reference/indexing-language-reference.html#converter) converter to convert the 
display date into an epoch timestamp. This is useful because we can calculate the document's age and use the `freshness(timestamp)` rank feature during ranking phases.
- the `embedding` tensor field takes the subject and body as input. It feeds that into an [embed](https://docs.vespa.ai/en/embedding.html#embedding-a-document-field) function that uses an embedding model to map the string input into an embedding vector representation 
using 384-dimensions with `bfloat16` precision. Vectors in Vespa are represented as [Tensors](https://docs.vespa.ai/en/tensor-user-guide.html).


### calendar schema
```python
from vespa.package import Schema, Document, Field, FieldSet, HNSW
calendar_schema = Schema(
            name="calendar",
            inherits="mail",
            mode="streaming",
            document=Document(inherits="mail",
                fields=[
                    Field(name="duration", type="int", indexing=["summary", "index"]),
                    Field(name="guests", type="array<string>", indexing=["summary", "index"]),
                    Field(name="location", type="string", indexing=["summary", "index"]),
                    Field(name="url", type="string", indexing=["summary", "index"]),
                    Field(name="address", type="string", indexing=["summary", "index"])
                ]
            )
)
```
The `calendar` schema `inherits` from the `mail` schema, meaning we don't have to define the `embedding` field for the
`calendar` schema.  

### Configuring embedders 

The observant reader might have noticed the `e5` argument to the `embed` expression in the above `mail` schema `embedding` field.
The `e5` argument references a component of the type [hugging-face-embedder](https://docs.vespa.ai/en/embedding.html#huggingface-embedder). In this
example, we use the [e5-small-v2](https://huggingface.co/intfloat/e5-small-v2) text embedding model that maps text to 384-dimensional vectors. 

```python
from vespa.package import ApplicationPackage, Component, Parameter

vespa_app_name = "assistant"
vespa_application_package = ApplicationPackage(
        name=vespa_app_name,
        schema=[mail_schema, calendar_schema],
        components=[Component(id="e5", type="hugging-face-embedder",
            parameters=[
                Parameter("transformer-model", {"url": "https://github.com/vespa-engine/sample-apps/raw/master/simple-semantic-search/model/e5-small-v2-int8.onnx"}),
                Parameter("tokenizer-model", {"url": "https://raw.githubusercontent.com/vespa-engine/sample-apps/master/simple-semantic-search/model/tokenizer.json"})
            ]
        )]
) 
```
We share and reuse the same embedding model for both schemas. Note that [embedding inference](https://blog.vespa.ai/accelerating-transformer-based-embedding-retrieval-with-vespa/) is resource-intensive.

### Ranking 
In the last step of configuring the Vespa app, we add [ranking](https://docs.vespa.ai/en/ranking.html) profiles by adding `rank-profile`'s to the schemas. Vespa supports [phased ranking](https://docs.vespa.ai/en/phased-ranking.html) and has a rich set of built-in [rank-features](https://docs.vespa.ai/en/reference/rank-features.html). 

One can also define custom functions with [ranking expressions](https://docs.vespa.ai/en/reference/ranking-expressions.html).

```python
from vespa.package import RankProfile, Function, GlobalPhaseRanking, FirstPhaseRanking

keywords_and_freshness = RankProfile(
    name="default", 
    functions=[Function(
        name="my_function", expression="nativeRank(subject) + nativeRank(body) + freshness(timestamp)"
    )],
    first_phase=FirstPhaseRanking(
        expression="my_function",
        rank_score_drop_limit=0.02
    ),
    match_features=["nativeRank(subject)", "nativeRank(body)", "my_function", "freshness(timestamp)"],
)

semantic = RankProfile(
    name="semantic", 
    functions=[Function(
        name="cosine", expression="max(0,cos(distance(field, embedding)))"
    )],
    inputs=[("query(q)", "tensor<float>(x[384])"), ("query(threshold)","", "0.75")],
    first_phase=FirstPhaseRanking(
        expression="if(cosine > query(threshold), cosine, -1)",
        rank_score_drop_limit=0.1
    ),
    match_features=["cosine", "freshness(timestamp)", "distance(field, embedding)", "query(threshold)"],
)

fusion = RankProfile(
    name="fusion",
    inherits="semantic",
    functions=[
        Function(
            name="keywords_and_freshness", expression=" nativeRank(subject) + nativeRank(body) + freshness(timestamp)"
        ),
        Function(
            name="semantic", expression="cos(distance(field,embedding))"
        )

    ],
    inputs=[("query(q)", "tensor<float>(x[384])"), ("query(threshold)", "", "0.75")],
    first_phase=FirstPhaseRanking(
        expression="if(cosine > query(threshold), cosine, -1)",
        rank_score_drop_limit=0.1
    ),
    match_features=["nativeRank(subject)", "keywords_and_freshness", "freshness(timestamp)", "cosine", "query(threshold)"],
    global_phase=GlobalPhaseRanking(
        rerank_count=1000,
        expression="reciprocal_rank_fusion(semantic, keywords_and_freshness)"
    )
)

```
The `default` rank profile defines a custom function `my_function` that computes a linear combination of three different features:

- `nativeRank(subject)` Is a text matching feature [](https://docs.vespa.ai/en/reference/nativerank.html), scoped to the `subject` field. 
- `nativeRank(body)` Same, but scoped to the `body` field.
- `freshness(timestamp)` This is a built-in [rank-feature](https://docs.vespa.ai/en/reference/rank-features.html#freshness) that returns a number close to 1 
if the timestamp is recent compared to the current query time.

The `semantic` profile defines the query tensor user with nearestNeighbor search and a custom expression in combination 
with [rank-score-drop-limit](https://docs.vespa.ai/en/reference/schema-reference.html#rank-score-drop-limit) that allows for a query time threshold. 

The `fusion` profile is more involved and uses [phased ranking](https://docs.vespa.ai/en/phased-ranking.html), 
where the first-phase uses semantic similarity (cosine), and the best results from
that phase are re-ranked using a global phase expression that performs reciprocal rank fusion. Read more about [Vespa RRF and cross-hit normalization](https://docs.vespa.ai/en/phased-ranking.html#cross-hit-normalization-including-reciprocal-rank-fusion).

### Serializing from PyVespa object representation to application files
 
We can serialize the representation to application package files.
This is practical when we want to start working with production deployments and when we want to manage the 
application schema files with version control and [safe deployments with CI/CD in Vespa Cloud](https://cloud.vespa.ai/en/production-deployment).

```python
application_directory="my-assistant-vespa-app"
vespa_application_package.to_files(application_directory)
import os

def print_files_in_directory(directory):
    for root, _, files in os.walk(directory):
        for file in files:
            print(os.path.join(root, file))
print_files_in_directory(application_directory)

```

    my-assistant-vespa-app/services.xml
    my-assistant-vespa-app/schemas/mail.sd
    my-assistant-vespa-app/schemas/calendar.sd
    my-assistant-vespa-app/search/query-profiles/default.xml
    my-assistant-vespa-app/search/query-profiles/types/root.xml


## Deploy the application to Vespa Cloud

With the configured application, we can deploy it to [Vespa Cloud](https://cloud.vespa.ai/en/). 
It is also possible to deploy the app using docker; see the [Hybrid Search - Quickstart](https://pyvespa.readthedocs.io/en/latest/getting-started-pyvespa.html) guide for
an example of deploying a Vespa app using the [vespaengine/vespa](https://hub.docker.com/r/vespaengine/vespa/) container image. 

See <a target="_blank" href="https://colab.research.google.com/github/vespa-engine/pyvespa/blob/master/docs/sphinx/source/examples/scaling-personal-ai-assistants-with-streaming-mode-cloud.ipynb">
  <img src="https://colab.research.google.com/assets/colab-badge.svg" alt="Open In Colab"/>
</a>  for complete details on onboarding Vespa Cloud and deployment details. 

### Feeding data to Vespa

With the app up and running in Vespa Cloud, we can feed and query our data. 
We use the [feed_iterable](https://pyvespa.readthedocs.io/en/latest/reference-api.html#vespa.application.Vespa.feed_iterable) API of pyvespa
with a custom `callback` that prints the URL and an error if the operation fails. We pass the defined synthetic generators and call `feed_iterable` with the specific `schema` and `namespace`. 

```python
from vespa.io import VespaResponse

def callback(response:VespaResponse, id:str):
    if not response.is_successful():
        print(f"Error {response.url} : {response.get_json()}")
    else:
        print(f"Success {response.url}")

app.feed_iterable(synthetic_mail_data_generator(), schema="mail", namespace="assistant", callback=callback)
app.feed_iterable(synthetic_calendar_data_generator(), schema="calendar", namespace="assistant", callback=callback)

```

    Success https://cb923ffc.cae25ac9.z.vespa-app.cloud//document/v1/assistant/mail/group/bergum@vespa.ai/1
    Success https://cb923ffc.cae25ac9.z.vespa-app.cloud//document/v1/assistant/mail/group/bergum@vespa.ai/2
    Success https://cb923ffc.cae25ac9.z.vespa-app.cloud//document/v1/assistant/mail/group/giraffe@wildlife.ai/1
    Success https://cb923ffc.cae25ac9.z.vespa-app.cloud//document/v1/assistant/mail/group/penguin@antarctica.ai/1
    Success https://cb923ffc.cae25ac9.z.vespa-app.cloud//document/v1/assistant/mail/group/space@exploration.ai/1
    Success https://cb923ffc.cae25ac9.z.vespa-app.cloud//document/v1/assistant/mail/group/ocean@discovery.ai/1
    Success https://cb923ffc.cae25ac9.z.vespa-app.cloud//document/v1/assistant/calendar/group/bergum@vespa.ai/1
    Success https://cb923ffc.cae25ac9.z.vespa-app.cloud//document/v1/assistant/calendar/group/bergum@vespa.ai/2

### Querying data
Now, we can also query our data. With [streaming mode](https://docs.vespa.ai/en/reference/query-api-reference.html#streaming), 
we must pass the `groupname` parameter, or the request will fail with an error. The query request uses the [Vespa Query API](https://docs.vespa.ai/en/query-api.html) and the `Vespa.query()` function 
supports passing any of the Vespa query API parameters. 

Sample query request for `when is my dentist appointment` for the user `bergum@vespa.ai`:


```python
from vespa.io import VespaQueryResponse
import json

response:VespaQueryResponse = app.query(
    yql="select subject, display_date, to from sources mail where userQuery()",
    query="when is my dentist appointment", 
    groupname="bergum@vespa.ai", 
    ranking="default"
)
assert(response.is_successful())
print(json.dumps(response.hits[0], indent=2))
```

    {
      "id": "id:assistant:mail:g=bergum@vespa.ai:2",
      "relevance": 1.134783932836458,
      "source": "assistant_content.mail",
      "fields": {
        "matchfeatures": {
          "freshness(timestamp)": 0.9232458847736625,
          "nativeRank(body)": 0.09246780326887034,
          "nativeRank(subject)": 0.11907024479392506,
          "my_function": 1.134783932836458
        },
        "subject": "Dentist Appointment Reminder",
        "to": "bergum@vespa.ai",
        "display_date": "2023-11-15T15:30:00Z"
      }
    }


For the above query request, Vespa searched the `default` fieldset we defined in the schema to match against several fields, including the body and the subject. The `default` rank-profile calculated the relevance score as the sum of three rank-features `nativeRank(body) + nativeRank(subject) + freshness(timestamp)`. The result of this computation is the `relevance` score of the hit.
In addition, we also asked Vespa to return `matchfeatures`, that are handy for debugging the final `relevance` score 
or for feature logging. 

Now, we can try the `semantic` ranking profile, using Vespa's support for nearestNeighbor search. This example also demonstrates using the configured `e5` embedder to embed the user query 
into an embedding representation. 
See [embedding a query text](https://docs.vespa.ai/en/embedding.html#embedding-a-query-text) for more usage examples of using Vespa native embedders.

```python
from vespa.io import VespaQueryResponse
import json

response:VespaQueryResponse = app.query(
    yql="select subject, display_date from mail where {targetHits:10}nearestNeighbor(embedding,q)",
    groupname="bergum@vespa.ai", 
    ranking="semantic",
    body={
        "input.query(q)": "embed(e5, \"when is my dentist appointment\")",
    }
)
assert(response.is_successful())
print(json.dumps(response.hits[0], indent=2))
```

    {
      "id": "id:assistant:mail:g=bergum@vespa.ai:2",
      "relevance": 0.9079386507883569,
      "source": "assistant_content.mail",
      "fields": {
        "matchfeatures": {
          "distance(field,embedding)": 0.4324572498488368,
          "freshness(timestamp)": 0.9232457561728395,
          "query(threshold)": 0.75,
          "cosine": 0.9079386507883569
        },
        "subject": "Dentist Appointment Reminder",
        "display_date": "2023-11-15T15:30:00Z"
      }
    }

## LlamaIndex Retrievers Introduction

Now, we have a basic Vespa app using streaming mode. 
We likely want to use an LLM framework like [LangChain](https://www.langchain.com/) or [LLamaIndex](https://www.llamaindex.ai/) to build an end-to-end assistant. The LlamaIndex [retriever](https://gpt-index.readthedocs.io/en/latest/core_modules/query_modules/retriever/root.html)
abstraction allows developers to add custom retrievers that retrieve information in Retrieval Augmented Generation (RAG) pipelines. For an excellent 
introduction to LLamaIndex and its concepts, see [LLamaIndex Concepts](https://gpt-index.readthedocs.io/en/latest/getting_started/concepts.html).

To create a custom LlamaIndex retriever, we implement a class that inherits from `llama_index.retrievers.BaseRetriever.BaseRetriever` and 
which implements `_retrieve(query)`. A simple `PersonalAssistantVespaRetriever` could look like the following:

```python

from llama_index.core import BaseRetriever
from llama_index.schema import NodeWithScore, QueryBundle, TextNode
from llama_index.callbacks.base import CallbackManager

from vespa.application import Vespa
from vespa.io import VespaQueryResponse

from typing import List, Union, Optional

class PersonalAssistantVespaRetriever(BaseRetriever):

   def __init__(
      self,
      app: Vespa,
      user: str,
      hits: int = 5,
      vespa_rank_profile: str = "default",
      vespa_score_cutoff: float = 0.70,
      sources: List[str] = ["mail"],
      fields: List[str] = ["subject", "body"],
      callback_manager: Optional[CallbackManager] = None
   ) -> None:
      """Sample Retriever for a personal assistant application.
      Args:
      param: app: Vespa application object
      param: user: user id to retrieve documents for (used for Vespa streaming groupname)
      param: hits: number of hits to retrieve from Vespa app
      param: vespa_rank_profile: Vespa rank profile to use
      param: vespa_score_cutoff: Vespa score cutoff to use during first-phase ranking
      param: sources: sources to retrieve documents from
      param: fields: fields to retrieve
      """
 
      self.app = app
      self.hits = hits
      self.user = user
      self.vespa_rank_profile = vespa_rank_profile
      self.vespa_score_cutoff = vespa_score_cutoff
      self.fields = fields
      self.summary_fields = ",".join(fields)
      self.sources = ",".join(sources)
      super().__init__(callback_manager)

   def _retrieve(self, query:Union[str,QueryBundle]) -> List[NodeWithScore]:
      """Retrieve documents from Vespa application.
      """
      if isinstance(query, QueryBundle):
         query = query.query_str
      
      if self.vespa_rank_profile == 'default':
         yql:str = f"select {self.summary_fields} from mail where userQuery()"
      else:
         yql = f"select {self.summary_fields} from sources {self.sources} where {targetHits:10}nearestNeighbor(embedding,q) or userQuery()"
      vespa_body_request = {
         "yql" : yql,
         "query": query,
         "hits": self.hits,
         "ranking.profile": self.vespa_rank_profile,
         "timeout": "1s",
         "input.query(threshold)": self.vespa_score_cutoff,
      }
      if self.vespa_rank_profile != "default":
         vespa_body_request["input.query(q)"] = f"embed(e5, \"{query}\")"

      with self.app.syncio(connections=1) as session:
         response:VespaQueryResponse = session.query(body=vespa_body_request, groupname=self.user)
         if not response.is_successful():
            raise ValueError(f"Query request failed: {response.status_code}, response payload: {response.get_json()}")

      nodes: List[NodeWithScore] = []
      for hit in response.hits:
         response_fields:dict = hit.get('fields', {})
         text: str = ""
         for field in response_fields.keys():
            if isinstance(response_fields[field], str) and field in self.fields:
                  text += response_fields[field] + " "
         id = hit['id']
         # 
         doc = TextNode(id_=id, text=text, 
            metadata=response_fields,    
         )
         nodes.append(NodeWithScore(node=doc, score=hit['relevance']))    
      return nodes                  
```

The above defines a `PersonalAssistantVespaRetriever` that takes a [pyvespa](https://pyvespa.readthedocs.io/en/latest/)
`Vespa` application instance as an argument, plus some.

The `YQL` request specifies a hybrid retrieval query that retrieves both using embedding-based retrieval (vector search) 
using Vespa's nearest neighbor search operator in combination with traditional keyword matching.  

### Running queries with the PersonalAssistantVespaRetriever

We initialize the `PersonalAssistantVespaRetriever` for the user `bergum@vespa.ai` with the `app` defined earlier. 
The `user` argument maps to the Vespa streaming mode [groupname
parameter](https://docs.vespa.ai/en/reference/query-api-reference.html#streaming.groupname), 
efficiently limiting the search to only a specific user.

```python

retriever = PersonalAssistantVespaRetriever(
    app=app, 
    user="bergum@vespa.ai", 
    vespa_rank_profile="default"
)
retriever.retrieve("When is my dentist appointment?")

```
    [NodeWithScore(node=TextNode(id_='id:assistant:mail:g=bergum@vespa.ai:2', embedding=None, metadata={'matchfeatures': {'freshness(timestamp)': 0.9232454989711935, 'nativeRank(body)': 0.09246780326887034, 'nativeRank(subject)': 0.11907024479392506, 'my_function': 1.1347835470339889}, 'subject': 'Dentist Appointment Reminder', 'body': 'Dear Jo Kristian ,\nThis is a reminder for your upcoming dentist appointment on 2023-12-04 at 09:30. Please arrive 15 minutes early.\nBest regards,\nDr. Dentist'}, excluded_embed_metadata_keys=[], excluded_llm_metadata_keys=[], relationships={}, hash='269fe208f8d43a967dc683e1c9b832b18ddfb0b2efd801ab7e428620c8163021', text='Dentist Appointment Reminder Dear Jo Kristian ,\nThis is a reminder for your upcoming dentist appointment on 2023-12-04 at 09:30. Please arrive 15 minutes early.\nBest regards,\nDr. Dentist ', start_char_idx=None, end_char_idx=None, text_template='{metadata_str}\n\n{content}', metadata_template='{key}: {value}', metadata_seperator='\n'), score=1.1347835470339889),
     NodeWithScore(node=TextNode(id_='id:assistant:mail:g=bergum@vespa.ai:1', embedding=None, metadata={'matchfeatures': {'freshness(timestamp)': 0.9202362397119341, 'nativeRank(body)': 0.02919821398130037, 'nativeRank(subject)': 1.3512214436142505e-38, 'my_function': 0.9494344536932345}, 'subject': 'LlamaIndex news, 2023-11-14', 'body': "Hello Llama Friends 🦙 LlamaIndex is 1 year old this week! 🎉 To celebrate, we're taking a stroll down memory \n                    lane on our blog with twelve milestones from our first year. Be sure to check it out."}, excluded_embed_metadata_keys=[], excluded_llm_metadata_keys=[], relationships={}, hash='5e975eaece761d46956c9d301138f29b5c067d3da32fd013bb79c6ee9c033d3d', text="LlamaIndex news, 2023-11-14 Hello Llama Friends 🦙 LlamaIndex is 1 year old this week! 🎉 To celebrate, we're taking a stroll down memory \n                    lane on our blog with twelve milestones from our first year. Be sure to check it out. ", start_char_idx=None, end_char_idx=None, text_template='{metadata_str}\n\n{content}', metadata_template='{key}: {value}', metadata_seperator='\n'), score=0.9494344536932345)]


We can also try the `semantic` profile, which has rank-score-drop functionality, allowing us to have a per-query time score threshold. This will then
also invoke the native Vespa embedder model inside Vespa. 

```python
retriever = PersonalAssistantVespaRetriever(
    app=app, 
    user="bergum@vespa.ai", 
    vespa_rank_profile="semantic",
    vespa_score_cutoff=0.6,
    hits=20
)
retriever.retrieve("When is my dentist appointment?")
```
    [NodeWithScore(node=TextNode(id_='id:assistant:mail:g=bergum@vespa.ai:2', embedding=None, metadata={'matchfeatures': {'distance(field,embedding)': 0.43945494361938975, 'freshness(timestamp)': 0.9232453703703704, 'query(threshold)': 0.6, 'cosine': 0.9049836898369259}, 'subject': 'Dentist Appointment Reminder', 'body': 'Dear Jo Kristian ,\nThis is a reminder for your upcoming dentist appointment on 2023-12-04 at 09:30. Please arrive 15 minutes early.\nBest regards,\nDr. Dentist'}, excluded_embed_metadata_keys=[], excluded_llm_metadata_keys=[], relationships={}, hash='e89f669e6c9cf64ab6a856d9857915481396e2aa84154951327cd889c23f7c4f', text='Dentist Appointment Reminder Dear Jo Kristian ,\nThis is a reminder for your upcoming dentist appointment on 2023-12-04 at 09:30. Please arrive 15 minutes early.\nBest regards,\nDr. Dentist ', start_char_idx=None, end_char_idx=None, text_template='{metadata_str}\n\n{content}', metadata_template='{key}: {value}', metadata_seperator='\n'), score=0.9049836898369259),
     NodeWithScore(node=TextNode(id_='id:assistant:mail:g=bergum@vespa.ai:1', embedding=None, metadata={'matchfeatures': {'distance(field,embedding)': 0.69930099954744, 'freshness(timestamp)': 0.9202361111111111, 'query(threshold)': 0.6, 'cosine': 0.7652923088511814}, 'subject': 'LlamaIndex news, 2023-11-14', 'body': "Hello Llama Friends 🦙 LlamaIndex is 1 year old this week! 🎉 To celebrate, we're taking a stroll down memory \n                    lane on our blog with twelve milestones from our first year. Be sure to check it out."}, excluded_embed_metadata_keys=[], excluded_llm_metadata_keys=[], relationships={}, hash='cb9b588e5b53dbdd0fbe6f7aadfa689d84a5bea23239293bd299347ee9ecd853', text="LlamaIndex news, 2023-11-14 Hello Llama Friends 🦙 LlamaIndex is 1 year old this week! 🎉 To celebrate, we're taking a stroll down memory \n                    lane on our blog with twelve milestones from our first year. Be sure to check it out. ", start_char_idx=None, end_char_idx=None, text_template='{metadata_str}\n\n{content}', metadata_template='{key}: {value}', metadata_seperator='\n'), score=0.7652923088511814)]

Both profiles return the fields defined with `summary`, and the "extra" `matchfeatures` that can be used for debugging or feature logging (feedback data used to train ranking models). 

### Federating and blending from multiple sources

Create a new retriever with sources (mail and calendar data), and rerun the query (The default source was `mail`): 

```python
retriever = PersonalAssistantVespaRetriever(
    app=app, 
    user="bergum@vespa.ai", 
    vespa_rank_profile="fusion",
    sources=["calendar", "mail"],
    vespa_score_cutoff=0.80
)
retriever.retrieve("When is my dentist appointment?")
```
    [NodeWithScore(node=TextNode(id_='id:assistant:calendar:g=bergum@vespa.ai:1', embedding=None, metadata={'matchfeatures': {'freshness(timestamp)': 0.9232447273662552, 'nativeRank(subject)': 0.11907024479392506, 'query(threshold)': 0.8, 'cosine': 0.8872983644178517, 'keywords_and_freshness': 1.1606592237923947}, 'subject': 'Dentist Appointment', 'body': 'Dentist appointment at 2023-12-04 at 09:30 - 1 hour duration'}, excluded_embed_metadata_keys=[], excluded_llm_metadata_keys=[], relationships={}, hash='b30948011cbe9bbf29135384efbc72f85a6eb65113be0eb9762315a022f11ba1', text='Dentist Appointment Dentist appointment at 2023-12-04 at 09:30 - 1 hour duration ', start_char_idx=None, end_char_idx=None, text_template='{metadata_str}\n\n{content}', metadata_template='{key}: {value}', metadata_seperator='\n'), score=0.03278688524590164),
     NodeWithScore(node=TextNode(id_='id:assistant:mail:g=bergum@vespa.ai:2', embedding=None, metadata={'matchfeatures': {'freshness(timestamp)': 0.9232447273662552, 'nativeRank(subject)': 0.11907024479392506, 'query(threshold)': 0.8, 'cosine': 0.9049836898369259, 'keywords_and_freshness': 1.1347827754290507}, 'subject': 'Dentist Appointment Reminder', 'body': 'Dear Jo Kristian ,\nThis is a reminder for your upcoming dentist appointment on 2023-12-04 at 09:30. Please arrive 15 minutes early.\nBest regards,\nDr. Dentist'}, excluded_embed_metadata_keys=[], excluded_llm_metadata_keys=[], relationships={}, hash='21c501ccdc6e4b33d388eefa244c5039a0e1ed4b81e4f038916765e22be24705', text='Dentist Appointment Reminder Dear Jo Kristian ,\nThis is a reminder for your upcoming dentist appointment on 2023-12-04 at 09:30. Please arrive 15 minutes early.\nBest regards,\nDr. Dentist ', start_char_idx=None, end_char_idx=None, text_template='{metadata_str}\n\n{content}', metadata_template='{key}: {value}', metadata_seperator='\n'), score=0.03278688524590164)]

The above query retrieved results from both sources and blended the results from the two sources using the per schema profile scores. At runtime, we can adjust
scores per source, depending on, e.g., query context categorization. Another possibility is using generative LLMs to predict which sources to include. 

### Summary
This tutorial leveraged Vespa's streaming mode to store and retrieve personal data. Vespa streaming mode is a unique capability, allowing for building
highly cost-efficient RAG applications for personal data. Our focus extended to the practical application of custom LLamaIndex retrievers, 
connecting LLamaIndex seamlessly with a Vespa app to build advanced generative AI pipelines.

The tutorial also demonstrated the seamless blending and federation of query results from multiple data sources (multi-index RAG). We can easily
envision adding more sources or schemas, for example, to track chat message history (long-term memory) in the context of a single user, offering a 
simple and industry-leading cost-efficient way to store and search personal context.  

For those eager to learn more about Vespa, join the [Vespa community on Slack](https://vespatalk.slack.com/) to exchange ideas, seek assistance, or just stay updated on the latest Vespa developments.
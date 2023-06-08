---
layout: post
title: Vespa Newsletter, May 2023
author: kkraune
date: '2023-05-31'
categories: [newsletter]
image: assets/images/scott-graham-5fNmWej4tAA-unsplash.jpg
skipimage: true
tags: [big data serving, big data, search engines, search, database]
index: false
excerpt: >
    Advances in Vespa features and performance include multi-vector HNSW Indexing,
    global-phase re-ranking, LangChain support, improved bfloat16 throughput,
    and new document feed/export features in the Vespa CLI.
---

In the [previous update]({% post_url /newsletter/2023-03-21-vespa-newsletter-march-2023 %}),
we mentioned GPU-accelerated ML inference, BCP-aware autoscaling, and GCP Private Service Connect for Vespa Cloud.
Today, we’re excited to share the following updates:


### Multi-Vector HNSW Indexing
Finding data items by nearest neighbor search in vector space has become popular in recent years,
but suffers from one big limitation:
Each data item must be well representable by a single vector.
This is often far from possible, for example, when your data is text documents of non-trivial length.
Since 8.132, Vespa allows you to index a collection of vectors per document and retrieve by the closest in each,
using the [nearestNeighbor](https://docs.vespa.ai/en/nearest-neighbor-search.html) operator with a mixed tensor.
Read more in [revolutionizing semantic search with multi-vector HNSW indexing in Vespa](https://blog.vespa.ai/semantic-search-with-multi-vector-indexing/).


### Global-phase re-ranking
Vespa has always supported two-phase ranking on the content nodes.
In addition, it has been possible to rerank the global list of hits in
[searcher](https://docs.vespa.ai/en/searcher-development.html) code in the container.

With the new [declarative global re-ranking support](https://blog.vespa.ai/improving-llm-context-ranking-with-cross-encoders/),
Vespa can run inference and re-rank the global list of hits in the container without writing code:

<pre>
rank-profile global-phased {
    first-phase {
        expression: log(bm25(title)) + cos(distance(field,embedding))    
    }
    second-phase {
        expression { firstPhase + lightgbm("f834_v2.json")}
        rerank-count: 1000
    }
    <strong>global-phase {
        expression { sum(onnx(transformer).score) }
        rerank-count: 100
    }</strong>
}
</pre>

As global-phase ranking runs on Vespa container nodes, model inference can be GPU-accelerated, too -
combine this with [Vespa Cloud autoscaling](https://cloud.vespa.ai/en/autoscaling)
to find the sweet cost/performance spot.


### LangChain support
LangChain is a framework for developing applications powered by language models,
and usage has exploded since its launch in October 2022.
LangChain lets developers connect a language model to other sources of data.
Vespa is now integrated into LangChain as a LangChain Retriever,
letting developers use Vespa Cloud or a self-hosted Vespa instance as a data source.
See the announcement at [vespa-support-in-langchain](https://blog.vespa.ai/vespa-support-in-langchain/).


### Optimizations and features
* Since Vespa 8.141, [attributes](https://docs.vespa.ai/en/attributes.html) can now be of
  [type raw](https://docs.vespa.ai/en/reference/schema-reference.html#raw).
  A primary usecase is using it as key-value store, serving from memory -
  read more in [#26242](https://github.com/vespa-engine/vespa/issues/26242).
* Developers use the Vespa Cloud Dev Console for rapid iterations on schema and document corpus.
  It is now easy to drop all documents of an application in the console using the new _drop documents_ feature
  in the _clusters_ view.
  Feeding documents again is easy from the command line using _vespa feed_.
* Use the new [deploy.yaml](https://github.com/vespa-cloud/examples/blob/main/.github/workflows/deploy.yaml)
  as a template for production application deployment using GitHub Actions.
  This template is a basic script for how to manage secrets and names required for deployment with
  [vespa deploy](https://docs.vespa.ai/en/vespa-cli.html).
* We have improved performance of bfloat16 tensor operations by 27% since Vespa 8.158, optimizations are active.
  Read more in [#26255](https://github.com/vespa-engine/vespa/issues/26255#issuecomment-1563094123).


### Did you know?
We cut a new production release of Vespa daily Monday through Thursday.
This is essential for security and rapid bug fixing, but also how we release new features.
If you are on Vespa Cloud your applications are upgraded to the newest version automatically,
which means it is possible to request a feature and have it running in production two days later.
We encourage teams to stay on the latest versions not only for security reasons,
but also easier support and better performance.

You can see the status of our releases at [factory.vespa.oath.cloud/releases](https://factory.vespa.oath.cloud/releases):

![factory](/assets/2023-05-31-vespa-newsletter-may-2023/factory.png)


### High speed feeding using the Vespa CLI
The Vespa CLI has been updated to support vespa feed while vespa visit now supports slicing the corpus
and also filter by timestamp.
Use this with feeding to easily manage data in multiple application instances.
Read more in the [feed blog announcement](https://blog.vespa.ai/high-performance-feeding-with-vespa-cli/)
and in the [Vespa CLI](https://docs.vespa.ai/en/vespa-cli.html) documentation.


### Vespa on dockerhub
The [Vespa project](https://hub.docker.com/r/vespaengine/vespa)
has been approved for the Docker-Sponsored Open Source program.
This is good news for the Vespa users,
as the rate-limiting from docker.io has been removed for all pulls of the Vespa images.


### RSS feed
Struggling to keep up with all the great blog posts from the Vespa team?
Now it's possible to keep up-to-date with the latest post
by subscribing to the [Vespa Blog RSS feed](https://blog.vespa.ai/feed.xml).
The feed now also includes the full posts to read inline should your RSS reader support that.


### Blog posts since last newsletter
* [Private regional endpoints in Vespa Cloud](https://blog.vespa.ai/private-regional-endpoints/)
* [Revolutionizing Semantic Search with Multi-Vector HNSW Indexing in Vespa](https://blog.vespa.ai/semantic-search-with-multi-vector-indexing/)
* [Customizing Reusable Frozen ML-Embeddings with Vespa](https://blog.vespa.ai/tailoring-frozen-embeddings-with-vespa/)
* [Minimizing LLM Distraction with Cross-Encoder Re-Ranking](https://blog.vespa.ai/improving-llm-context-ranking-with-cross-encoders/)
* [Vespa support in LangChain](https://blog.vespa.ai/vespa-support-in-langchain/)
* [High performance feeding with Vespa CLI](https://blog.vespa.ai/high-performance-feeding-with-vespa-cli/)

----

Thanks for reading! Try out Vespa on [Vespa Cloud](https://cloud.vespa.ai/)
or grab the latest release at [vespa.ai/releases](https://vespa.ai/releases) and run it yourself! &#x1F600;

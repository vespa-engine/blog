---
layout: post
title: Vespa Product Updates, July 2021
author: kkraune
date: '2021-07-06'
categories: [product updates]
image: assets/images/scott-graham-5fNmWej4tAA-unsplash.jpg
skipimage: true
tags: [big data serving, big data, search engines, search, database]
index: false
excerpt: >
    Advances in Vespa features and performance include HTTP/2 feed and query endpoints,
    ONNX Runtime integration for stateless model inference,
    and the new open Vespa Factory build and test system.
    
---

In the [previous update]({% post_url /product-updates/2021-05-21-vespa-product-updates-may-2021 %}),
we mentioned bfloat16 and int8 tensor value types, case-sensitive attribute search,
attributes with hashed dictionary and Hamming distance metric for ANN search.

This month, we’re excited to share the following updates:


#### HTTP/2
HTTP/2 is now available for both search and feed endpoints.
HTTP/2 delivers more efficient network usage and increases security.
With HTTP/2, it becomes possible to feed equally efficiently using the
[document/v1 REST API](https://docs.vespa.ai/en/document-v1-api-guide.html) as with the Vespa HTTP client.
There is also a new, simplified [vespa-feed-client](https://docs.vespa.ai/en/vespa-feed-client.html).
[Read more]({% post_url /2021-07-01-http2 %}).


#### ONNX RUNTIME in the Vespa Container
We have integrated [ONNX RUNTIME](https://www.onnxruntime.ai/) also in the stateless Vespa container
which allows ONNX models to be used with:

* Automatically generated REST API for stateless model serving.
* Creating lightweight request handlers for serving models with some custom code without the need for content nodes.
* Model evaluation to Searchers for query processing and enrichment.
* Model evaluation to Document Processors for transforming content before ingestion.
* Processing results from the content nodes to add additional ranking phases.

[Read more]({% post_url /2021-07-05-stateless-model-evaluation %}).


#### factory.vespa.oath.cloud
[factory.vespa.oath.cloud/](https://factory.vespa.oath.cloud/)
is the automated build and test system for Vespa.ai - now open for everyone.
Use [factory.vespa.oath.cloud/releases](https://factory.vespa.oath.cloud/releases)
to inspect changes in each release as Vespa.ai normally releases 4 times a week.
The Vespa Factory is useful to track performance improvements tested in the performance test suite,
see e.g. [testrun/31415803](https://factory.vespa.oath.cloud/testrun/31415803/test/ProgrammaticFeedClientTest::test_throughput?tab=graphs).


#### Berlin Buzzwords 2021 recordings
Approximate nearest neighbor with filtering and real time updates has generated much attention,
and Vespa’s real time indexing structures is well explained in these talks
at [Berlin Buzzwords 2021](https://2021.berlinbuzzwords.de/).
The search engine debate is a follow-up to the
[Haystack event last January]({% post_url /2021-02-08-the-great-search-engine-debate-elasticsearch-solr-or-vespa %}):

* Jo Kristian Bergum, Anshum Gupta, Josh Devins & Charlie Hull:
  [The Debate: Which Search Engine?](https://www.youtube.com/watch?v=AlnVpDfQJ6w)
* Lester Solbakken:
  [From text search & recommendation to ads & online dating;
  approximate nearest neighbors in real world applications](https://www.youtube.com/watch?v=-NjETJIe-Xs&list=PLq-odUc2x7i9I_i403nJT9IdiyQMDira9)
* Jo Kristian Bergum:
  [Search and Sushi; Freshness Counts](https://www.youtube.com/watch?v=vFu5g44-VaY&list=PLq-odUc2x7i9I_i403nJT9IdiyQMDira9)


___
About Vespa: Largely developed by Yahoo engineers,
[Vespa](https://github.com/vespa-engine/vespa) is an open source big data processing and serving engine.
It’s in use by many products, such as Yahoo News, Yahoo Sports, Yahoo Finance, and the Yahoo Ad Platform.
Thanks to feedback and contributions from the community, Vespa continues to grow.

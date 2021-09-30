---
layout: post
title: Vespa Product Updates, September 2021
author: kkraune
date: '2021-09-30'
categories: [product updates]
image: assets/images/ilya-pavlov-OqtafYT5kTw-unsplash.jpg
skipimage: true
tags: [big data serving, big data, search engines, search, database]
index: false
excerpt: >
    Advances in Vespa features and performance include Vespa CLI, nearest neighbor performance improvements,
    mTLS security, improved write throughput and Sentencepiece Encoder.
    
---

In the [previous update]({% post_url /product-updates/2021-07-06-vespa-product-updates-july-2021 %}),
we mentioned HTTP/2, ONNX Runtime and factory.vespa.oath.cloud.

This month, we’re excited to share the following updates:


#### Vespa CLI
Vespa CLI is a zero-dependency tool built with Go, available for Linux, macOS and Windows -
it greatly simplifies interaction with a Vespa instance. Use Vespa CLI to:

* Clone Vespa sample applications
* Deploy an application to a Vespa installation running locally or remote
* Deploy an application to a dev zone in Vespa Cloud
* Feed and query documents
* Send custom requests with automatic authentication

[Read more]({% post_url /2021-09-23-introducing-vespa-cli %}).


#### Nearest neighbor search performance improvement
Exact nearest neighbor search without HNSW index improved serving performance by 20x in Vespa 7.457.52
when combined with query filters and using multiple threads per query.
HNSW index itself has a reduced memory footprint, too -
this enables applications to fit larger data sets for nearest neighbor use cases.
Reindexing an [HNSW-index](https://docs.vespa.ai/en/reference/schema-reference.html#index-hnsw)
is multithreaded since Vespa 7.436.31.
This makes it much faster to apply e.g. changes in what distance function is used depending on available CPU cores –
and is now as fast as regular multi-threaded updates to HNSW index.


#### Paged tensor attributes
Fields indexed as attributes are stored in memory which enables fast partial updates,
flexible match modes, grouping, range queries, sorting, parent/child imports, and direct use in ranking.
Dense tensor attributes can now be set as paged, which means they will mostly reside on disk rather than in memory.
This is useful for large tensors where fast access over many documents per query is not required.
[Read more](https://docs.vespa.ai/en/attributes.html#paged-attributes).


#### mTLS
With [#7219](https://github.com/vespa-engine/vespa/issues/7219),
Vespa now supports mTLS across all internal services and endpoints.
See the [blog post]({% post_url /2021-08-23-securing-vespa-with-mutually-authenticated-tls %})
for an introduction and the [reference documentation](https://docs.vespa.ai/en/mtls.html) for setup instructions.


#### Feed performance
Many applications use Vespa for [real-time partial update](https://docs.vespa.ai/en/partial-updates.html)
rates in the 1000s per node per second.
Since Vespa 7.468.9, the Vespa Distributor uses multiple threads by default
with each thread handling a distinct set of the document bucket space.
Context switching is reduced by using async operations in the network threads.
The end-to-end feed throughput have increased significantly:

* 25-40% increase in throughput for partial updates
* 25% increase in throughput for puts of summary-only data


#### Sentencepiece Embedder
A common task in modern IR is to embed a document or query in a vector space for retrieval and/or ranking,
which often means turning a natural language text into a tensor.
Since 7.474.25, Vespa ships with a [native implementation](https://github.com/vespa-engine/vespa/blob/master/linguistics-components/src/main/java/com/yahoo/language/sentencepiece/SentencePieceEmbedder.java)
of [SentencePiece](https://github.com/google/sentencepiece),
a language agnostic and fast algorithm for this task.
You can use it by having it injected into your own Java code, or by:

* On the query side, passing tensors as "embed(some text)"
* On the indexing side, use the "embed" command to turn a text field into a tensor.

As part of this we added a genetic [Embedder](https://github.com/vespa-engine/vespa/blob/master/linguistics/src/main/java/com/yahoo/language/process/Embedder.java) interface,
so applications can plug in any algorithm for this and use it in queries and indexing as described above.
See [this system test](https://github.com/vespa-engine/system-test/tree/master/tests/search/embedding)
for an example using this.


___
About Vespa: Largely developed by Yahoo engineers,
[Vespa](https://github.com/vespa-engine/vespa) is an open source big data processing and serving engine.
It’s in use by many products, such as Yahoo News, Yahoo Sports, Yahoo Finance, and the Yahoo Ad Platform.
Thanks to feedback and contributions from the community, Vespa continues to grow.

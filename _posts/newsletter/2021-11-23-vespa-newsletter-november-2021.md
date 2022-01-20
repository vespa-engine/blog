---
layout: post
title: Vespa Newsletter, November 2021
author: kkraune
date: '2021-11-23'
categories: [newsletter]
image: assets/images/scott-graham-5fNmWej4tAA-unsplash.jpg
skipimage: true
tags: [big data serving, big data, search engines, search, database]
index: false
excerpt: >
    Advances in Vespa features and performance include improved schema inheritance,
    Intellij plugin for schemas, Hamming distance in ranking,
    and performance gains in data dump and application deployment.
    
---

In the [previous update]({% post_url /product-updates/2021-09-30-vespa-product-updates-september-2021 %}),
we mentioned vespa CLI, Nearest neighbor search performance improvement, Paged tensor attributes, mTLS,
improved Feed performance, and the SentencePiece Embedder. This time, we have the following updates:


#### Schema Inheritance
In applications with multiple document types
it is often convenient to put common fields in shared parent document types to avoid duplication.
This is done by declaring that the document type in a schema inherits other types.

However, this does not inherit the other elements of the schema,
such as rank profiles and fields outside the document.
From 7.487.27 onwards, you can also let a [schema inherit another](https://docs.vespa.ai/en/schema-inheritance.html).
It will then include all the content of the parent schema, not just the document type part.

In Vespa 7.498.22, we also added support for lettings structs inherit each other;
see [#19949](https://github.com/vespa-engine/vespa/pull/19949).


#### Improved data dump performance
The [visit](https://docs.vespa.ai/en/content/visiting.html) operation
is used to export data in batch from a Vespa instance.
In November, we added features to increase throughput when visiting a lot of data:
* Streaming HTTP responses enables higher throughput,
  particularly where the client has high latency to the Vespa instance.
* [Slicing]({% post_url /2021-11-13-sliced-visiting %}) lets you partition the selected document space
  and iterate over the slices in parallel using multiple clients to get linear scaling with the number of clients.


#### Matching all your documents
Vespa now has a [true](https://docs.vespa.ai/en/reference/query-language-reference.html#literal.true) query item,
simplifying queries matching all documents, like select * from sources music, books where true.


#### More query performance tuning
More configuration options are added for query performance tuning:
* _min-hits-per-thread_
* _termwise-limit_
* _num-search-partitions_

These address various aspects of query and document matching,
see the [schema reference](https://docs.vespa.ai/en/reference/schema-reference.html#rank-profile).


#### Faster deployment
Vespa application packages can become large, especially when you want to use modern large ML models.
Such applications will now deploy faster, due to a series of optimizations we have made over the last few months.
Distribution to content nodes is faster, and rank profiles are evaluated in parallel using multiple threads -
we have measured an 8x improvement on some complex applications.

#### Hamming distance
Bitwise Hamming distance is now supported as a mathematical operation in
[ranking expressions](https://docs.vespa.ai/en/reference/ranking-expressions.html),
in addition to being a distance metric option in nearest neighbor searches.

#### The neural search paradigm shift
November 8, [Jo Kristian Bergum](https://github.com/jobergum) from the Vespa team presented
_From research to production - bringing the neural search paradigm shift to production_ at Glasgow University.
The slides are available
[here](https://docs.google.com/presentation/d/1oLt87DQhYhsw6bLkY6jmPiwzPco43HPok0bq2uI0Nao/edit?usp=sharing).


___
About Vespa: Largely developed by Yahoo engineers,
[Vespa](https://github.com/vespa-engine/vespa) is an open source big data processing and serving engine.
It’s in use by many products, such as Yahoo News, Yahoo Sports, Yahoo Finance, and the Yahoo Ad Platform.
Thanks to feedback and contributions from the community, Vespa continues to grow.

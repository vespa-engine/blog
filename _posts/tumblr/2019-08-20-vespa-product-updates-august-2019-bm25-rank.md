---
layout: post
title: 'Vespa Product Updates, August 2019: BM25 Rank Feature, Searchable Parent References,
  Tensor Summary Features, and Metrics Export'
author: kkraune
date: '2019-08-20T22:20:04-07:00'
tags:
- big data
- database
- search
- search engines
- big data serving
tumblr_url: https://blog.vespa.ai/post/187148684196/vespa-product-updates-august-2019-bm25-rank
index: false
---
In the recent [Vespa product update]({% post_url /tumblr/2019-05-31-vespa-product-updates-may-2019-deploy-large %}), we mentioned Large Machine Learning Models, Multithreaded Disk Index Fusion, Ideal State Optimizations, and Feeding Improvements. Largely developed by Yahoo engineers, [Vespa](https://github.com/vespa-engine/vespa) is an open source big data processing and serving engine. It’s in use by many products, such as Yahoo News, Yahoo Sports, Yahoo Finance, and the Verizon Media Ad Platform. Thanks to feedback and contributions from the community, Vespa continues to grow.

This month, we’re excited to share the following feature updates with you:

**BM25 Rank Feature**

The BM25 rank feature implements the Okapi BM25 ranking function and is a great candidate to use in a first phase ranking function when you’re ranking text documents. [Read more](https://docs.vespa.ai/en/reference/bm25.html).

**Searchable Reference Attribute**

A [reference attribute field](https://docs.vespa.ai/en/reference/schema-reference.html#type:reference) can be searched using the document id of the parent document-type instance as query term, making it easy to find all children for a parent document. [Learn more](https://docs.vespa.ai/en/parent-child.html).

**Tensor in Summary Features**

A tensor can now be returned in summary features.
This makes rank tuning easier and can be used in custom [Searchers](https://docs.vespa.ai/en/searcher-development.html) when generating result sets.
[Read more](https://docs.vespa.ai/en/reference/schema-reference.html#summary-features).

**Metrics Export**

To export metrics out of Vespa, you can now use the new node metric interface. Aliasing metric names is possible and metrics are assigned to a namespace. This simplifies integration with monitoring products like CloudWatch and Prometheus. [Learn more about this update](https://docs.vespa.ai/en/reference/metrics.html).

We welcome your [contributions](https://github.com/vespa-engine/vespa/blob/master/CONTRIBUTING.md) and feedback ([tweet](https://twitter.com/vespaengine) or [email](mailto:info@vespa.ai)) about any of these new features or future improvements you’d like to request.


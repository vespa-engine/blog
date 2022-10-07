---
layout: post
title: Vespa Product Updates, March 2021
author: kkraune
date: '2021-03-30'
categories: [product updates]
image: assets/images/scott-graham-5fNmWej4tAA-unsplash.jpg
skipimage: true
tags: [big data serving, big data, search engines, search, database]
index: false
excerpt: >
    Advances in Vespa features and performance last month include mass update/delete in /document/v1/,
    improved memory usage, OR-to-WeakAnd and better full node protection.
    
---

In the [previous update]({% post_url /product-updates/2021-02-02-vespa-product-updates-january-2021 %}),
we mentioned Automatic Reindexing, Tensor Optimizations, Query Profile Variant Initialization Speedup,
Explainlevel Query Parameter and PR System Testing.
Subscribe to the [mailing list](https://vespa.ai/mailing-list.html) to get these updates delivered to your inbox.

This month, we’re excited to share the following updates:


#### New features in document/v1/
The [/document/v1/ API](https://docs.vespa.ai/en/reference/document-v1-api-reference.html)
is the easiest way to interact with documents.
Since Vespa 7.354, this API lets users easily update or remove a selection of the documents,
rather than just single documents at a time.
It also lets users copy documents directly between clusters.
These new features are efficient and useful for production use-cases;
and also increase the expressiveness of the API,
which is great for playing around with- and learning Vespa.


#### weakAnd.replace
Queries with many OR-terms can recall a large set of the corpus for first-phase ranking,
hence increasing query latency.
In many cases, using [WeakAnd (WAND)](https://docs.vespa.ai/en/using-wand-with-vespa.html)
can improve query performance by skipping the most irrelevant hits.
Since Vespa 7.356, you can use [weakAnd.replace](https://docs.vespa.ai/en/reference/query-api-reference.html#weakAnd.replace)
to auto-convert from OR to WeakAnd to cut query latency.
Thanks to [Kyle Rowan](https://github.com/karowan) for submitting this in
[#16411](https://github.com/vespa-engine/vespa/pull/16411)!


#### Improved feed-block at full node
Vespa has protection against corrupting indices when exhausting disk or memory:
Content nodes [block writes](https://docs.vespa.ai/en/operations/feed-block.html) at a given threshold.
Recovering from a blocked-write situation is now made easier with
[resource-limits](https://docs.vespa.ai/en/reference/services-content.html#resource-limits) -
this blocks external writes at a lower threshold than internal redistribution,
so the content nodes retain capacity to rebalance data.


#### Reduced memory at stop/restart
Index and attribute structures are [flushed](https://docs.vespa.ai/en/proton.html#proton-maintenance-jobs) when Vespa is stopped.
Since [Vespa 7.350](https://github.com/vespa-engine/vespa/pull/16296),
the flushing is staggered based on the size of the in-memory structures to minimize temporary memory use.
This allows higher memory utilization and hence lower cost,
particularly for applications with multiple large in-memory structures.


___
About Vespa: Largely developed by Yahoo engineers,
[Vespa](https://github.com/vespa-engine/vespa) is an open source big data processing and serving engine.
It’s in use by many products, such as Yahoo News, Yahoo Sports, Yahoo Finance, and the Verizon Media Ad Platform.
Thanks to feedback and contributions from the community, Vespa continues to grow.

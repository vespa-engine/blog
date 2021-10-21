---
layout: post
title: Vespa Product Updates, June 2020
excerpt: Announcing support for approximate nearest neighbor vector search which can be combined with filters and text search with state-of-the art performance
author: kkraune
date: '2020-07-05'
categories: [product updates]
tags: [big data serving, big data, search engines, search, database]
index: false
---

In the [May updates]({% post_url /product-updates/2020-05-30-vespa-product-updates-may-2020 %}),
we mentioned Improved Slow Node Tolerance, Multi-Threaded Rank Profile Compilation, Reduced Peak Memory at Startup, Feed Performance Improvements and Increased Tensor Performance.

This month, we’re excited to share the following updates:


#### Support for Approximate Nearest Neighbor Vector Search
Vespa now supports approximate nearest neighbor search which can be combined with filters and text search.
By using a [native implementation of the HNSW algorithm]({% post_url /2020-06-30-approximate-nearest-neighbor-search-in-vespa-part-1 %}),
Vespa provides state of the art performance on vector search:
Typical single digit millisecond response time, searching hundreds of millions of documents per node,
but also uniquely allows vector query operators to be combined efficiently with filters and text search -
which is usually a requirement for real-world applications such as text search and recommendation.
Vectors can be updated in real time with a sustained write rate of a few thousand vectors per node per second.
Read more in the documentation on [nearest neighbor search](https://docs.vespa.ai/en/nearest-neighbor-search.html).


#### Streaming Search Speedup
Streaming Search is a feature unique to Vespa.
It is optimized for use cases like personal search and e-mail search -
but is also useful in high-write applications querying a fraction of the total data set.
With [#13508](https://github.com/vespa-engine/vespa/pull/13508),
read throughput from storage increased up to 5x due to better parallelism.


#### Rank Features
* The (Native)fieldMatch rank features are optimized to use less CPU query time, improving query latency for
  [Text Matching and Ranking](https://docs.vespa.ai/en/text-matching-ranking.html#ranking). 
* The new globalSequence rank feature is an inexpensive global ordering of documents in a system with stable system state.
  For a system where node indexes change, this is inaccurate.
  See [globalSequence documentation](https://docs.vespa.ai/en/reference/rank-features.html#globalSequence) for alternatives.


#### GKE Sample Application
Thank you to [Thomas Griseau](https://github.com/griseau) for contributing a new sample application
for Vespa on [GKE](https://cloud.google.com/kubernetes-engine),
which is a great way to start using Vespa on Kubernetes.


___
About Vespa: Largely developed by Yahoo engineers,
[Vespa](https://github.com/vespa-engine/vespa) is an open source big data processing and serving engine.
It’s in use by many products, such as Yahoo News, Yahoo Sports, Yahoo Finance, and the Yahoo Ad Platform.
Thanks to feedback and contributions from the community, Vespa continues to grow.

We welcome your contributions and feedback ([tweet](https://twitter.com/vespaengine)
or [email](mailto:info@vespa.ai)) about any of these new features or future improvements you’d like to request.

Subscribe to the [mailing list](https://vespa.ai/mailing-list.html) for more frequent updates!

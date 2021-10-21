---
layout: post
title: Vespa Product Updates, May 2020
excerpt: The May 2020 update includes Improved Slow Node Tolerance, Multi-Threaded Rank Profile Compilation, Reduced Peak Memory at Startup, Feed Performance Improvements, & Increased Tensor Performance.
author: kkraune
date: '2020-05-30T00:00:00-00:00'
categories: [product updates]
tags: [big data serving, big data, search engines, search, database]
index: false
---

In the [April updates]({% post_url /product-updates/2020-05-06-vespa-product-updates-april-2020 %}),
we mentioned Improved Performance for Large Fan-out Applications, Improved Node Auto-fail Handling,
CloudWatch Metric Import and CentOS 7 Dev Environment.

This month, we’re excited to share the following updates:


#### Improved Slow Node Tolerance
To improve query scaling, applications can
[group content nodes](https://docs.vespa.ai/en/performance/sizing-search.html)
to balance static and dynamic query cost.
The largest Vespa applications use a few hundred nodes.
This is a great feature to optimize cost vs performance in high-query applications.
Since Vespa-7.225.71, the
[adaptive dispatch policy](https://docs.vespa.ai/en/reference/services-content.html#dispatch-policy)
is made default.
This balances load to the node groups based on latency rather than just round robin -
a slower node will get less load, and overall latency is lower.


#### Multi-Threaded Rank Profile Compilation
Queries are using a [rank profile](https://docs.vespa.ai/en/ranking.html) to score documents.
Rank profiles can be huge, like machine learned models.
The models are compiled and validated when deployed to Vespa.
Since Vespa-7.225.71, the compilation is multi-threaded, cutting compile time to 10% for large models.
This makes content node startup quicker, which is important for rolling upgrades.


#### Reduced Peak Memory at Startup
[Attributes](https://docs.vespa.ai/en/attributes.html)
is a unique Vespa feature used for high feed performance for low-latency applications.
It enables writing directly to memory for immediate serving.
At restart, these structures are reloaded.
Since Vespa-7.225.71, the largest attribute is loaded first, to minimize temporary memory usage.
As memory is sized for peak usage,
this cuts content node size requirements for applications with large variations in attribute size.
Applications should keep memory at less than 80% of AWS EC2 instance size.


#### Feed Performance Improvements
At times, batches of documents are deleted.
This subsequently triggers compaction.
Since Vespa-7.227.2, compaction is blocked at high removal rates, reducing overall load.
Compaction resumes once the remove rate is low again. 


#### Increased Tensor Performance
[Tensor](https://docs.vespa.ai/en/tensor-user-guide.html)
is a field type used in advanced ranking expressions, with heavy CPU usage.
Simple tensor joins are now optimized and more optimizations will follow in June.


___
About Vespa: Largely developed by Yahoo engineers,
[Vespa](https://github.com/vespa-engine/vespa) is an open source big data processing and serving engine.
It’s in use by many products, such as Yahoo News, Yahoo Sports, Yahoo Finance, and the Yahoo Ad Platform.
Thanks to feedback and contributions from the community, Vespa continues to grow.

We welcome your contributions and feedback ([tweet](https://twitter.com/vespaengine)
or [email](mailto:info@vespa.ai)) about any of these new features or future improvements you’d like to request.

Subscribe to the [mailing list](https://vespa.ai/mailing-list.html) for more frequent updates!

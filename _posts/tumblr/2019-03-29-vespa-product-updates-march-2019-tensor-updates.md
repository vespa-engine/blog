---
layout: post
title: 'Vespa Product Updates, March 2019: Tensor updates, Query tracing and coverage'
author: kkraune
date: '2019-03-29T13:17:35-07:00'
tags:
- big data
- database
- search
- search engines
tumblr_url: https://blog.vespa.ai/post/183792996111/vespa-product-updates-march-2019-tensor-updates
index: false
---
In [last month’s Vespa update]({% post_url /tumblr/2019-02-28-vespa-product-updates-february-2019-boolean %}), we mentioned Boolean Field Type, Environment Variables, and Advanced Search Core Tuning. Largely developed by Yahoo engineers, [Vespa](https://github.com/vespa-engine/vespa) is an open source big data processing and serving engine. It’s in use by many products, such as Yahoo News, Yahoo Sports, Yahoo Finance, and Oath Ads Platforms. Thanks to feedback and contributions from the community, Vespa continues to grow.

This month, we’re excited to share the following updates with you:

**Tensor update**

Easily update individual tensor cells. [Add, remove, and modify cell is now supported](https://docs.vespa.ai/en/reference/document-json-format.html). This enables high throughput and continuous updates as tensor values can be updated without writing the full tensor.

**Advanced Query Trace**

Query tracing now includes [matching and ranking execution information from content nodes](https://docs.vespa.ai/en/reference/query-api-reference.html#trace.level) -
Query Explain, &nbsp;is useful for performance optimization.

**Search coverage in access log**

Search coverage is now available in the access log. This enables operators to track the fraction of queries that are degraded with lower coverage. Vespa has features to gracefully reduce query coverage in overload situations and now it’s easier to track this. Search coverage is a useful signal to reconfigure or increase the capacity for the application. Explore the [access log documentation](https://docs.vespa.ai/en/access-logging.html) to learn more.

We welcome your [contributions](https://github.com/vespa-engine/vespa/blob/master/CONTRIBUTING.md) and feedback ([tweet](https://twitter.com/vespaengine) or [email](mailto:info@vespa.ai)) about any of these new features or future improvements you’d like to request.


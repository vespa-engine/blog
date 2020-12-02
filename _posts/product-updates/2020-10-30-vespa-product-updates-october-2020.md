---
layout: post
title: Vespa Product Updates, October 2020
author: kkraune
date: '2020-10-30'
categories: [product updates]
image: assets/images/ilya-pavlov-OqtafYT5kTw-unsplash.jpg
skipimage: false
tags: [big data serving, big data, search engines, search, database]
excerpt: Improvement to Vespa feeding APIs
index: false
---

<em>Photo by
<a href="https://unsplash.com/@ilyapavlov?utm_source=unsplash&amp;utm_medium=referral&amp;utm_content=creditCopyText">
Ilya Pavlov</a> on
<a href="https://unsplash.com/s/photos/technology?utm_source=unsplash&amp;utm_medium=referral&amp;utm_content=creditCopyText">
Unsplash</a></em>

In the [September updates]({% post_url /product-updates/2020-10-01-vespa-product-updates-september-2020 %}),
we mentioned ONNX runtime integration and feeding improvements.

This month, we’re excited to share the following updates:


#### New Container thread pool configurations
When deploying, application changes are
[live reloaded](https://docs.vespa.ai/documentation/cloudconfig/application-packages.html) into the running JVM.
New code requires JVM JIT compilation, which temporarily loads the container
and causes increased query latencies for a second or two.
Many parallel threads aggravate this problem.
Vespa now has a dedicated container thread pool for feeding.
Compared to the previous default of a fixed size with 500 threads, it now defaults to 2x logical CPUs.
This both improves feed throughput and reduces latency impact during deployments.


#### Improved document/v1 API throughput
Vespa users feed their applications through feed containers in their Vespa cluster,
using either an asynchronous or a synchronous HTTP API.
Optimizations and fine-tuning of concurrent execution in these feed containers,
and the change to asynchronous handling of requests in the synchronous
[document/v1 API](https://docs.vespa.ai/documentation/reference/document-v1-api-reference.html),
has made the feed container more effective.
This has greatly increased quality of service for both search and feed during container restarts.
As a bonus, we also see a 50% increase in throughput for our performance test suite of the synchronous HTTP API,
since Vespa version 7.304.50 onwards.


#### Visibility-delay for feeding no more
[Visibility-delay](https://docs.vespa.ai/documentation/reference/services-content.html#visibility-delay)
was used to batch writes for increased write throughput.
With the recent optimizations, there is no gain in batching writes,
now it is as fast without it, the batch code is hence removed.
Visibility-delay is still working for queries, with a short cache with max 1 second TTL.
Vespa Team recommends stop using this feature, as there is no longer an advantage to have this delay.


___
About Vespa: Largely developed by Yahoo engineers,
[Vespa](https://github.com/vespa-engine/vespa) is an open source big data processing and serving engine.
It’s in use by many products, such as Yahoo News, Yahoo Sports, Yahoo Finance, and the Verizon Media Ad Platform.
Thanks to feedback and contributions from the community, Vespa continues to grow.

We welcome your contributions and feedback ([tweet](https://twitter.com/vespaengine)
or [email](mailto:info@vespa.ai)) about any of these new features or future improvements you’d like to request.

Subscribe to the [mailing list](https://vespa.ai/cloud/mailing-list.html) for more frequent updates!

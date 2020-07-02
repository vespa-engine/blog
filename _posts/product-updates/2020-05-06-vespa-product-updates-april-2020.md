---
layout: post
title: Vespa Product Updates, April 2020
excerpt: The April 2020 update includes Top-K hits, smarter data migration and CloudWatch integration. Contributing to Vespa is now easier with the release of a CentOS 7 dev environment.
author: kkraune
date: '2020-05-06T00:00:00-00:00'
categories: [product updates]
tags: [big data serving, big data, search engines, search, database]
---

In the [previous product update]({% post_url /product-updates/2020-02-28-vespa-product-updates-february-2020 %}),
we mentioned Ranking with LightGBM Models, Matrix Multiplication Performance, Benchmarking Guide, Query Builder and Hadoop Integration.

This month, we’re excited to share the following updates:


#### Improved Performance for Large Fan-out Applications
Vespa container nodes execute queries by fanning out to a set of content nodes evaluating parts of the data in parallel. When fan-out or partial results from each node is large, this can cause bandwidth to run out.
Vespa now provides an optimization which lets you control the tradeoff between the size of the partial results
vs. the probability of getting a 100% global result.
As this works out, tolerating a small probability of less than 100% correctness
gives a large reduction in network usage.
[Read more](https://docs.vespa.ai/documentation/reference/services-content.html#top-k-probability).


#### Improved Node Auto-fail Handling
Whenever content nodes fail, data is auto-migrated to other nodes.
This consumes resources on both sender and receiver nodes,
competing with resources used for processing client operations.
Starting with Vespa-7.197, we have improved operation and thread scheduling,
which reduces the impact on client document API operation latencies
when a node is under heavy migration load.


#### CloudWatch Metric Import
Vespa metrics can now be pushed or pulled into
[AWS CloudWatch](https://aws.amazon.com/cloudwatch/).
Read more in [monitoring](https://docs.vespa.ai/documentation/monitoring.html). 



#### CentOS 7 Dev Environment
A [development environment](https://github.com/vespa-engine/docker-image-dev#vespa-development-on-centos-7)
for Vespa on CentOS 7 is now available.
This ensures that the turnaround time between code changes and running unit tests and system tests is short,
and makes it easier to contribute to Vespa.

___
About Vespa: Largely developed by Yahoo engineers,
[Vespa](https://github.com/vespa-engine/vespa) is an open source big data processing and serving engine.
It’s in use by many products, such as Yahoo News, Yahoo Sports, Yahoo Finance, and the Verizon Media Ad Platform.
Thanks to feedback and contributions from the community, Vespa continues to grow.

We welcome your contributions and feedback ([tweet](https://twitter.com/vespaengine)
or [email](mailto:info@vespa.ai)) about any of these new features or future improvements you’d like to request.

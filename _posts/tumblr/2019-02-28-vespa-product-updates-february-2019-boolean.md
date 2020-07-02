---
layout: post
title: 'Vespa Product Updates, February 2019: Boolean Field Type, Environment Variables,
  and Advanced Search Core Tuning'
author: kkraune
date: '2019-02-28T12:29:30-08:00'
tags:
- database
- search
- search engines
- big data
tumblr_url: https://blog.vespa.ai/post/183115205176/vespa-product-updates-february-2019-boolean
---
In [last month’s Vespa update]({% post_url /tumblr/2019-01-28-vespa-product-updates-january-2019-parentchild %}), we mentioned Parent/Child, Large File Config Download, and a Simplified Feeding Interface. Largely developed by Yahoo engineers, [Vespa](https://github.com/vespa-engine/vespa) is an open source big data processing and serving engine. It’s in use by many products, such as Yahoo News, Yahoo Sports, Yahoo Finance, and Oath Ads Platforms. Thanks to helpful feedback and contributions from the community, Vespa continues to grow.

This month, we’re excited to share the following updates:

**Boolean field type**

Vespa has released a boolean field type in [#6644](https://github.com/vespa-engine/vespa/issues/6644). This feature was requested by the open source community and is targeted for applications that have many boolean fields. This feature reduces memory footprint to 1/8 for the fields (compared to byte) and hence increases query throughput / cuts latency. Learn more about choosing the field type [here](https://docs.vespa.ai/documentation/performance/feature-tuning.html#boolean-numeric-text-attribute).

**Environment variables**

The Vespa Container now supports setting environment variables in services.xml. This is useful if the application uses libraries that read [environment variables](https://docs.vespa.ai/documentation/reference/services-container.html#environment-variables).

**Advanced search core tuning**

You can now configure index warmup - this reduces high-latency requests at startup. Also, reduce spiky memory usage when attributes grow using resizing-amortize-count - the default is changed to provide smoother memory usage. This uses less transient memory in growing applications. More details surrounding search core configuration can be explored [here](https://docs.vespa.ai/documentation/reference/services-content.html#tuning).

We welcome your [contributions](https://github.com/vespa-engine/vespa/blob/master/CONTRIBUTING.md) and feedback ([tweet](https://twitter.com/vespaengine) or [email](mailto:info@vespa.ai)) about any of these new features or future improvements you’d like to see.


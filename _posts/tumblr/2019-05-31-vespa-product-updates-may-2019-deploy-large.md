---
layout: post
title: 'Vespa Product Updates, May 2019: Deploy Large Machine Learning Models, Multithreaded
  Disk Index Fusion, Ideal State Optimizations, and Feeding Improvements'
author: kkraune
date: '2019-05-31T17:38:04-07:00'
tags: []
tumblr_url: https://blog.vespa.ai/post/185272046721/vespa-product-updates-may-2019-deploy-large
index: false
---
In [last month’s Vespa update]({% post_url /tumblr/2019-03-29-vespa-product-updates-march-2019-tensor-updates %}), we mentioned Tensor updates, Query tracing and coverage. Largely developed by Yahoo engineers, [Vespa](https://github.com/vespa-engine/vespa) is an open source big data processing and serving engine. It’s in use by many products, such as Yahoo News, Yahoo Sports, Yahoo Finance, and the Verizon Media Ad Platform. Thanks to feedback and contributions from the community, Vespa continues to evolve.

For May, we’re excited to share the following feature updates with you:

**Multithreaded disk index fusion**

Content nodes are now able to sustain a higher feed rate by using multiple threads for disk index fusion. [Read more](https://docs.vespa.ai/documentation/proton.html#disk-index-fusion).

**Feeding improvements**

Cluster-internal communications are now multithreaded out of the box, for &nbsp;high throughput feeding operations. This fully utilizes a 10 Gbps network and improves utilization of high-CPU content nodes.

**Ideal state optimizations**

Whenever the content cluster state changes, the ideal state is calculated. This is now optimized (faster and runs less often) and state transitions like node up/down will have less impact on read and write operations. Learn more in [the dynamic data distribution documentation](https://docs.vespa.ai/documentation/elastic-vespa.html).

**Download ML models during deploy**

One procedure for using/importing ML models to Vespa is to put them in the application package in the [models](https://docs.vespa.ai/documentation/reference/application-packages-reference.html) directory. Applications where models are trained frequently in some external system can refer to the model by URL rather than including it in the application package. This use case is now documented in [deploying remote models](https://docs.vespa.ai/documentation/cloudconfig/application-packages.html#deploying-remote-models), and solves the challenge of deploying huge models.

We welcome your [contributions](https://github.com/vespa-engine/vespa/blob/master/CONTRIBUTING.md) and feedback ([tweet](https://twitter.com/vespaengine) or [email](mailto:info@vespa.ai)) about any of these new features or future improvements you’d like to request.


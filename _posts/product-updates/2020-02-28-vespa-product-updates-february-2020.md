---
layout: post
title: Vespa Product Updates, February 2020
excerpt: Advances in Vespa features and performance in February include LightGBM support, improved tensor performance, benchmarking guide and query builder library
author: kkraune
date: '2020-02-28T00:00:00-00:00'
categories: [product updates]
tags: [big data serving, big data, search engines, search, database]
index: false
---

In the [January product update]({% post_url /product-updates/2020-01-31-vespa-product-updates-january-2020 %}),
we mentioned Tensor Operations, New Sizing Guides, matched-elements-only performance and Boolean query optimizations.

This month, we’re excited to share the following updates:


#### Ranking with LightGBM Models
Vespa now supports [LightGBM](https://docs.vespa.ai/en/lightgbm.html) machine learning models
in addition to ONNX, Tensorflow and XGBoost.
LightGBM is a gradient boosting framework that trains fast, has a small memory footprint and provides similar or improved accuracy to XGBoost. LightGBM also supports categorical features.


#### Matrix multiplication performance
Vespa now uses [OpenBLAS](https://www.openblas.net/) for matrix multiplication,
which improves performance in machine-learned models using matrix multiplication.


#### Benchmarking guide
Teams use Vespa to implement applications with strict latency requirements, with the minimal cost possible.
In January we released a new sizing guide.
This month, we’re adding a [benchmarking guide](https://docs.vespa.ai/en/performance/vespa-benchmarking.html)
that you can use to find the sweet spot between cost and performance.


#### Query builder
Thanks to contributions from [yehzu](https://github.com/vespa-engine/vespa/commits?author=yehzu),
Vespa now has a fluent library for composing [queries](https://docs.vespa.ai/en/query-language.html),
see the [client](https://github.com/vespa-engine/vespa/tree/master/client) module for details.


#### Hadoop integration
Vespa is integrated with [Hadoop](https://docs.vespa.ai/en/feed-using-hadoop-pig-oozie.html) and it is easy to feed from a grid.
The grid integration now also supports conditional writes, see [#12081](https://github.com/vespa-engine/vespa/pull/12081). 


___
About Vespa: Largely developed by Yahoo engineers,
[Vespa](https://github.com/vespa-engine/vespa) is an open source big data processing and serving engine.
It’s in use by many products, such as Yahoo News, Yahoo Sports, Yahoo Finance, and the Yahoo Ad Platform.
Thanks to feedback and contributions from the community, Vespa continues to grow.

We welcome your contributions and feedback ([tweet](https://twitter.com/vespaengine)
or [email](mailto:info@vespa.ai)) about any of these new features or future improvements you’d like to request.

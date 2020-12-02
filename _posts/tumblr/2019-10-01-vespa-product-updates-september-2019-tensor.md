---
layout: post
title: 'Vespa Product Updates, September 2019: Tensor Float Support, Reduced Memory
  Use for Text Attributes, Prometheus Monitoring Support, and Query Dispatch Integrated
  in Container'
author: kkraune
date: '2019-10-01T14:14:40-07:00'
tags:
- big data
- big data serving
- search engines
- search
- database
tumblr_url: https://blog.vespa.ai/post/188063440936/vespa-product-updates-september-2019-tensor
index: false
---
In the [August Vespa product update]({% post_url /tumblr/2019-08-20-vespa-product-updates-august-2019-bm25-rank %}), we mentioned BM25 Rank Feature, Searchable Parent References, Tensor Summary Features, and Metrics Export. Largely developed by Yahoo engineers, [Vespa](https://github.com/vespa-engine/vespa) is an open source big data processing and serving engine. It’s in use by many products, such as Yahoo News, Yahoo Sports, Yahoo Finance, and the Verizon Media Ad Platform. Thanks to feedback and contributions from the community, Vespa continues to grow.

This month, we’re excited to share the following updates with you:

**Tensor Float Support**

Tensors now supports _float_ cell values, for example _tensor\<float\>(key{}, x[100])_. Using the 32 bits float type cuts memory footprint in half compared to the 64 bits double, and can increase ranking performance up to 30%. Vespa’s [TensorFlow](https://www.tensorflow.org/) and [ONNX](https://docs.vespa.ai/documentation/onnx.html) integration now converts to float tensors for higher performance. [Read more](https://docs.vespa.ai/documentation/reference/tensor.html#tensor-type-spec).

**Reduced Memory Use for Text Attributes&nbsp;**

[Attributes](https://docs.vespa.ai/documentation/attributes.html) in Vespa are fields stored in columnar form in memory for access during ranking and grouping. From Vespa 7.102, the _enum store_ used to hold attribute data uses a set of smaller buffers instead of one large. This typically cuts static memory usage by 5%, but more importantly reduces peak memory usage (during background compaction) by 30%.

**Prometheus Monitoring Support**

Integrating with the [Prometheus](https://prometheus.io) open-source monitoring solution is now easy to do using the new interface to Vespa metrics. [Read more](https://docs.vespa.ai/documentation/monitoring.html#pulling-into-prometheus).

**Query Dispatch Integrated in Container**

The Vespa query flow is optimized for multi-phase evaluation over a large set of search nodes. Since Vespa-7-109.10, the dispatch function is integrated into the Vespa Container process which simplifies the architecture with one less service to manage. [Read more](https://docs.vespa.ai/documentation/querying-vespa.html).

We welcome your [contributions](https://github.com/vespa-engine/vespa/blob/master/CONTRIBUTING.md) and feedback ([tweet](https://twitter.com/vespaengine) or [email](mailto:info@vespa.ai)) about any of these new features or future improvements you’d like to request.


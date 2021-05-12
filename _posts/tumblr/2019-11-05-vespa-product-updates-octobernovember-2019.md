---
layout: post
title: "Vespa Product Updates, October/November 2019: Nearest Neighbor and Tensor
  Ranking, Optimized JSON Tensor Feed Format, \nMatched Elements in Complex Multi-value
  Fields, Large Weighted Set Update Performance, and Datadog Monitoring Support"
author: kkraune
date: '2019-11-05T08:56:51-08:00'
tags:
- big data serving
- big data
- search engines
- search
- database
tumblr_url: https://blog.vespa.ai/post/188829632081/vespa-product-updates-octobernovember-2019
index: false
---
In the [September Vespa product update]({% post_url /tumblr/2019-10-01-vespa-product-updates-september-2019-tensor %}), we mentioned Tensor Float Support, Reduced Memory Use for Text Attributes, Prometheus Monitoring Support, and Query Dispatch Integrated in Container.

This month, we’re excited to share the following updates:

**Nearest Neighbor and Tensor Ranking**

[Tensors](https://docs.vespa.ai/en/tensor-user-guide.html) are native to Vespa. We compared [elastic.co](https://elastic.co) to [vespa.ai](https://vespa.ai) testing nearest neighbor ranking using dense tensor dot product. The result of an out-of-the-box configuration demonstrated that Vespa performed 5 times faster than Elastic. [View the test results](https://github.com/jobergum/dense-vector-ranking-performance).

**Optimized JSON Tensor Feed Format**

A tensor is a data type used for advanced ranking and recommendation use cases in Vespa. This month, we released an optimized tensor format, enabling a more than 10x improvement in feed rate. [Read more](https://docs.vespa.ai/en/reference/document-json-format.html#tensor).

**Matched Elements in Complex Multi-value Fields&nbsp;**

Vespa is used in many use cases with structured data - documents can have arrays of structs or maps. Such arrays and maps can grow large, and often only the entries matching the query are relevant. You can now use the recently released [matched-elements-only](https://docs.vespa.ai/en/reference/schema-reference.html#matched-elements-only) setting to return matches only. This increases performance and simplifies front-end code.

**Large Weighted Set Update Performance**

[Weighted sets](https://docs.vespa.ai/en/reference/schema-reference.html#type:weightedset) in documents are used to store a large number of elements used in ranking. Such sets are often updated at high volume, in real-time, enabling online big data serving. Vespa-7.129 includes a performance optimization for updating large sets. E.g. a set with 10K elements, without [fast-search](https://docs.vespa.ai/en/attributes.html#fast-search), is 86.5% faster to update.

**Datadog Monitoring Support**

Vespa is often used in large scale mission-critical applications. For easy integration into dashboards, Vespa is now in Datadog’s [integrations-extras](https://github.com/DataDog/integrations-extras/tree/master/vespa) GitHub repository. Existing Datadog users will now find it easy to monitor Vespa. [Read more](https://docs.vespa.ai/en/monitoring.html#pulling-into-datadog).

About Vespa: Largely developed by Yahoo engineers, [Vespa](https://github.com/vespa-engine/vespa) is an open source big data processing and serving engine. It’s in use by many products, such as Yahoo News, Yahoo Sports, Yahoo Finance, and the Verizon Media Ad Platform. Thanks to feedback and contributions from the community, Vespa continues to grow.

We welcome your contributions and feedback ([tweet](https://twitter.com/vespaengine) or [email](mailto:info@vespa.ai)) about any of these new features or future improvements you’d like to request.


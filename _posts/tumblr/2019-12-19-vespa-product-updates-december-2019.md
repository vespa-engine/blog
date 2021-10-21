---
layout: post
title: "Vespa Product Updates, December 2019: Improved ONNX support, New rank 
  feature attributeMatch().maxWeight, Free lists for attribute multivalue 
  mapping, faster updates for out-of-sync documents, Zookeeper 3.5.6"
author: kkraune
date: '2019-12-19T11:45:08-05:00'
tags:
- big data serving
- big data
- search engines
- search
- database
tumblr_url: https://blog.vespa.ai/post/189755117376/vespa-product-updates-december-2019-improved
index: false
---

In the [November Vespa product update]({% post_url /tumblr/2019-11-05-vespa-product-updates-octobernovember-2019 %}), we mentioned Nearest Neighbor and Tensor Ranking, Optimized JSON Tensor Feed Format, Matched Elements in Complex Multi-value Fields, Large Weighted Set Update Performance and Datadog Monitoring Support.

Today, we’re excited to share the following updates:

**Improved ONNX Support**

Vespa has added more operations to its ONNX model API, such as GEneral Matrix to Matrix Multiplication (GEMM) - see [list of supported opsets](https://docs.vespa.ai/en/onnx.html#onnx-operation-support). Vespa has also improved support for PyTorch through ONNX, see the pytorch_test.py [example](https://github.com/vespa-engine/vespa/blob/master/model-integration/src/test/models/pytorch/pytorch_test.py#L60).

**New Rank Feature attributeMatch().maxWeight**

[attributeMatch(name).maxWeight](https://docs.vespa.ai/en/reference/rank-features.html#attributeMatch(name).maxWeight) was added in Vespa-7.135.5. The value is&nbsp; the maximum weight of the attribute keys matched in a weighted set attribute.

**Free Lists for Attribute Multivalue Mapping**

Since Vespa-7.141.8, [multivalue attributes](https://docs.vespa.ai/en/attributes.html) uses a free list to improve performance. This reduces CPU (no compaction jobs) and approximately 10% memory. This primarily benefits applications with a high update rate to such attributes.

**Faster Updates for Out-of-Sync Documents**

Vespa handles replica consistency using bucket checksums. Updating documents can be cheaper than putting a new document, due to less updates to posting lists. For updates to documents in inconsistent buckets, a GET-UPDATE is now used instead of a GET-PUT whenever the document to update is consistent across replicas. This is the common case when only a subset of the documents in the bucket are out of sync. This is useful for applications with high update rates, updating multi-value fields with large sets. Explore details [here](https://github.com/vespa-engine/vespa/pull/11319).

**ZooKeeper 3.5.6**

Vespa now uses Apache ZooKeeper 3.5.6 and can encrypt communication between ZooKeeper servers.

About Vespa: Largely developed by Yahoo engineers, [Vespa](https://github.com/vespa-engine/vespa) is an open source big data processing and serving engine. It’s in use by many products, such as Yahoo News, Yahoo Sports, Yahoo Finance, and the Yahoo Ad Platform. Thanks to feedback and contributions from the community, Vespa continues to grow.

We welcome your contributions and feedback ([tweet](https://twitter.com/vespaengine) or [email](mailto:info@vespa.ai)) about any of these new features or future improvements you’d like to request.

---
layout: post
title: 'Vespa Product Updates, December 2018: ONNX Import and Map Attribute Grouping'
date: '2018-12-14T12:20:43-08:00'
tags: []
tumblr_url: https://blog.vespa.ai/post/181105335071/vespa-product-updates-december-2018-onnx-import
index: false
---
Hi Vespa Community!

Today we’re kicking off a blog post series of need-to-know updates on Vespa, summarizing the features and fixes detailed in [Github issues](https://github.com/vespa-engine/vespa/issues).

We welcome your [contributions](https://github.com/vespa-engine/vespa/blob/master/CONTRIBUTING.md) and feedback about any new features or improvements you’d like to see.

For December, we’re excited to share the following product news:

**Streaming Search Performance Improvement**  
Streaming Search is a solution for applications where each query only searches a small, statically determined subset of the corpus. In this case, Vespa searches without building reverse indexes, reducing storage cost and making writes more efficient. With the latest changes, the document type is used to further limit data scanning, resulting in lower latencies and higher throughput. Read more [here](https://docs.vespa.ai/en/streaming-search.html).

**ONNX Integration**  
[ONNX](https://onnx.ai/) is an open ecosystem for interchangeable AI models. Vespa now supports importing models in the ONNX format and transforming the models into [Tensors](https://docs.vespa.ai/en/tensor-user-guide.html) for use in ranking. This adds to the TensorFlow import included earlier this year and allows Vespa to support many training tools. While Vespa’s strength is real-time model evaluation over large datasets, to get started using single data points, try the [stateless model evaluation API](https://docs.vespa.ai/en/stateless-model-evaluation.html). Explore this integration more in [Ranking with ONNX models](https://docs.vespa.ai/en/onnx.html).

**Precise Transaction Log Pruning**  
Vespa is built for large applications running continuous integration and deployment. This means nodes restart often for software upgrades, and node restart time matters. A common pattern is serving while restarting hosts one by one. Vespa has optimized transaction log pruning with prepareRestart, due to flushing as much as possible before stopping, which is quicker than replaying the same data after restarting. This feature is on by default. Learn more in live [upgrade](https://docs.vespa.ai/en/operations/live-upgrade.html) and [prepareRestart](https://docs.vespa.ai/en/operations-selfhosted/vespa-cmdline-tools.html#vespa-proton-cmd).

**Grouping on Maps**  
Grouping is used to implement faceting. Vespa has added support to group using map attribute fields, creating a group for values whose keys match the specified key, or field values referenced by the key. This support is useful to create indirections and relations in data and is great for use cases with structured data like e-commerce. Leverage key values instead of field names to simplify the search definition. Read more in [Grouping on Map Attributes](https://docs.vespa.ai/en/reference/grouping-syntax.html).

Questions or suggestions? [Send us a tweet](https://twitter.com/vespaengine) or an [email](mailto:info@vespa.ai).


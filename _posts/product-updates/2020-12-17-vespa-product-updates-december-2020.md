---
layout: post
title: Vespa Product Updates, December 2020
author: kkraune
date: '2020-12-17'
categories: [product updates]
image: assets/images/donald-giannatti-Wj1D-qiOseE-unsplash.jpg
skipimage: false
tags: [big data serving, big data, search engines, search, database]
index: false
excerpt: >
    Advances in Vespa features and performance include improved tensor ranking performance,
    Apache ZooKeeper integration, Vespa Python API for researchers and ONNX integration.
---

<em><span>Photo by <a href="https://unsplash.com/@wizwow?utm_source=unsplash&amp;utm_medium=referral&amp;utm_content=creditCopyText">Donald Giannatti</a>
on <a href="https://unsplash.com/s/photos/data-science?utm_source=unsplash&amp;utm_medium=referral&amp;utm_content=creditCopyText">Unsplash</a></span></em>

In the [previous update]({% post_url /product-updates/2020-10-30-vespa-product-updates-october-2020 %}),
we mentioned new Container Thread Pools and Feed Throughput improvements.

This month, we’re excited to share the following updates:


#### Tensor Performance Improvements
Vespa 7.319.17 and onwards includes new optimizations to
[tensors](https://docs.vespa.ai/documentation/tensor-user-guide.html) with sparse dimensions.
We have implemented new memory structures to represent sparse and mixed tensors
and a new pipeline for evaluating tensor operations.
This has enabled applications to deploy new advanced ranking models using mixed tensors in production.
An example is a use case where end-to-end average latency went from 135ms to 13ms; a **10x** speedup.
When measuring the latency of only mixed tensor operations, the speedup is **150x**.
Latency improvement for basic sparse tensor operations is around 40%,
while more advanced sparse tensor operations have a speedup of up to **50x**.


#### Vespa Container Apache ZooKeeper Integration
Vespa allows you to add custom Java components for query and document processing.
If this code needs a shared lock across servers in a cluster,
you can now configure a container cluster to run an embedded ZooKeeper cluster
and access it through an injected component.
[Read more](https://docs.vespa.ai/documentation/using-zookeeper.html)


#### Pyvespa
pyvespa is a python library created to enable faster prototyping
and facilitate Machine Learning experiments for Vespa applications.
The library is under active development and ready for trial usage.
Please give it a try and help the Vespa team improve it through feedback and contributions.
[Read more](https://pyvespa.readthedocs.io/en/latest/index.html)


#### ONNX Runtime
To increase Vespa’s capacity for evaluating large models,
both in performance and model types supported,
Vespa has integrated [ONNX Runtime](https://cloudblogs.microsoft.com/opensource/2020/12/14/onnx-runtime-vespa-ai-integration/).
This makes it easier to use both Vespa and ONNX, as there is no conversion.
See the [blog post](https://blog.vespa.ai/stateful-model-serving-how-we-accelerate-inference-using-onnx-runtime) for details.

___
About Vespa: Largely developed by Yahoo engineers,
[Vespa](https://github.com/vespa-engine/vespa) is an open source big data processing and serving engine.
It’s in use by many products, such as Yahoo News, Yahoo Sports, Yahoo Finance, and the Verizon Media Ad Platform.
Thanks to feedback and contributions from the community, Vespa continues to grow.

We welcome your contributions and feedback ([tweet](https://twitter.com/vespaengine)
or [email](mailto:info@vespa.ai)) about any of these new features or future improvements you’d like to request.

Subscribe to the [mailing list](https://vespa.ai/cloud/mailing-list.html) for more frequent updates!

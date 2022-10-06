---
layout: post
title: Vespa Product Updates, January 2021
author: kkraune
date: '2021-02-02'
categories: [product updates]
image: assets/images/scott-graham-5fNmWej4tAA-unsplash.jpg
skipimage: true
tags: [big data serving, big data, search engines, search, database]
index: false
excerpt: >
    Advances in Vespa features and performance last month include Automatic Reindexing,
    Tensor Optimizations and Explainlevel Query Parameter for easier query blueprint tracing.
    
---

In the [previous update]({% post_url /product-updates/2020-12-17-vespa-product-updates-december-2020 %}),
we mentioned Improved Tensor Ranking Performance, Apache ZooKeeper Integration, Vespa Python API for Researchers and ONNX Integration.

Subscribe to the [mailing list](https://vespa.ai/mailing-list.html) to get these updates delivered to your inbox.

This month, we’re excited to share the following updates:


#### Automatic Reindexing
When the indexing pipeline of a Vespa application changes
(index script / index mode, or linguistics libraries),
Vespa can automatically reprocess stored data
such that the index is updated according to the new specification.
Reindexing can be triggered and inspected for an application's full corpus, for only certain content clusters,
or for only certain document types in certain clusters, using the new reindex endpoint.
This eliminates the need for data re-feed and makes it easier to improve the application's relevance.
[Read more](https://docs.vespa.ai/en/reindexing.html).


#### Tensor Optimizations
Sparse tensor dot product performance has improved by adding the optimized
[sum_max_dot_product_function](https://github.com/vespa-engine/vespa/pull/16236).
For tests on a single node, 9M passages ColBERT
(like in [vespa-engine/vespa#15854](https://github.com/vespa-engine/vespa/issues/15854#issuecomment-769013855)),
this has cut latency by 64% and hence tripled query throughput.


#### Query Profile Variant Initialization Speedup
[Query profiles](https://docs.vespa.ai/en/query-profiles.html) are used to store query variables in configuration.
In some applications, it is convenient to allow the values in query profiles to vary
depending on variables input in the query.
E.g, a query profile can contain values depending on the market in which the request originated,
the device model and the bucket in question.
With many dimensions, the space of possible combinations grows huge.
With [vespa-engine/vespa#15969](https://github.com/vespa-engine/vespa/pull/15969),
container query profiles configuration load 10x faster for an extreme use case with variants in many dimensions.


#### Explainlevel Query Parameter
Use the new [explainlevel](https://docs.vespa.ai/en/reference/query-api-reference.html#trace.explainLevel)
query parameter to trace query execution in Vespa.
With this, you can see the query plan used in the matching and ranking engine -
use this for low level debugging of query execution.


#### PR System Testing
Vespa Team loves contributions!
However, all pull request checks must pass.
Since Jan 6, one can invoke system testing from pull requests.
If you have made changes involving the config model, OSGi bundles or dependency injection,
we require that the pull request is created with [run-systemtest] in the title.
This will run an extended test suite as part of the checks.
Read more in [contributing](https://docs.vespa.ai/en/contributing).

___
About Vespa: Largely developed by Yahoo engineers,
[Vespa](https://github.com/vespa-engine/vespa) is an open source big data processing and serving engine.
It’s in use by many products, such as Yahoo News, Yahoo Sports, Yahoo Finance, and the Verizon Media Ad Platform.
Thanks to feedback and contributions from the community, Vespa continues to grow.

---
layout: post
title: Vespa Product Updates, January 2020
excerpt: The January 2020 update includes information about new tensor functions, updated sizing guides and various performance improvements.
author: kkraune
date: '2020-01-31T00:00:00-00:00'
categories: [product updates]
tags: [big data serving, big data, search engines, search, database]
index: false
---

In the [December product update]({% post_url /tumblr/2019-12-19-vespa-product-updates-december-2019 %}),
we mentioned improved ONNX support,
new rank feature attributeMatch().maxWeight,
free lists for attribute multivalue mapping,
faster updates for out-of-sync documents,
and ZooKeeper 3.5.6.

This month, we’re excited to share the following updates:


#### Tensor Functions
The tensor language has been extended with functions to allow the representation of very complex neural nets, such as [BERT](https://github.com/google-research/bert) models, and better support for working with mapped (sparse) tensors:
* [Slice](https://docs.vespa.ai/en/reference/ranking-expressions.html#slice)
  makes it possible to extract values and subspaces from tensors.
* [Literal tensors](https://docs.vespa.ai/en/reference/ranking-expressions.html#literal)
  make it possible to create tensors on the fly, for instance from values sliced out of other tensors
  or from a list of scalar attributes or functions.
* [Merge](https://docs.vespa.ai/en/reference/ranking-expressions.html#merge)
  produces a new tensor from two mapped tensors of the same type,
  where a lambda to resolve is invoked only for overlapping values.
  This can be used, for example, to supply default values which are overridden by an argument tensor.


#### New Sizing Guides
Vespa is used for applications with high performance or cost requirements.
New sizing guides for [queries](https://docs.vespa.ai/en/performance/sizing-search.html) and
[writes](https://docs.vespa.ai/en/performance/sizing-feeding.html)
are now available to help teams use Vespa optimally.


#### Performance Improvement for Matched Elements in Map/Array-of-Struct
As maps or arrays in documents can often grow large,
applications use [matched-elements-only](https://docs.vespa.ai/en/reference/schema-reference.html#matched-elements-only)
to return only matched items. This also simplifies application code.
Performance for this feature is now improved - ex: an array or map with 20.000 elements is now 5x faster.


#### Boolean Field Query Optimization
Applications with strict latency requirements, using boolean fields and concurrent feed and query load, have a latency reduction since Vespa 7.165.5 due to an added bitCount cache. For example, we realized latency improvement from 3ms to 2ms for an application with a 30k write rate. Details in [#11879](https://github.com/vespa-engine/vespa/pull/11879).

### Bug fixes / errata

#### Regression introduced in Vespa 7.141 may cause data loss or inconsistencies when using 'create: true' updates
There exists a regression introduced in Vespa 7.141 where updates marked as `create: true` (i.e. create if missing) may cause data loss or undetected inconsistencies in certain edge cases. This regression was introduced as part of an optimization effort to greatly reduce the common-case overhead of updates when replicas are out of sync.

Fixed in Vespa 7.157.9 and beyond. If you are running a version affected (7.141 up to and including 7.147) you are strongly advised to upgrade.

See [#11686](https://github.com/vespa-engine/vespa/issues/11686) for details.

___
About Vespa: Largely developed by Yahoo engineers,
[Vespa](https://github.com/vespa-engine/vespa) is an open source big data processing and serving engine.
It’s in use by many products, such as Yahoo News, Yahoo Sports, Yahoo Finance, and the Verizon Media Ad Platform.
Thanks to feedback and contributions from the community, Vespa continues to grow.

We welcome your contributions and feedback ([tweet](https://twitter.com/vespaengine)
or [email](mailto:info@vespa.ai)) about any of these new features or future improvements you’d like to request.

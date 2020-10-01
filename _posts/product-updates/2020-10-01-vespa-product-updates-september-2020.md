---
layout: post
title: Vespa Product Updates, September 2020
author: kkraune
date: '2020-10-01'
categories: [product updates]
tags: [big data serving, big data, search engines, search, database]
excerpt: Introducing ONNX-Runtime,
         Hamming Distance Metric,
         Conditional Update Performance Improvements and
         Compressed Transaction Log with Synced Ack
---

In the [August updates]({% post_url /product-updates/2020-08-27-vespa-product-updates-august-2020 %}),
we mentioned NLP with Transformers on Vespa, Grafana How-to, Improved GEO Search and Query Profile Variants.

This month, we have several exciting updates to share:


#### ONNX-Runtime
We have completed integration with ONNX-Runtime in Vespa’s ranking framework,
which vastly increases the capabilities of evaluating large deep-learning models in Vespa
both in terms of model types we support and evaluation performance.
New capabilities within hardware acceleration and model optimizations - such as quantization - 
allows for efficient evaluation of large NLP models like BERT and other Transformer models during ranking.
To demonstrate this, we have created an end-to-end question/answering system all within Vespa,
using approximate nearestneighbors and large BERT models to reach state-of-the-art on the Natural Questions benchmark.
[Read more]({% post_url 2020-09-30-efficient-open-domain-question-answering-on-vespa %}). 

#### Hamming Distance
The approximate nearest neighbor ranking feature now also supports the
[hamming distance metric](https://docs.vespa.ai/documentation/reference/schema-reference.html#distance-metric).

#### Conditional Update Performance Improvements
Conditional writes are used for test-and-set operations when updating the document corpus.
As long as the fields in the condition are
[attributes](https://docs.vespa.ai/documentation/attributes.html) (i.e. in memory),
the write throughput is now the same as without a condition, up to 3x better than before the optimization.

#### Compressed Transaction Log with Synced Ack
Vespa uses a [transaction log](https://docs.vespa.ai/documentation/proton.html#transaction-log) for write performance.
The transaction log is now synced to disk before the write ack is returned.
The transaction log is now also compressed in order to reduce IO,
and can improve update throughput by 10X if writing to attributes only.

#### In the News
Learn from the OkCupid Engineering Blog about how OkCupid uses Vespa to launch new features,
ML models in query serving, simplify operations and cut deployment drastically:
[tech.okcupid.com/vespa-vs-elasticsearch/](https://tech.okcupid.com/vespa-vs-elasticsearch/) 


___
About Vespa: Largely developed by Yahoo engineers,
[Vespa](https://github.com/vespa-engine/vespa) is an open source big data processing and serving engine.
It’s in use by many products, such as Yahoo News, Yahoo Sports, Yahoo Finance, and the Verizon Media Ad Platform.
Thanks to feedback and contributions from the community, Vespa continues to grow.

We welcome your contributions and feedback ([tweet](https://twitter.com/vespaengine)
or [email](mailto:info@vespa.ai)) about any of these new features or future improvements you’d like to request.

Subscribe to the [mailing list](https://vespa.ai/cloud/mailing-list.html) for more frequent updates!

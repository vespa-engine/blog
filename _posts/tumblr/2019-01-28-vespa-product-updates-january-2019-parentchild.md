---
layout: post
title: 'Vespa Product Updates, January 2019: Parent/Child, Large File Config Download,
  and a Simplified Feeding Interface'
date: '2019-01-28T21:01:59-08:00'
tags:
- database
- search
- big data
- search engines
tumblr_url: https://blog.vespa.ai/post/182378865716/vespa-product-updates-january-2019-parentchild
index: false
---
In [last month’s Vespa update]({% post_url /tumblr/2018-12-14-vespa-product-updates-december-2018-onnx-import %}), we mentioned ONNX integration, precise transaction log pruning, grouping on maps, and improvements to streaming search performance. Largely developed by Yahoo engineers, [Vespa](https://github.com/vespa-engine/vespa) is an open source big data processing and serving engine. It’s in use by many products, such as Yahoo News, Yahoo Sports, Yahoo Finance, and Oath Ads Platforms. Thanks to feedback and contributions from the community, Vespa continues to evolve.

This month, we’re excited to share the following updates with you:

**Parent/Child**

We’ve added support for multiple levels of parent-child document references. Documents with references to parent documents can now import fields, with minimal impact on performance. This simplifies updates to parent data as no denormalization is needed and supports use cases with many-to-many relationships, like Product Search. Read more in [parent-child](https://docs.vespa.ai/en/parent-child.html).

**File URL references in application packages**

Serving nodes sometimes require data files which are so large that it doesn’t make sense for them to be stored and deployed in the application package. Such files can now be included in application packages by using the [URL reference](https://docs.vespa.ai/en/application-packages.html). When the application is redeployed, the files are automatically downloaded and injected into the components who depend on them.

**Batch feed in java client**

The new [SyncFeedClient](https://docs.vespa.ai/en/vespa8-release-notes.html#vespa-http-client) provides a simplified API for feeding batches of data with high performance using the Java HTTP client. This is convenient when feeding from systems without full streaming support such as Kafka and DynamoDB.

We welcome your contributions and feedback (tweet or email) about any of these new features or future improvements you’d like to see.


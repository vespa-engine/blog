---
layout: post
title: Vespa Product Updates, August 2020
excerpt: Introducing NLP with Transformers, Grafana how-to, Improved GEO Search Support, Query Profile Variants Optimizations, & Build on Debian 10
author: kkraune
date: '2020-08-27'
categories: [product updates]
tags: [big data serving, big data, search engines, search, database]
index: false
---

In the [June updates]({% post_url /product-updates/2020-07-05-vespa-product-updates-june-2020 %}),
we mentioned Approximate Nearest Neighbor Search, Streaming Search Speedup, Rank Features, and a GKE Sample Application.

This month, we’re excited to share the following updates:


#### Introducing NLP with Transformers on Vespa
There has been considerable interest lately to bring sophisticated natural language processing (NLP) power
using machine learned models such as BERT and other transformer models to production.
[We have extended the tensor execution engine in Vespa to support transformer based models]({% post_url 2020-07-02-introducing-nlp-with-transformers-on-vespa %}),
so you can deploy transformer models as part of your Vespa applications
and evaluate these models in parallel on each content partition when executing a query.
This makes it possible to scale evaluation to any corpus size without sacrificing latency.

#### Grafana how-to
We released a new [Grafana](https://grafana.com/oss/grafana) integration
by leveraging our existing [Prometheus](https://prometheus.io) integration, with a few improvements.
This allows you to add Grafana monitoring to the [Quick Start](https://docs.vespa.ai/en/monitoring-with-grafana-quick-start.html)
and you can add a random load to generate a sample work graph.
We've provided a sample application to get you started with monitoring Vespa using Grafana.

#### Improved GEO Search Support
[We added support for geoLocation items](https://docs.vespa.ai/en/geo-search.html)
to the  [Vespa query language](https://docs.vespa.ai/en/query-language.html)
to make it possible to create arbitrary query conditions which include positional information.
We also added additional distance rank features to provide more support for ranking by positions. 

#### Query Profile Variants Optimizations
[Query Profile Variants](https://docs.vespa.ai/en/query-profiles.html#query-profile-variants)
make it possible to configure bundles of query parameters which vary by properties of the request, such as e.g market, bucket, or device.
We added a new algorithm for resolving the parameters that applies for a given query which greatly reduces both compilation and resolution time with variants,
leading to faster container startup and lower query latency for applications using variants.

#### Build Vespa on Debian 10
Thanks to contributions from [ygrek](https://github.com/ygrek), you can now
[build Vespa on Debian 10](https://github.com/vespa-engine/vespa/pull/14082). 

___
About Vespa: Largely developed by Yahoo engineers,
[Vespa](https://github.com/vespa-engine/vespa) is an open source big data processing and serving engine.
It’s in use by many products, such as Yahoo News, Yahoo Sports, Yahoo Finance, and the Yahoo Ad Platform.
Thanks to feedback and contributions from the community, Vespa continues to grow.

We welcome your contributions and feedback ([tweet](https://twitter.com/vespaengine)
or [email](mailto:info@vespa.ai)) about any of these new features or future improvements you’d like to request.

Subscribe to the [mailing list](https://vespa.ai/mailing-list.html) for more frequent updates!

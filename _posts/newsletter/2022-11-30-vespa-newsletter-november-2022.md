---
layout: post
title: Vespa Newsletter, November 2022
author: kkraune
date: '2022-11-30'
categories: [newsletter]
image: assets/images/ilya-pavlov-OqtafYT5kTw-unsplash.jpg
image_credit: 'Photo by <a href="https://unsplash.com/pt-br/@ilyapavlov?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Ilya Pavlov</a> on <a href="https://unsplash.com/photos/OqtafYT5kTw?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>'
skipimage: true
tags: [big data serving, big data, search engines, search, database]
index: false
excerpt: >
    Vespa features and performance advances include ANN Pre-Filter Performance,
    Parent Field Hit-Estimates, Model Training Notebooks, and GCP Support.
---

In the [previous update]({% post_url /newsletter/2022-10-31-vespa-newsletter-october-2022 %}),
we mentioned Vector Embeddings, Vespa Cloud Model Hub, Paged Attributes, ARM64 Support, and Result Highlighting.
Today, we’re excited to share the following updates:


### Improved performance when using ANN and pre-filter
Since Vespa 8.78.45, multithreaded pre-filtering before running the
[approximate nearest neighbor](https://docs.vespa.ai/en/approximate-nn-hnsw.html) query operator is supported by using
[num-threads-per-search](https://docs.vespa.ai/en/performance/practical-search-performance-guide.html#multithreaded-search-and-ranking)
in the rank-profile.
Multithreading can cut latencies for applications using pre-filtering,
where the filtering amounts to a significant part of the query latency.
[Read more](https://docs.vespa.ai/en/approximate-nn-hnsw.html#combining-approximate-nearest-neighbor-search-with-filters).


### Better hit estimates from parent document attributes
Applications can use [parent/child](https://docs.vespa.ai/en/parent-child.html) to normalize data -
keeping fields common for many documents in a parent schema.
This simplifies updating such fields and makes the update use fewer resources with many children.
When using parent fields in matching,
one can use [fast-search](https://docs.vespa.ai/en/attributes.html#fast-search)
for better performance by using a dictionary.
Since Vespa 8.84.14, a parent field with fast-search set will have a better hit estimate using the dictionary data.
The estimate is then used when creating the query plan to limit the candidate result set quicker,
resulting in lower query latency.


### New XGBoost and LightGBM model training notebooks
Vespa supports gradient boosting decision tree (GBDT) models trained with
[XGBoost](https://docs.vespa.ai/en/xgboost.html) and [LightGBM](https://docs.vespa.ai/en/lightgbm.html).
To get you started, we have released two new sample notebooks for easy training of XGBoost and LightGBM models in
[Vespa sample apps notebooks](https://github.com/vespa-engine/sample-apps/tree/master/commerce-product-ranking/notebooks).
Linked from these is an exciting blog post series on using these models in Product Search applications.


### Vespa Cloud on GCP
[Vespa Cloud](https://cloud.vespa.ai/) has been available in AWS zones since its start in 2019.
Now, we are happy to announce Vespa Cloud availability in Google Cloud Platform (GCP) zones!
To add a GCP zone to your application,
simply add `<region>gcp-us-central1-f</region>` to [deployment.xml](https://cloud.vespa.ai/en/reference/deployment).
See the [announcement]({% post_url /2022-11-08-vespa-cloud-on-gcp %}) for more details.

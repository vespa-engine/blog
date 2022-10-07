---
layout: post
title: Vespa Newsletter, December 2021
author: kkraune
date: '2021-12-22'
categories: [newsletter]
image: assets/images/ilya-pavlov-OqtafYT5kTw-unsplash.jpg
skipimage: true
tags: [big data serving, big data, search engines, search, database]
index: false
excerpt: >
    Advances in Vespa features and performance include tensor performance improvements,
    match-features and a Vespa IntelliJ plugin.
    
---

In the [previous update]({% post_url /newsletter/2021-11-23-vespa-newsletter-november-2021 %}),
we mentioned schema inheritance, improved data dump performance,
“true” query item, faster deployments and Hamming distance for ranking.
This time, we have the following updates:


#### Tensor performance improvements
Since Vespa 7.507.67, Euclidian distance calculations using int8 are 250% faster, using HW-accelerated instructions.
This speeds up feeding to HSNW-based indices, and reduces latency for nearest neighbor queries.
This is relevant for applications with large data sets per node - using int8 instead of float uses 4x less memory,
and the performance improvement is measured to bring us to 10k puts/node when using HSNW.

With Vespa 7.514.11, tensor field memory alignment for types <= 16 bytes is optimized.
E.g. a 104 bit = 13 bytes int8 tensor field will be aligned at 16 bytes, previously 32, a 2x improvement.
Query latency might improve too, due to less memory bandwidth used.

Refer for [#20073 Representing SPANN with Vespa](https://github.com/vespa-engine/vespa/issues/20073)
for details on this work, and also see
[Bringing the neural search paradigm shift to production](https://docs.google.com/presentation/d/1vWKhSvFH-4MFcs4aNa9CNAy4m_TRMNJ0oJ_va7t3OFA)
from the London Information Retrieval Meetup Group.


#### Match features
Any Vespa rank feature or function output can be returned along with regular document fields by adding it to the list of
[summary-features](https://docs.vespa.ai/en/reference/schema-reference.html#summary-features) of the rank profile.
If a feature is both used for ranking and returned with results,
it is re-calculated by Vespa when fetching the document data of the final result
as this happens after the global merge of matched and scored documents.
This can be wasteful when these features are the output of complex functions such as a neural language model.

The new [match-features](https://docs.vespa.ai/en/reference/schema-reference.html#match-features)
allows you to configure features that are returned from content nodes
as part of the document information returned before merging the global list of matches.
This avoids re-calculating such features for serving results
and makes it possible to use them as inputs to a (third) re-ranking evaluated over the globally best ranking hits.
Furthermore, calculating match-features is also part of the
multi-threaded per-matching-and-ranking execution on the content nodes,
while features fetched with summary-features are single-threaded.


#### Vespa IntelliJ plugin
[Shahar Ariel](https://github.com/shahariel) has created an IntelliJ plugin for editing schema files,
find it at [docs.vespa.ai/en/schemas.html#intellij-plugin](https://docs.vespa.ai/en/schemas.html#intellij-plugin).
Thanks a lot for the contribution!

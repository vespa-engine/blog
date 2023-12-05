---
layout: post
title: Vespa Newsletter, June 2022
author: kkraune
date: '2022-06-29'
categories: [newsletter]
image: assets/images/scott-graham-5fNmWej4tAA-unsplash.jpg
image_credit: 'Photo by <a href="https://unsplash.com/@homajob?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Scott Graham</a> on <a href="https://unsplash.com/photos/5fNmWej4tAA?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>'
skipimage: true
tags: [big data serving, big data, search engines, search, database]
index: false
excerpt: >
    Advances in Vespa features and performance include ANN with configurable filtering,
    fuzzy matching, and native embedding support.
    Also see pyvespa’s new experimental ranking module!
    
---

In the [previous update]({% post_url /newsletter/2022-04-21-vespa-newsletter-april-2022 %}),
we mentioned tensor formats, grouping improvements, new query guides,
modular rank profiles and pyvespa docker image and deployments.
Today, we’re excited to share the following updates:


#### Vespa 8
Vespa 8 is released. Vespa is now on Java 17 and
[CentOS Stream 8](https://blog.vespa.ai/Upcoming-changes-in-OS-support-for-Vespa/).
Read more about what this means for you in the [blog post](https://blog.vespa.ai/vespa-8-is-here/).


#### Pre/Post ANN filtering support
Approximate Nearest Neighbor is a popular feature in Vector Search applications, also supported in Vespa.
Vespa has integral support for combining ANN search with filters,
like "similar articles to this, in US market, not older than 14 days".
From Vespa 7.586.113, users can configure whether to use pre- or post-filtering, with thresholds.
This enables a much better toolset to trade off precision with performance, i.e. balance cost and quality.
Read more in [constrained-approximate-nearest-neighbor-search]({% post_url /2022-05-09-constrained-approximate-nearest-neighbor-search %}).


#### Fuzzy matching
Thanks to [alexeyche](https://github.com/alexeyche), Vespa supports fuzzy query matching since 7.585 –
a user typing "spageti" will now match documents with "spaghetti".
This is implemented using Levenshtein edit distance search –
e.g. one must make two "edits" (one-character changes) to make "spaghetti" from "spageti".
Find the full contribution in [#21689](https://github.com/vespa-engine/vespa/pull/21689) and documentation at
[query-language-reference.html#fuzzy](https://docs.vespa.ai/en/reference/query-language-reference.html#fuzzy).


#### Embedding support
A common technique in modern big data serving applications is to map the subject data – say, text or images –
to points in an abstract vector space and then do computation in that vector space.
For example, retrieve similar data by finding nearby points in the vector space,
or using the vectors as input to a neural net.
This mapping is usually referred to as _embedding_ –
[read more](https://docs.vespa.ai/en/embedding.html) about Vespa’s built-in support.


#### Tensors and ranking
[fast-rank](https://docs.vespa.ai/en/reference/schema-reference.html#attribute)
enables ranking expression evaluation without de-serialization, to decrease latency, on the expense of more memory used.
Supported for tensor field types with at least one mapped dimension.

Tensor [short format](https://docs.vespa.ai/en/reference/document-json-format.html#tensor)
is now supported in the [/document/v1 API](https://docs.vespa.ai/en/document-v1-api-guide.html).

Support for importing [onnx models in rank profiles](https://docs.vespa.ai/en/ranking.html#rank-profiles) is added.


#### Blog posts and training videos
Find great [Vespa blog](https://blog.vespa.ai/) posts on 
[constrained ANN-search]({% post_url /2022-05-09-constrained-approximate-nearest-neighbor-search %}),
[hybrid billion scale vector search]({% post_url /2022-06-07-vespa-hybrid-billion-scale-vector-search %}),
and Lester Solbakken + Jo Kristian Bergum at the 
[Berlin Buzzwords conference]({% post_url /2022-06-17-vespa-at-berlin-buzzwords %}) – 
[follow](https://twitter.com/jobergum) Jo Kristian for industry leading commentary.

New training videos for _Vespa startup troubleshooting_ and _auto document redistribution_
are available at [vespa.ai/resources](https://vespa.ai/resources):
<!-- Crop the black top/bottom of the youtube thumbnails -->
<style>
.cropped {
  width: 250px;
  height: 115px;
  object-fit: cover;
  object-position: 0% 35%;
}
</style>
<a href="https://www.youtube.com/watch?v=dUCLKtNchuE" target="_blank">
<img class="cropped" src="https://i.ytimg.com/vi/dUCLKtNchuE/hqdefault.jpg"
  alt="Vespa.ai: Troubleshooting startup, singlenode"/></a>
<a href="https://www.youtube.com/watch?v=BG7XZmXpIzo" target="_blank">
<img class="cropped" src="https://i.ytimg.com/vi/BG7XZmXpIzo/hqdefault.jpg"
  alt="Vespa.ai: Troubleshooting startup, multinode"/></a>
<a href="https://www.youtube.com/watch?v=HnhiesF62JY" target="_blank">
<img class="cropped" src="https://i.ytimg.com/vi/HnhiesF62JY/hqdefault.jpg"
  alt="Vespa.ai: Bucket distribution - intro" width="210"/></a>

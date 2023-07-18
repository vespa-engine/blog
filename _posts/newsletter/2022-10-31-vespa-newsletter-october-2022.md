---
layout: post
title: Vespa Newsletter, October 2022
author: kkraune
date: '2022-10-31'
categories: [newsletter]
image: assets/images/scott-graham-5fNmWej4tAA-unsplash.jpg
image_credit: 'Photo by <a href="https://unsplash.com/@homajob?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Scott Graham</a> on <a href="https://unsplash.com/photos/5fNmWej4tAA?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>'
skipimage: true
tags: [big data serving, big data, search engines, search, database]
index: false
excerpt: >
    Advances in Vespa features and performance include a BertBase Embedder / model hub,
    improved query performance, paged attributes, ARM64 support and term bolding in string arrays.
---

In the [previous update]({% post_url /newsletter/2022-09-19-vespa-newsletter-september-2022 %}),
we mentioned Rank-phase statistics, Schema feeding flexibility, the Query Builder and Trace Visualizer,
Rank trace profiling, the new `--speed-test` parameter and a new video.
Today, we’re excited to share the following updates:


### Create vector embeddings in Vespa without custom Java code
An increasingly popular reason for using Vespa is the ability to use vector embeddings
to be able to retrieve documents by semantic similarity in addition to retrieving by text tokens or attributes.
Since Vespa 8.52, we have made this easier by making it possible to use BERT-style models
to create document and query embeddings inside Vespa without writing any custom code.

The [BertBase embedder](https://docs.vespa.ai/en/embedding.html#bert-embedder) bundled with Vespa
uses a WordPiece embedder to produce a token sequence that is then input to a transformer model.
A BERT-Base compatible transformer model must have three inputs:
*  A token sequence (`input_ids`)
*  An attention mask (`attention_mask`)
*  (Optionally) Token types for cross encoding (`token_type_ids`)

Give this a try at
[simple-semantic-search](https://github.com/vespa-engine/sample-apps/tree/master/simple-semantic-search).



### Model hub: Provided ML models on Vespa Cloud
The BERT base embedder allows you to use vector search without bringing your own vectors, or writing any Java code -
but you still have to bring the model.
For our Vespa Cloud users we have made this even simpler by
[providing the models](https://cloud.vespa.ai/en/model-hub) out of the platform as well.

For us working on [Vespa.ai](https://vespa.ai/), it is always a goal to empower application developers
by making it as simple as possible to get started,
while at the same time being able to scale seamlessly to more data, higher traffic, and more complex use cases.
So of course you can still bring your own models, write your own embedders, or pass in your own vectors,
and mix and match all these capabilities in all possible ways.



### Improved query performance for filters with common terms
When making text indexes,
Vespa stores a bitvector in addition to the posting list for frequent terms to enable maximally fast matching.
If the field is used as a filter only, no ranking is needed,
and the bitvector will be used instead of the posting list.
This makes queries using such terms faster and cheaper.
The bitvector optimization is now also available for
[attribute fields with fast-search](https://docs.vespa.ai/en/attributes.html).



### Paged attributes
Fields which are stored in column stores suitable for random memory access are called attributes in Vespa.
These are used for matching, ranking and grouping, and enabling high-throughput partial updates.
By default, attributes are stored completely in memory to make all accesses maximally fast,
but some have also supported [paging](https://docs.vespa.ai/en/attributes.html#paged-attributes) out to disk
to support a wider range of tradeoffs between lookup speed and memory cost -
see e.g. [hybrid billion scale vector search](https://blog.vespa.ai/vespa-hybrid-billion-scale-vector-search/).

Since Vespa 8.69, paging support has been extended to all attribute types,
except [tensor with fast-rank](https://docs.vespa.ai/en/reference/schema-reference.html#attribute) and
[predicate](https://docs.vespa.ai/en/predicate-fields.html).



### ARM64 support
Vespa container images are now released as multiplatform, supporting both x86_64 and ARM64.
ARM64 is also available on Vespa Cloud.
[Read more](https://blog.vespa.ai/vespa-on-arm64/).



### Query result highlighting for arrays of string
Highlighting query words in results helps users see why a particular document is returned in their search result.
Since Vespa 8.53, this is supported for arrays of string in addition to single-value strings -
see the [schema reference](https://docs.vespa.ai/en/reference/schema-reference.html#bolding).



### Vespa scripts are becoming go only
The Vespa Container image was set on a diet and now has zero Perl-dependencies.
Most Vespa utilities have now instead been ported to using Go to support a wider range of client platforms
without requiring any dependencies.

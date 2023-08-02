---
layout: post
title: Vespa Newsletter, July 2023
author: kkraune
date: '2023-07-17'
categories: [newsletter]
image: assets/images/ilya-pavlov-OqtafYT5kTw-unsplash.jpg
image_credit: 'Photo by <a href="https://unsplash.com/pt-br/@ilyapavlov?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Ilya Pavlov</a> on <a href="https://unsplash.com/photos/OqtafYT5kTw?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>'
skipimage: true
tags: [big data serving, big data, search engines, search, database]
index: false
excerpt: >
    Advances in Vespa features and performance include Vector Streaming Search,
    GPU accelerated embeddings, Huggingface models
    and a solution to MIPS using a nearest neighbor search.
---

In the [previous update]({% post_url /newsletter/2023-05-31-vespa-newsletter-may-2023 %}),
we mentioned multi-vector HNSW Indexing, global-phase re-ranking, LangChain support, improved bfloat16 throughput,
and new document feed/export features in the Vespa CLI.
Today, we’re excited to share Vector Streaming Search, multiple new embedding features,
MIPS support, and performance optimizations:


### Vector Streaming Search
When searching personal data or other data sets which are divided into many subsets you never search across,
maintaining global indexes is unnecessarily expensive.
Vespa streaming search is built for these use cases, and now supports vectors in searching and ranking.

This enables vector search in personal search use cases such as personal assistants
at typically less than 5% of the usual cost,
while delivering complete rather than approximate results,
something which is often crucial with personal data.
Read more in our [announcement blog post](https://blog.vespa.ai/announcing-vector-streaming-search/).


### Use Embedder Models from Huggingface
Vespa now comes with generic support for embedding models hosted on Huggingface.
With the new Huggingface Embedder functionality,
developers can export embedding models from Huggingface
and import them in ONNX format in Vespa for accelerated inference close to where the data is created.
The Huggingface Embedder supports multilingual embedding models as well as multi-vector representations -
[read more](https://blog.vespa.ai/enhancing-vespas-embedding-management-capabilities/).


### GPU Acceleration of Embedding Models
GPU acceleration of embedding model inferences is now supported,
unlocking larger and more powerful embedding models while maintaining low serving latency.
With this, Vespa embedders can efficiently process large amounts of text data,
resulting in faster response times, improved scalability, and lower cost.

Embedding GPU acceleration is available both on Vespa Cloud and for Open Source Vespa use -
[read more](https://blog.vespa.ai/enhancing-vespas-embedding-management-capabilities/).


### More models for [Vespa Cloud](http://cloud.vespa.ai/) users
As more teams use embeddings to improve search and recommendation use cases,
easy access to models is key for productivity. From the paper:

> E5 is a family of state-of-the-art text embeddings that transfer well to a wide range of tasks.
> The model is trained in a contrastive manner with weak supervision signals
> from our curated large-scale text pair dataset (called CCPairs).
> E5 can be readily used as a general-purpose embedding model for any tasks
> requiring a single-vector representation of texts such as retrieval, clustering, and classification,
> achieving strong performance in both zero-shot and fine-tuned settings.

Vespa Cloud users can find a set of E5 models on the cloud.vespa.ai
[model hub](https://cloud.vespa.ai/en/model-hub).


### Dotproduct distance metric for ANN
The Maximum Inner Product Search (MIPS) problem arises naturally in recommender systems,
where item recommendations and user preferences are modeled with vectors,
and the scoring is just the dot product (inner product) between the item vector and the query vector.

Vespa supports a range of [distance metrics](https://docs.vespa.ai/en/reference/schema-reference.html#distance-metric)
for approximate nearest neighbor search.
Since 8.172, Vespa supports a [dotproduct](https://docs.vespa.ai/en/reference/schema-reference.html#dotproduct) distance metric,
used for distance calculations and an extension to HNSW index structures.
Read more about how using an extra dimension to map points on a 3D hemisphere
makes the vector have the same magnitude and hence solvable as a nearest neighbor problem in the
[blog post](https://blog.vespa.ai/announcing-maximum-inner-product-search/).


### Optimizations and features
* Query using emojis!
  The Unicode Characters of Category _"Other Symbol"_ contains emojis, math symbols, etc.
  From Vespa 8.172 these are indexed as letter characters to support searching for them.
  E.g., you can now try _vespa query 'select * from music where song contains "&#x1F349;"'_.
* Sorting on multivalue fields like [array](https://docs.vespa.ai/en/reference/schema-reference.html#array)
  or [weightedset](https://docs.vespa.ai/en/reference/schema-reference.html#weightedset) is now supported:
  Ascending sort order uses the lowest value while descending sort order uses the highest value.
  E.g., descending order sort on an array field with ["apple", "banana", "melon"] will use "melon" as the sort value -
  see the [reference documentation](https://docs.vespa.ai/en/reference/sorting#multivalue-sort-attribute).
* Since Vespa 8.185, you can balance feed vs query resource usage using feeding
  [niceness](https://docs.vespa.ai/en/reference/services-content.html#feeding) - use this configuration to de-prioritize feeding.
* Since Vespa 8.178, users can use conditional puts with auto-create -
  [read more](https://docs.vespa.ai/en/document-v1-api-guide.html#conditional-updates-and-puts-with-create).
* With [lidspace max-bloat-factor](https://docs.vespa.ai/en/reference/services-content.html#lidspace)
  you can fine tune this compaction job in the content node - since Vespa 8.171.
* Vespa supports [multivalue attributes](https://docs.vespa.ai/en/reference/schema-reference.html#field),
  like arrays and maps.
  In Vespa 8.181 the static memory usage of multivalue attributes is reduced by up to 40%.
  This is useful for applications with many such fields, with little data each -
  see [#26640](https://github.com/vespa-engine/vespa/issues/26640) for details.


### Blog posts since last newsletter
* Guest blog post from Andrii Yurkiv: [Leveraging frozen embeddings in Vespa with SentenceTransformers](https://blog.vespa.ai/leveraging-frozen-embeddings-in-vespa-with-sentence-transformers/)
* [Announcing Maximum Inner Product Search](https://blog.vespa.ai/announcing-maximum-inner-product-search/)
* [Announcing vector streaming search: AI assistants at scale without breaking the bank](https://blog.vespa.ai/announcing-vector-streaming-search/)
* [Vespa at Berlin Buzzwords 2023](https://blog.vespa.ai/vespa-at-berlin-buzzwords-2023/)
* [Enhancing Vespa’s Embedding Management Capabilities](https://blog.vespa.ai/enhancing-vespas-embedding-management-capabilities/)

----

Thanks for reading! Try out Vespa on [Vespa Cloud](https://cloud.vespa.ai/)
or grab the latest release at [vespa.ai/releases](https://vespa.ai/releases) and run it yourself! &#x1F600;

---  
layout: post
title: "Scaling to large datasets with Cohere binary embeddings and Vespa"
author: jobergum
date: '2024-03-21'
image: assets/2024-03-21-scaling-large-vector-datasets-with-cohere-binary-embeddings-and-vespa/phil-botha-NcqCpiwW0g0-unsplash.jpg
skipimage: false
image_credit: 'Photo by <a href="https://unsplash.com/@philbotha?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Phil Botha</a> on <a href="https://unsplash.com/photos/silhouette-of-mountains-between-sky-and-water-NcqCpiwW0g0?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Unsplash</a>'
tags: [embeddings]
excerpt: "Scaling vector search with binary embeddings from Cohere with Vespa"

---

Cohere recently released a new embedding API, now featuring support
for binary and int8 vectors. The announcement can be found in their
blog post titled [Cohere int8 & binary Embeddings - Scale Your
Vector Database to Large
Datasets](https://txt.cohere.com/int8-binary-embeddings/).

>We are thrilled to introduce Cohere Embed, the pioneering embedding
model that inherently accommodates int8 and binary embeddings.

This development is significant because:

* Binarization dramatically reduces storage requirements, compressing
vectors from 1024 floats (4096 bytes) per vector to just 128 bytes.
* Faster distance computations facilitated by[
hamming](https://docs.vespa.ai/en/reference/schema-reference.html#distance-metric)
distance, a feature natively supported by Vespa. More insights on[
hamming distance in
Vespa](https://docs.vespa.ai/en/reference/schema-reference.html#hamming).
* Multiple vector representations for the same text input allow for initial
coarse retrieval in coarse-level hamming space, followed by subsequent phases
using higher-resolution representations.  
* Significantly reduces deployment costs due to tiered storage and computations economics.

Vespa supports[
hamming](https://docs.vespa.ai/en/reference/schema-reference.html#distance-metric) distance calculations both with and without[ HNSW
indexing](https://docs.vespa.ai/en/approximate-nn-hnsw.html).

For those seeking further understanding of binary vectors, it's
recommended to explore the 2021 blog series on[ Billion-scale vector
search with Vespa](https://blog.vespa.ai/billion-scale-knn/) and
its continuation in[ part
two](https://blog.vespa.ai/billion-scale-knn-part-two/). We also
use a similar vector compression and binarization schema for [Vespa’s
colbert
embedder.](https://blog.vespa.ai/announcing-colbert-embedder-in-vespa/)


## About the new Cohere v3 embedding models

Cohere's embedding models offer the versatility of multiple vector representations for a single text input, all without incurring extra charges when utilizing the embedding API. This API allows for balancing effectiveness with cost. Users can make informed trade-offs between these factors, ensuring optimal performance within their budgetary constraints.


## Using the new Cohere embedding models with Vespa

We have built three comprehensive guides on using the new Cohere
embedding models with Vespa.

#### Embed-english-v3.0 with compact binary representation and re-scoring for improved accuracy

This is a great starting point for understanding Vespa’s capabilities
and the new Cohere embedding models. This application uses only the
most compact representation (128 bytes per vector) and includes a
single re-scoring phase that lifts retrieval accuracy to 95% using
the 32x larger float representation.

[cohere-binary-vectors-in-vespa-cloud.html](https://pyvespa.readthedocs.io/en/latest/examples/cohere-binary-vectors-in-vespa-cloud.html)
 <a target="_blank" href="https://colab.research.google.com/github/vespa-engine/pyvespa/blob/master/docs/sphinx/source/examples/cohere-binary-vectors-in-vespa-cloud.ipynb">
  <img src="https://colab.research.google.com/assets/colab-badge.svg" alt="cohere-binary-vectors-in-vespa-cloud.ipynb"/>
</a>

#### Embed-english-v3.0 with two vector representations and tiered compute and storage

This demonstrates using two representations per text, the binary
representation and the int8 version. This also features a 3 phase
coarse-to-fine retrieval and ranking pipeline. This improves accuracy
further, but increases storage (but no additional memory resources).

[billion-scale-vector-search-with-cohere-embeddings-cloud](https://pyvespa.readthedocs.io/en/latest/examples/billion-scale-vector-search-with-cohere-embeddings-cloud.html)
 <a target="_blank" href="https://colab.research.google.com/github/vespa-engine/pyvespa/blob/master/docs/sphinx/source/examples/billion-scale-vector-search-with-cohere-embeddings-cloud.ipynb">
  <img src="https://colab.research.google.com/assets/colab-badge.svg" alt="billion-scale-vector-search-with-cohere-embeddings-cloud.ipynb"/>
</a>


#### Embed-multilingual-v3 - redefining cost-efficient multilingual hybrid search

The flagship for multilingual hybrid search. Combining Vespa’s
support for multi-vector indexing, Cohere multilingual embeddings and lexical keyword search. 
This is a comprehensive guide to combining multilingual embedding models with
Vespa’s lexical matching features.

* **Indexing multiple vectors per document field**: Vespa's offers
the flexibility to index multiple vectors for each document field.
Instead of indexing chunks, we index pages with chunk-level vector
representations using the Cohere embeddings.  
* **Hybrid search with lexical linguistic processing**: Combines the power of Vespa’s
lexical linguistic processing with vector embeddings to deliver
hybrid search.  
* **Keep the context** by indexing pages with chunked
texts and their corresponding vector representation, we don’t lose
the original context of the page. This avoids duplicating metadata,
and avoids splitting the original text context into multiple different
retrievable units like with single-vector databases.


[multilingual-multi-vector-reps-with-cohere-cloud](https://pyvespa.readthedocs.io/en/latest/examples/multilingual-multi-vector-reps-with-cohere-cloud.html)
 <a target="_blank" href="https://colab.research.google.com/github/vespa-engine/pyvespa/blob/master/docs/sphinx/source/examples/multilingual-multi-vector-reps-with-cohere-cloud.ipynb">
  <img src="https://colab.research.google.com/assets/colab-badge.svg" alt="multilingual-multi-vector-reps-with-cohere-cloud.ipynb"/>
</a>



## Summary

Vespa's integration with Cohere's new embedding API seamlessly
aligns with Vespa’s support for binary and int8 vectors, optimizing
costs through tiered storage and computations. This development
holds promise for organizations seeking to enhance their RAG pipelines
and reducing cost when scaling to large datasets.


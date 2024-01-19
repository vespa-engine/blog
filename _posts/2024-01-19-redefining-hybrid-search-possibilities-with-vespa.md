--- 
layout: post
title: "Redefining Hybrid Search Possibilities with Vespa - part one"
author: jobergum
date: '2024-01-19'
image: assets/2024-01-19-redefining-hybrid-search-possibilities-with-vespa/trent-erwin-UgA3Xvi3SkA-unsplash.jpg
image_credit: 'Photo by <a href="https://unsplash.com/@tjerwin?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Trent Erwin</a> on <a href="https://unsplash.com/photos/black-framed-eyeglasses-and-black-pen-UgA3Xvi3SkA?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Unsplash</a>'
skipimage: false
tags: [hybrid search]
excerpt: 'This first blog post in a series of two on hybrid search. This first post focues on efficient hybrid retrieval and representational approaches in IR.'
---

This first blog post in a series of two on hybrid search, discusses
**first retrievers in a ranking pipeline**, where the first **retriever
phase** aims to find reasonably good candidates for a query, under
a **limited compute budget** to allow scaling the retrieval phase
to large collections of documents without incurring large costs.

## Introduction

Representational approaches in information retrieval involve
converting queries and documents into structured forms, like vectors,
to make retrieval more efficient. Representational approaches allow querying collections of 
documents without having to score all documents for a query.

Query and document representations for information retrieval come
in two **main** types: sparse and dense. For both methods, we can distinguish 
between unsupervised and supervised representations.
In other words, the representations of queries and documents could
be learned using supervision or unsupervised by using corpus
statistics.

**Let's pause for a moment to underscore the distinction between
the retrieval and ranking phases**. Many developers, accustomed to
working with technologies that offer minimal support for [phased
ranking](https://docs.vespa.ai/en/phased-ranking.html), might
instinctively view this through the lens of systems where retrieval
and ranking are implemented by distinct services. In such systems,
there's often a separation of technologies, with retrieval handled
by a subsystem—like Apache Solr or Elasticsearch—and ranking primarily
executed within a dedicated 'ranker' system that re-ranks a shallow
pool of candidates retrieved by the retriever subsystem.

Unlike systems characterized by discrete retrieval and ranking
technologies, Vespa has rich support for both retrieval and [phased
ranking](https://docs.vespa.ai/en/phased-ranking.html). In Vespa,
the retrieval phase is expressed with the Vespa query language,
using top-k scoring query operators (e.g
[nearestNeighbor](https://docs.vespa.ai/en/reference/query-language-reference.html#nearestneighbor),
[wand](https://docs.vespa.ai/en/reference/query-language-reference.html#wand)).
These operators, with the help of index structures, accelerate the
search for the top-k scoring documents without having to score all
documents in the collection.

Let us illustrate top-k scoring operators with an example from the
database world. Imagine that we have a table `products` and we want
to find the top-100 most popular products using the following SQL
query:

```
SELECT * FROM products ORDER BY popularity DESC LIMIT 100;
```

If we haven’t specified any index on the `popularity` column, the
above query would likely entail a linear table scan over all the
rows in the products table, followed by a sort operation, and finally, returning the top-100 products sorted by descending popularity.

A simplistic index implementation to speed up such top-k queries,
avoiding reading the popularity value of all the rows, would be to
maintain a sorted data structure with all the unique popularity
values with a pointer to the row ID. Then, at query time, we could
traverse this sorted data structure, starting at the largest
value and traversing it until we have found 100 products. This
illustrates a basic form of efficient top-k retrieval. Things get
more complex as you introduce additional filters to the query and
begin ranking documents based on user-specified information, typically
expressed as a free-text query.

In the following sections, we discuss representational approaches
in information retrieval that involve converting queries and documents
into structured forms, like vectors, to make retrieval (top-k search)
more efficient, allowing querying collections of billions of documents
without scoring all documents for a query.


## Sparse representations and retrieval

With sparse representations, documents and queries are represented
as sparse vectors with up to |V| dimensions, where V is the vocabulary
(unique terms in the corpus). Only dimensions (terms) that
have a non-zero weight impact the score.

**A popular unsupervised scoring function using sparse representations
is [BM25](https://docs.vespa.ai/en/reference/bm25.html)**. BM25 can
be expressed as a dot product between the query terms weights and
the document term weights. The term weights are assigned by using
document collection statistics such as inverse document frequency
and term frequency. The BM25 scoring function does not take into
account the order of the terms in the text. Put simply; a document
or a query is represented as a “bag of terms”. BM25 offers the
advantage of easily applying it to your document collection, providing
a decent baseline for text search [without any labeled
data](https://blog.vespa.ai/improving-zero-shot-ranking-with-vespa/).
During index building, it analyzes the corpus to determine term
occurrences and calculates term statistics, such as term frequency
and document frequency. **The drawback, however, is its vulnerability
to vocabulary mismatch—if the query uses different terms than those
in the document, retrieval may fail.**

Another less dated example of a sparse representational model is
SPLADE (_Sparse Lexical and Expansion Model for Information
Retrieval)_. [SPLADE](https://arxiv.org/abs/2109.10086) can, given labeled data of the form (query,
relevant document, irrelevant document) learn sparse representations
of documents and queries that optimizes in-domain search ranking
performance.

**Compared to BM25, SPLADE representations of both queries and
documents are denser, as queries and documents are expanded with
terms**. In addition to more non-zero dimensions, the term weights
are contextualized by other terms in the text within the context
length limitation of the Transformer model that SPLADE uses. As
with BM25, the scoring function of SPLADE is expressed as a dot
product between the non-zero query and document terms.

Top-k retrieval for both mentioned sparse representational methods
can be done in (potential) sub-linear time using inverted indices.
The search for the _top-k_ ranked documents can be accelerated by
dynamic pruning algorithms like
[WAND](https://docs.vespa.ai/en/using-wand-with-vespa.html). Dynamic
pruning retrieval algorithms attempt to avoid exhaustively scoring
all documents (linear complexity) that match at least one of the
terms in the query.

The effectiveness of dynamic pruning algorithms for top-k scoring,
as opposed to exhaustive scoring, depends on factors such as k,
sparseness (number of non-zero terms), and the distributions of
term weights. In the case of learned sparse expansion models like
SPLADE, the efficiency of result pruning is influenced by both the
density and [wacky weights](https://arxiv.org/abs/2110.11540).
**This negative serving performance observation might be unexpected, given
that many have advocated for sparse expansion models based on their
perceived simplicity in utilizing inverted index structures.**

Acceleration of sparse top-k retrieval, using dynamic pruning
algorithms like WAND, is the magic sauce of search engine
implementations. Implementing a BM25 scoring function for a query
and document pair is trivial, while implementing top-k pruning
algorithms to avoid exhaustively scoring all documents is not. This
means that technologies that advertise support for sparse vector
representations [might not dislodge mature search
engines](https://blog.vespa.ai/will-vector-dbs-dislodge-search-engines/).


### Sparse retrieval in Vespa

There are two WAND algorithm implementations for sublinear top-k
retrieval in Vespa that are useful for _retrieval_ models using
sparse representations:

**weakAnd**

The
[weakAnd()](https://docs.vespa.ai/en/reference/query-language-reference.html#weakand)
query operator which fully integrates with language-dependent
linguistic processing of text. This operator does not require much
thinking, define a string field in the Vespa schema, feed the
documents, and issue queries:

```json
{
  "query": "what was the manhattan project?",
  "yql": "select * from sources * where userQuery()"
}
```

This is a [handy
beginning](https://docs.vespa.ai/en/tutorials/text-search.html) for
developers. They can easily set up a solid text ranking baseline
for their data without delving into Vespa's inner workings. Vespa
speeds up the query with the WAND algorithm, skipping the need to
score every matching document in the corpus. It's worth noting that
for certain cases with smaller document collections (a few million
documents), scoring all documents is doable within 100 milliseconds
on modern hardware, using [multithreaded query
execution](https://docs.vespa.ai/en/performance/practical-search-performance-guide.html#multithreaded-search-and-ranking),
without attempting to prune the result.

**wand**

The [wand()
](https://docs.vespa.ai/en/reference/query-language-reference.html#wand)Vespa
query operator is useful for retrieval using sparse learned
representations of documents and queries, beyond text search use
cases. The wand implementation in Vespa was primarily developed for
efficient retrieval for [recommendation use
cases](https://blog.vespa.ai/parent-child-joins-tensors-content-recommendation/),
using interaction data to learn sparse representations of users and
items for large-scale recommendation use cases and where the wand
operator is used for efficient candidate retrieval.

The developer controls the vocabulary (number of unique dimensions
or “terms”), and where the query and document weights of each
dimension is provided using integer precision. That means, that if
the sparse representational model uses float, the float weights
must be scaled to integer representations to be used with the wand
query operator.

Take SPLADE, for instance, it uses a vocabulary of around 30K words
using the English BERT language model wordpiece tokenizer. Instead
of using the actual words or subword string representation, you can
use subword vocabulary identifiers that fit into the signed int
type in Vespa. For instance, the phrase “what was the manhattan
project” can be represented by the corresponding wordpiece token
identifiers such as 2054, 2001, 1996, 7128, 2622.

Their term weights are assigned by the sparse representational
model. In Vespa, sparse learned representations for top-k retrieval
with the wand query operator, are best expressed using a schema
field of the type
[weightedset](https://docs.vespa.ai/en/reference/schema-reference.html#weightedset)

```
schema doc {
   
   field sparse_rep type weightedset<int> {
	indexing: summary | attribute
       attribute: fast-search
   }

}
```

In ranking phases, one can also use [Vespa’s tensors
support](https://docs.vespa.ai/en/tensor-user-guide.html), using a
mapped tensor to represent the sparse representation, but this post
focuses on using sparse representations for efficient top-k retrieval,
where we have to currently use integer precision weights.

Then using the model (and converted to integer weights), feed
documents to Vespa:
```json
{
    "id": "id:namespace..::doc",
    "fields": {
        "sparse_rep": { 
 		    "2054": 12,
            "2001": 9,
            "1996": 7,
            "7128":34,
            "2622": 53
        }
    }
}
```

One can then query the sparse representation using the wand query
operator:

```json
{
    "yql": "select * from sources * where ({targetHits:100}wand(sparse_rep,@sparse_query_rep))",
    "sparse_query_rep": "{2622:45, 7128:23}"
}
```

## Dense representations and retrieval

With dense representations, queries and documents are embedded into
a [latent low-dimensional](https://en.wikipedia.org/wiki/Latent_space) dense vector space where most dimensions
have a non-zero weight.

Scoring a document for a query can be done by a vector similarity
function such as cosine or a dot product. Dense vector text
representations are commonly referred to as text embeddings and
similar to SPLADE, require inference with a Transformer-based
language model for both queries and documents.

Dense representations using language models require in-domain
training data (supervised in the same way as other supervised
retrieval models) or hoping that an off-the-shelf embedding
model [transfers to your data in a zero-shot
setting.](https://blog.vespa.ai/improving-zero-shot-ranking-with-vespa/)

Retrieval over dense representations is accelerated by approximate
nearest neighbor search algorithms, for example indexing the document
[vector(s)](https://blog.vespa.ai/semantic-search-with-multi-vector-indexing/)
representations using [HNSW](https://docs.vespa.ai/en/approximate-nn-hnsw.html) indexing. 

In addition to single-vector representations, there are also multi-vector
representations of text, which represents a text using multiple
term vectors. Take
[ColBERT](https://blog.vespa.ai/pretrained-transformer-language-models-for-search-part-3/)
for instance, it learns contextual term vector embeddings, and where
scoring uses a multi-vector similarity expression.


### Dense retrieval in Vespa

An important difference between needing to perform efficient retrieval
over dense representations and ranking is that the latter does not
require building data structures for fast but approximate nearest
neighbor search.

**It’s possible in Vespa to retrieve using a sparse representation
using inverted indices, accelerated by any of the mentioned sparse
retrieval methods, and use dense representational models during
ranking phases.**

Such approaches are attractive as they eliminate the need for
[HNSW](https://docs.vespa.ai/en/approximate-nn-hnsw.html) data
structures to facilitate fast dense retrieval, which can be a
significant cost driver for real-time indexing in large-scale
production deployments. This is also true for retrieval and ranking
models that use several dense representational models, **adding
HNSW indexes to dense representations that are only used in ranking
phases is a fruitless waste of computing and storage.**

The following example defines two document embedding fields where
only the first has an HNSW index enabled (controlled by the `index` switch).

```
schema doc {
	document doc {
          field body type array<string> {..}
          field llm_summary type string {..}
    }
    field embedding1 type tensor<bfloat16>(p{}, x[384]) {
          indexing: input body | embed model-1 | attribute | index	    
    }
	field embedding2 type tensor<bfloat16>(x[768]) {
          indexing: input llm_summary | embed model-2 | attribute	    
    }
}
```

For this type of schema, we can effectively retrieve over the
`embedding1` field with an HNSW index while using `embedding2` in
ranking phases without incurring the overhead of the HNSW indexing
`embedding2` field. Details on representing text embedding models in
Vespa are found in [embedding
documentation](https://docs.vespa.ai/en/embedding.html).

```json
{
  "yql": "select * from sources * where {targetHits:100}nearestNeighbor(embedding1, q1)",
  "input.query(q1)": "embed(model-1, \"the query\")",
  "input.query(q2)": "embed(model-2, \"the query\")"
}
```
In the above Vespa query example, we retrieve efficiently over the
embedding1 field with HNSW enabled using the nearestNeighbor query
operator. In addition, we run inference with model-2 to produce
another query vector representation that can be used during Vespa
ranking phases.

Enabling the combination of sparse and dense representations in the
same query enhances the flexibility of the way we can implement
hybrid search. **This flexibility helps manage trade-offs involving
indexing speed, resource usage, and query performance.** For instance,
the HNSW graph algorithm relies on accessing document vectors during
both query and ingest times. 

This implies that, for optimal performance, the vectors must be
stored in memory. However, if **vector similarity is not utilized
for top-k retrieval, the vector data can be paged from disk during
ranking phases, because during the ranking phases, we have significantly 
less random accesses to vector data**.

With Vespa, developers can use the Vespa [paged attribute
option](https://docs.vespa.ai/en/attributes.html#paged-attributes) that
allows the system to page the tensor data from disk as needed during
ranking.

```
field embedding2 type tensor<bfloat16>(x[768]) {
  indexing: input text | embed model-2 | attribute
  attribute: paged 
 }
```

Vectors or tensors in general, can easily have a large footprint
per document (above uses 1536 bytes per document). Moving large
amounts of vector data across the network for re-ranking will quickly
saturate network capacity for smaller instance types. With Vespa, 
developers can express that the similarity calculations should happen where the data is stored, eliminating the network
throughput scaling bottlenecks.

There is also increasing interest in using sparse representation
models for retrieval, and use semantic (or dense) models for
re-ranking. In [Lexically Accelerated Dense Retrieval
(LADR)](https://arxiv.org/abs/2307.16779), the authors propose an
interesting approach that combines lexical (sparse) retrieval with
re-ranking using a dense model. LADR uses a two-phase retrieval
process, first retrieving a set of candidate documents using lexical
(sparse) retrieval, for example, BM25. The retrieved documents seed
an exploration of a proximity graph formed by documents to document
similarities. The candidates retrieved by the initial phase and
those discovered through the graph traversal are scored (query,
document) with the semantic (dense representational) ranking model.
**Interestingly enough, this approach lifts precision ranking metrics
like nDCG@10 compared to best-case exhaustive dense similarity
search because the initial sparse phase targets exact keyword matches**.


## Hybrid Retrieval in Vespa

Research indicates that combining dense and sparse methods could
improve the overall ranking effectiveness. The classic hybrid
retrieval approach combines dense and sparse retrieval but requires
technology that supports both retrieval types. **Vespa supports
hybrid retrieval, expressed in the same query by combining the
sparse wand and dense nearestNeighbor query operators in the same
query.**

There are multiple useful ways to combine these two dynamic pruning
algorithms in the Vespa Query Language for efficient top-k retrieval:

### Disjunction (OR)

With disjunction, we can express *retrieval* using sparse and
dense top-k retrieval algorithms in the same query. The retrieved
hits (potential disjoint set of candidates) are then exposed into
the Vespa ranking phases.

```json
{
  "yql": "select * from sources * where ({targetHits:100}nearestNeighbor(embedding1, q1)) or userQuery()",
  "query": "the query",
  "input.query(q1)": "embed(model-1, \"the query\")"
}
```

In this example, we ask Vespa to expose 100 (per node involved in
the query) to ranking phases using the `nearestNeighbor` query operator
or the best lexical matches using the `weakAnd` query operator.

How these candiates are scored and ranking is determined by the Vespa ranking phases.
One can also [use multiple nearestNeighbor search
operators](https://docs.vespa.ai/en/nearest-neighbor-search-guide.html#multiple-nearest-neighbor-search-operators-in-the-same-query)
in the same query request.

### RANK ()

The Vespa
[rank()](https://docs.vespa.ai/en/reference/query-language-reference.html#rank)
query operator allows retrieval using the first operand and allows
matching features calculated for those documents retrieved by the
first operand using the other operands.

```json
{
  "yql": "select * from sources * where rank(({targetHits:100}nearestNeighbor(embedding1, q1)), userQuery())",
  "query": "the query",
  "input.query(q1)": "embed(model-1, \"the query\")",
}
```

In the above example, Vespa uses dense retrieval to retrieve top-100 hits into
ranking phases, but at the same time, allows the calculation of sparse
matching features for the best semantic matching documents

The following inverts the above logic. Instead of dense first, it performs sparse retrieval using `weakAnd`, then uses the dense model for ranking. 
This way of querying Vespa does not benefit performance-wise with an HNSW index because the top-k retrieval uses the lexical `weakAnd` operator. 

```json
{
  "yql": "select * from sources * where rank(userQuery(), ({targetHits:100}nearestNeighbor(embedding1, q1)))",
  "query": "the query",
  "input.query(q1)": "embed(model-1, \"the query\")",
}
```

Both query operators can be combined with the flexibility of
the Vespa query language, for example, constraining the search by
filters. Similarly, one can combine `weakAnd` with `wand` in the same
query, or combine all three mentioned query operators. 

The Vespa `rank()` query operator accepts an arbitrary number of operands, but only
the first one is used for top-k _retrieval_.


## Summary

In this post, we explored representational approaches in information
retrieval, focusing on sparse and dense representations for queries
and documents. We made a clear distinction between efficient retrieval
and ranking, without going into details on how to combine different
dense and sparse signals in the ranking phases. That is the topic for the upcoming blog post in this series, 
where we will look at how to combine sparse and dense ranking signals for hybrid ranking practically.


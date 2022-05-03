---
layout: post
title: Run-Time Constrained Approximate Nearest Neighbor Search 
date: '2022-05-03'
categories: [vector search, filters]
tags: []
image: assets/2022-05-09-constrained-approximate-nearest-neighbor-search/christopher-burns-Kj2SaNHG-hg-unsplash.jpg
author: geirst jobergum
skipimage: true

excerpt: This blog post describes Vespa's support for combining approximate nearest neighbor search, or vector search, with run time filters or constraints to tackle real-world search and recommendation use cases at scale.
---
<img src="/assets/2022-05-09-constrained-approximate-nearest-neighbor-search/christopher-burns-Kj2SaNHG-hg-unsplash.jpg"/>
<p class="image-credit">

Photo by <a href="https://unsplash.com/@christopher__burns">
Christopher Burns</a> on <a href="https://unsplash.com/s/photos/stars">Unsplash</a>
</p>

This blog post describes Vespa's support for combining [approximate nearest neighbor search](https://docs.vespa.ai/en/approximate-nn-hnsw.html),
or vector search, with run time filters or constraints to tackle real-world search and recommendation use cases at scale.
The first section covers the data structures Vespa builds to support fast online search in vector fields and other field types. 
The blog post then describes the two primary strategies for combining vector search with filters; pre- or post-filtering. 
Finally, the blog post introduces two Vespa parameters for controlling vector search filtering behavior to 
achieve optimal functionality with the lowest possible resource usage.

## Introduction 
Many real-world problems need run-time constrained vector search. For example, real-time recommender systems 
using vector search for candidate retrieval need to filter recommendations by hard constraints like 
regional availability and age group suitability. Likewise, search systems using vector search need to support filtering.
For example, typical e-commerce search interfaces allow users to navigate and filter search results using result facets. 

Vespa's document model supports representing multiple field and collection types in the same 
[document schema](https://docs.vespa.ai/documentation/schemas.html).
Supported Vespa schema [field types](https://docs.vespa.ai/en/reference/schema-reference.html#field-types) 
include `string`, `long`, `int`, `float`, `double`, geo `position`, `bool`, `byte`, and `tensor` fields. 
Vespa’s first-order dense [tensor](https://docs.vespa.ai/en/tensor-user-guide.html) fields represent vector fields. 
Vespa's tensor fields support different [tensor cell precision](https://docs.vespa.ai/en/tensor-user-guide.html#cell-value-types) types,
ranging from `int8` for binary vectors to `bfloat16`, `float`, and `double` for real-valued vectors. 
Allowing vectors and other field types in the same document schema enable searching the vector field(s) in 
combination with filters expressed over other fields. 

This blog post uses the following track [Vespa document schema](https://docs.vespa.ai/documentation/schemas.html) 
to exemplify combining vector search with filters. 

<pre>
schema track {

  document track {

    field title type string {
      indexing: index | summary
      index: enable-bm25
      match: text 
    }

    field tags type array&lt;string&gt; {
      indexing: attribute | summary 
      attribute: fast-search
      rank: filter
      match: exact 
    }

    field embedding type tensor&lt;float&gt;(x[384]) {
      indexing: attribute | index 
      attribute {
        distance-metric: euclidean
      }          
    }
  }
  rank-profile closeness {
    first-phase { 
      expression: closeness(field, embedding) 
    } 
  } 
}
</pre>

The [practical nearest neighbor search guide](https://docs.vespa.ai/en/performance/practical-search-performance-guide.html) 
uses a similar schema, indexing a subset of the [last.fm](http://millionsongdataset.com/lastfm/) track dataset. 
The simplified track document type used in this post contains three fields; track title, track tags, and track embedding:

* The track `title` is configured for regular text indexing and matching using the default matching mode for 
indexed `string` fields, [match:text](https://docs.vespa.ai/en/reference/schema-reference.html#match).  
* The track `tags` field is an [array](https://docs.vespa.ai/en/reference/schema-reference.html#type:array) of strings, 
configured for exact database-style matching using Vespa’s `match:exact`. 
* The track `embedding` field is a first-order tensor (vector) using float tensor cell precision. 
X[384] denotes the named dimension (x) and the dimensionality (384). A vector field searched using 
Vespa’s [nearestNeighbor](https://docs.vespa.ai/en/reference/query-language-reference.html#nearestneighbor)
query operator must define a [distance-metric](https://docs.vespa.ai/en/reference/schema-reference.html#distance-metric). 
See also the Vespa [tensor user guide](https://docs.vespa.ai/en/tensor-user-guide.html).

The embedding vector field can be produced by, for example, a dense embedding model like 
[sentence-transformers/all-MiniLM-L6-v2](https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2). 

Vespa builds data structures for efficient query evaluation for fields with 
[indexing: index](https://docs.vespa.ai/en/reference/schema-reference.html#index) or `attribute` fields 
defined with the [attribute: fast-search](https://docs.vespa.ai/en/reference/schema-reference.html#attribute) property. 
The data structures used for non-tensor fields are variants of the classic inverted index data structure.
The inverted index data structure enables fast query evaluation of boolean queries, expressed using
[Vespa's query language](https://docs.vespa.ai/en/query-language.html): 

<pre>
select * from track where tags contains “90s” and tags contains “pop” 
</pre>

Vespa builds [Hierarchical Navigable Small World (HNSW)](https://docs.vespa.ai/en/approximate-nn-hnsw.html) 
graphs for first-order dense tensor fields or vector fields to support a fast, approximate nearest neighbor search. 
Read more in the [introducing HNSW support in Vespa](https://blog.vespa.ai/approximate-nearest-neighbor-search-in-vespa-part-1/)
blog post. 

Vespa's implementation of the *HNSW* graph data structure allows for fast approximate nearest neighbor searches like: 
<pre>
select * from track where {targetHits:3, approximate:true}nearestNeighbor(embedding, query_embedding) 
</pre>
This example searches for the three (approximate) nearest neighbors of the 
input query embedding vector using the configured 
[distance-metric](https://docs.vespa.ai/en/reference/schema-reference.html#distance-metric). 

<img src="/assets/2022-05-09-constrained-approximate-nearest-neighbor-search/vespa-data-structures.png"/>
<em>**Figure 1** illustrates, on a high level, Vespa's data structures for all types of fields, 
including vector fields with *HNSW* enabled.</em>

## Search Query Planning And Estimation
Vespa builds a query plan that tries to optimize the query execution. 
A significant part of the execution planning is estimating how many documents each branch of the query tree will match. 
The estimation process uses information present in per-field inverted index data structures.

Query terms searching fields with inverted index structures enabled, 
use the size of posting lists as the hit count estimate. Other terms in the query 
might use the number of searchable documents as an estimate, as it’s not known how many hits they will produce.
Furthermore, sub-trees of ANDed terms use the minimum estimate of their children, 
and OR-terms use the saturated sum of their children. 
Finally, the complete query hit estimate is scaled with 
the number of searchable documents to get an *estimated-hit-ratio* [0, 1].

Using the high-level illustration in Figure 1, a query for <em>tags contains “90s” or tags contains “pop”</em> 
is estimated to match the sum of the length of the posting lists of the two terms (4+7=11). 
A query for <em>tags contains “90s” and tags contains “pop”</em> is estimated to match 
at most four documents (min(4,7) = 4). The hit estimates determine the query execution plan. 
An optimal query evaluation for *90s and pop* would start with the shortest posting list (*90s*) 
and intersect with the postings of the longest (*pop*). 
The query execution with the intersection of these two posting lists will only match one document (*D9*), 
which is less than the estimated hit count. Estimation is a best-effort process, 
overestimating the number of documents the query will match. 

The posting lists of the inverted index can be of different granularity, which can help optimize the query execution. 
For example, using [rank: filter](https://docs.vespa.ai/en/reference/schema-reference.html#rank) for `attribute` fields 
with [fast-search](https://docs.vespa.ai/en/reference/schema-reference.html#attribute), enables compact posting list representation for frequent terms. 

## Combining exact nearest neighbor search with filters 
Given a query vector, Vespa’s [nearestNeighbor query operator](https://docs.vespa.ai/en/reference/query-language-reference.html#nearestneighbor) 
finds the (`targetHits`) nearest neighbors using the configured 
[distance-metric](https://docs.vespa.ai/en/reference/schema-reference.html#distance-metric). 

The retrieved hits are exposed to [first-phase ranking](https://docs.vespa.ai/en/ranking.html),
where the retrieved neighbors can be re-ranked using more sophisticated ranking models beyond the pure vector similarity. 
The examples in this blog post use the [closeness rank feature](https://docs.vespa.ai/en/reference/rank-features.html#closeness(dimension,name))
directly as the `first-phase` rank expression:

 <pre>
rank-profile closeness { 
  first-phase { 
    expression: closeness(field, embedding) 
  } 
} 
</pre>

Developers might switch between using `approximate:true`, which searches the [HNSW](https://docs.vespa.ai/en/approximate-nn-hnsw.html) 
graph data structure, and using exact search, setting `approximate:false`. 
The ability to switch between approximate and exact enables quantifying accuracy 
loss when turning to the faster, but approximate search. Read more about `HNSW` parameters and accuracy tradeoffs in the 
[billion scale vector search part two](https://blog.vespa.ai/billion-scale-knn-part-two/) blog post. 

It’s trivial to combine the exact nearest neighbor search with filters, and the computational 
complexity of the search is easy to understand. 
For example, the following query searches for the exact nearest neighbors of the query embedding using 
the `euclidean` [distance-metric](https://docs.vespa.ai/en/reference/schema-reference.html#distance-metric), 
restricting the search for neighbors to only consider documents tagged with *rock*:

<pre>
select * from track where {targetHits:5, approximate:false}nearestNeighbor(embedding, query_embedding) and tags:rock 
</pre>

The query execution planner estimates that the exact `nearestNeighbor` query operator 
will match all searchable documents, 
while the `tags` term will match a restricted subset. 
The most optimal way to evaluate this query is to first find the documents matching the filter,
and then perform an exact nearest neighbor search. During the exact search, Vespa reads the vector data 
from the tensor attribute store and does not touch the `HNSW` graph.

<img src="/assets/2022-05-09-constrained-approximate-nearest-neighbor-search/exact-scaling.png"/>
<em>**Figure 2** illustrates the computational cost (driven mainly by distance calculations) 
versus an increasing number of filter matches (% hit count rate) using exact search filters.
A more restrictive filter costs fewer resources as it involves fewer distance calculations. 

Note that the figure uses computational cost and not latency. 
It is possible to reduce search latency by using more threads to parallelize the exact search, 
but the number of distance calculations involved in the query execution stays the same.  
</em>

## Combining approximate nearest neighbor search with filters 

Using exact nearest neighbor search for web-scale search and recommendation problems 
quickly becomes prohibitively expensive. As a result, many turn to the less resource-intensive 
approximate nearest neighbor search, accepting an accuracy loss to reduce serving cost. 
There are two high-level strategies for combining boolean query evaluation over 
inverted indexes with approximate nearest neighbor search: *post-filtering* and *pre-filtering*. 

### Post-filtering strategy
This strategy evaluates the approximate nearest neighbors first and runs the constrained filter 
over those retrieved `targetHits` hits. This strategy is characterized as *post-filtering* as the 
filter constraints are considered only over the retrieved `targetHits` closest neighbors. 
The disadvantage of this approach is that restrictive filters (for example, the tag *90s* from Figure 1) 
will cause the search to expose fewer hits to ranking than the wanted `targetHits`. 
In the worst case, the post-filters eliminate all retrieved neighbors and expose zero documents to ranking. 
The advantage of this strategy is that the serving performance impact of constrained search is negligible 
compared to unconstrained approximate nearest neighbor search. 
Another aspect is that the hits which survive the post-filter are within the original `targetHits`.
In other words, the neighbors exposed to ranking are not distant compared to the *nearest*. 

### Pre-filtering strategy
This strategy evaluates the filter part of the query over the inverted index structures first. 
Then, it uses the resulting document IDs from the filter execution as input to the search for approximate nearest neighbors. 
The search for neighbors traverses the `HNSW` graph and each candidate neighbor is looked up in the 
document ID list from the filter execution.
Neighbors not on the document ID list are ignored and the greedy graph search continues until 
`targetHits` hits have been found.  

This filtering strategy is known as *pre-filtering*, as the filters go first before searching 
for the approximate nearest neighbors. With *pre-filtering*, the probability of exposing `targetHits` 
to the ranking phase is much higher than with the *post-filtering approach*. 
The disadvantage is that the performance impact is higher than with the post-filter strategy. 
In addition, the retrieved neighbors for a restrictive filter might be somewhat distant neighbors 
than the *nearest* neighbor of the query embedding. 
Distant neighbors could be combated by specifying a
[distance threshold](https://docs.vespa.ai/en/reference/query-language-reference.html#distancethreshold) 
as another constraint for the approximate `nearestNeighbor` query operator. 

<img src="/assets/2022-05-09-constrained-approximate-nearest-neighbor-search/ann-versus-pre-versus-post.png"/>
<em>**Figure 3** summarizes the strategies used for approximate nearest neighbor search with filtering. 
In the case of *post-filtering*, only one hit is exposed to the ranking phase after the post-filter is
evaluated. In the the case of *pre-filtering*, two additional hits were exposed, but they 
are more distant neighbors. 
</em>

### Filtering strategies and serving performance
From a performance and serving cost perspective, one can on a high level summarize the filtering strategies:

* Pure approximate nearest neighbor search without filters is the cheapest.  
* *Post-filtering* is less resource-intensive than pre-filtering for the same number of `targetHits`. 

*Pre-filtering* uses more resources than *post-filtering* as it needs to execute the 
filter and then search the `HNSW` graph, constrained by the document ID list produced by the pre-filter execution. 


<img src="/assets/2022-05-09-constrained-approximate-nearest-neighbor-search/pre-filter-approximate-threshold.png"/>
<em>**Figure 4** With the pre-filtering strategy, searching the `HNSW` graph with a restrictive pre-filter 
result (few hits) causes the greedy graph search to traverse many nodes before finding the `targetHits` 
which satisfies the document ID list from the pre-filter execution.  
Due to this, there is a sweet spot or threshold where an exact search with filters
has a lower computational cost than an approximate search using the document ID list from the pre-filter execution. 
The actual threshold value depends on vector dimensionality, `HNSW` graph properties, 
and the number of vectors in Vespa instance. 
</em>

## Controlling the filtering behavior with approximate nearest neighbor search 
Vespa exposes two parameters that control the filtering strategy. 
These parameters give the developer flexibility in choosing a method that fits 
the use case at hand best from a functional point of view, but also hedging performance and resource cost. 

The parameters are: 

* **post-filter-threshold** - default 1.0 
* **approximate-threshold** - default 0.05

These parameters were introduced in Vespa 7.854.xx, 
and can be configured in the rank profile, defined in the schema, 
or set in the query API per-query request. 

<img src="/assets/2022-05-09-constrained-approximate-nearest-neighbor-search/flowchart-small.png"/>
<em>**Figure 5** The flow chart shows how Vespa selects the 
strategy for an approximate nearest neighbor search with filters using mentioned parameters.</em>

* **Filter hit estimation**:
First, Vespa estimates the filter hit ratio of the query. 
The resulting *estimated-hit-ratio* is compared with the two parameters to select between *pre-filtering* or *post-filtering*.
* **Exact search with pre-filters**:
Vespa switches from approximate to exact search with pre-filters. 
* **ANN search using HNSW with post-filters**: 
Vespa searches for the `targetHits` approximate nearest neighbors using the `HNSW` graph. 
The retrieved hits are post-filtered. 
The default *post-filter-threshold* is 1.0, hence effectively disabling this decision branch by default. 
* **Pre-filter execution**:
Vespa executes the filter using the most compact posting list representations. 
The result of this execution is a list of document IDs matching the filter and an accurate hit ratio. 
The accurate hit ratio is used to choose between:
* **ANN search using HNSW with pre-filters**:
Vespa uses the list of document IDs matching the filter while searching the HNSW graph for the `targetHits` 
nearest neighbors, skipping all neighbors of the query vector that are not on the list.  
* **Exact search with pre-filters**:
Vespa switches from approximate to exact search with pre-filters. 

## Parameter Usage Guide   

This section guides on how to use the introduced parameters to achieve *pre-filtering*, *post-filtering*, or allowing Vespa 
to choose the strategy dynamically based on the filter hit count ratio estimates.  

### Pre-filtering with exact search fallback
Pre-filtering is the default evaluation strategy, and this example shows the default settings. 
This combination will never consider *post-filtering*, only *pre-filtering*. 
Developers can tune the `approximate-threshold` to optimize serving performance. 
<pre>
rank-profile pre-filtering-with-fallback {
  post-filter-threshold: 1.0
  approximate-threshold: 0.05
}
</pre>

### Post-filtering with exact search fallback
The following example uses *post-filtering* as a rule and *pre-filtering* is effectively disabled. 
This strategy will always search the `HNSW` graph unconstrained, unless the `estimated-hit-ratio` 
is less than 5%. Falling back to the exact search for estimated restrictive filters could be 
considered a way to improve functionality as exact search will guarantee to expose `targetHits` to ranking
as long as the filter matches more than one document. 

<pre>
rank-profile post-filtering-with-fallback {
  post-filter-threshold: 0.0
  approximate-threshold: 0.05
}
</pre>

### Hybrid - Allow Vespa to chose between pre and post-filtering
The previous examples set extreme values for *post-filter-threshold*, either disabling or enabling it. 

The following combination allows Vespa to choose the strategy 
dynamically based on the `estimated-hit-ratio* estimate`.  

<pre>
rank-profile hybrid-filtering {
    post-filter-threshold: 0.75
    approximate-threshold: 0.05
}
</pre>
This parameter combination will trigger post-filtering for relaxed filters, 
estimated to match more than 75% of the documents. 
Moderate filters (between 5% and 75%) are evaluated using `pre-filtering` 
and restrictive filters (&lt; 5%) are evaluated using exact search.  

## Summary
This blog post described Vespa's support for combining approximate nearest 
neighbor search with query time constraints or filters.
It covered on a high level the data structures that Vespa builds to 
support classic sparse retrieval and also the graph data structures 
for fast, approximate, nearest neighbor search. The post took a deep dive into 
the topic of how filters can be combined with vector search. 

Finally, the post introduced two newly introduced parameters for controlling 
the filtering behavior and how developers can tune these, 
choosing between *pre-filtering* or *post-filtering* for an 
optimal tradeoff between serving performance and functionality.  


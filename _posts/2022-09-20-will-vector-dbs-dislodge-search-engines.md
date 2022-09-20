---
layout: post
title: "Will new vector databases dislodge traditional search engines?"
author: jobergum
date: '2022-09-19'
image: assets/2022-09-20-will-vector-dbs-dislodge-search-engines/joshua-sortino-LqKhnDzSF-8-unsplash.jpg
skipimage: true
tags: []
excerpt: Doug Turnbull asks an interesting question on Linkedin; Will new vector databases dislodge traditional search engines?
---


Doug Turnbull asks [an interesting question on Linkedin](https://www.linkedin.com/posts/softwaredoug_will-new-vector-databases-dislodge-traditional-activity-6975451508918079488-2n_j?utm_source=share&utm_medium=member_desktop); _Will new vector databases dislodge traditional search engines?_

<img src="/assets/2022-09-20-will-vector-dbs-dislodge-search-engines/joshua-sortino-LqKhnDzSF-8-unsplash.jpg"/>
<p class="image-credit">
Photo by <a href="https://unsplash.com/@sortino">
Joshua Sortino</a> on <a href="https://unsplash.com/collections/25900015/abstract-%2F-tech">Unsplash</a>
</p>

The short answer is **no**, but it depends on what you classify as a traditional search engine.

Features like phrase search, exact search, [BM25](https://en.wikipedia.org/wiki/Okapi_BM25) ranking, dynamic summaries, and result facets are features we take for granted in a search engine implementation. Most vector databases lack these features. Apache Lucene and [Vespa](https://vespa.ai/) have 20 years of development, adding search critical features. 
Accelerated dynamic pruning algorithms like [wand](https://docs.vespa.ai/en/using-wand-with-vespa.html) and [BM-wand](https://www.elastic.co/blog/faster-retrieval-of-top-hits-in-elasticsearch-with-block-max-wand) over [inverted indexes](https://en.wikipedia.org/wiki/Inverted_index) also come to mind.

Major web search engines use [semantic vector search](https://twitter.com/jobergum/status/1484094284022398978) for candidate retrieval but still allow users to [perform an exact phrase search](https://blog.google/products/search/how-were-improving-search-results-when-you-use-quotes/). 
For example, a user searching for an article number, a phone number, or an ISSN are examples of search use cases that dense vector similarity computations cannot solve.

Real-world search ranking implementations include real-time signals like item stock availability, popularity, or other ranking business constraints. Unfortunately, these signals are hard to compress into a simple vector similarity calculation.

## The future of search is hybrid
A successful search implementation uses hybrid retrieval techniques, combining the best of both types of representations; sparse and dense vectors. The hybrid model is demonstrably better than the sum of its parts, especially when applied to new domains without lots of interaction data to train vector embedding models that map data to vectors.

<iframe width="560" height="315" src="https://www.youtube.com/embed/R5BLbnXPR5c" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

The critical observation is that search implementations must support exact matches and richer ranking than vector similarity alone. Given this, I believe integrating excellent dense vector search capabilities into feature-rich search engine technologies is the right direction.

## However, not all search engines are alike.

Not all search engine architectures can add efficient dense vector search capabilities without significantly impacting latency, storage, and serving costs.

For example, search engines built on the [Apache Lucene](https://lucene.apache.org/) 
library face severe challenges when exposing the recently added approximate nearest neighbor search support using HNSW graphs. 
Apache Lucene achieves near real-time indexing by creating [multiple immutable segments](https://blog.mikemccandless.com/2011/02/visualizing-lucenes-segment-merges.html). One new segment per refresh interval. How many are active in total depends on the number of shards, indexing rate, refresh interval settings, and segment merge policies.

A vector search in Elasticsearch, Apache Solr, or OpenSearch, using Lucene,  needs to scan all these active segments per shard, causing unpredictable latency and recall. Furthermore, the query cost, driven by vector distance calculations, increases almost linearly with the number of active segments since there is one graph per Lucene index segment.

But, can immutable segments with HNSW graphs be efficiently merged into fewer and larger segments to solve this search scalability problem?

Unfortunately not, HNSW graph data structures are inherently different from the classic inverted index data structures. Apache Lucene based its immutable segment architecture on sorted inverted index structures in 1998. Due to the sorted property, merging sorted posting lists was simple and cost-efficient. [HNSW graphs for high-recall vector search, on the other hand, are immensely expensive to merge](https://github.com/apache/lucene/issues/11354), effectively costing the same amount of compute as building a single HNSW graph from scratch.

## The solution?
So what is the alternative if you want all the features of a traditional search engine but also want to incorporate dense vector search in your search use cases?

Luckily, [Vespa](https://vespa.ai/), the [open-source big data serving engine](https://github.com/vespa-engine/vespa/), is an alternative to Apache Lucene-based engines. Vespa implements a mutable HNSW graph per node adjacent to other mutable data structures for efficient retrieval and ranking.

Users of Vespa can effortlessly [combine vector search with traditional search engine query operators](https://blog.vespa.ai/constrained-approximate-nearest-neighbor-search/), implementing [hybrid search](https://docs.vespa.ai/en/nearest-neighbor-search-guide.html) at [scale](https://blog.vespa.ai/vespa-hybrid-billion-scale-vector-search/).

Vespa’s core data structures are [mutable](https://youtu.be/vFu5g44-VaY), avoiding expensive merging and duplication. Vespa indexing latency is in milliseconds, not seconds. [Updating a single field](https://docs.vespa.ai/en/partial-updates.html) does not require a full re-indexing as in engines built on immutable data structures. For example, updating the popularity does not require reindexing the vector data like in engines built on Apache Lucene.

Critical features such as [phrase search](https://docs.vespa.ai/en/reference/query-language-reference.html#phrase), exact search, [BM25](https://docs.vespa.ai/en/reference/bm25.html), [proximity](https://docs.vespa.ai/en/reference/nativerank.html#nativeProximity) features, and [result grouping](https://docs.vespa.ai/en/grouping) comes for free. In addition to performance, scalability, and reliability, Vespa has [proven ranking results](https://blog.vespa.ai/pretrained-transformer-language-models-for-search-part-4/) on the world’s [most extensive open relevancy dataset](https://microsoft.github.io/msmarco/). 
Not anecdotes in a sales presentation, but proven ranking results,
[available to anyone to reproduce](https://github.com/vespa-engine/sample-apps/blob/master/msmarco-ranking/passage-ranking-README.md).

If you are interested in learning more about Vespa and how organizations like [Spotify are using Vespa](https://engineering.atspotify.com/2022/03/introducing-natural-language-search-for-podcast-episodes/) to unlock the full potential of hybrid search and neural ranking, check out the [Vespa Blog](https://blog.vespa.ai/) or get started with one of many [Vespa sample applications](https://github.com/vespa-engine/sample-apps). All the sample applications can either be deployed on-premise on your infrastructure or [using Vespa Cloud](https://cloud.vespa.ai/).

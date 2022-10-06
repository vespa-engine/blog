---
layout: post
title: Efficient personal search at large scale
date: '2019-01-21T16:01:07-08:00'
tags:
- database
- search
- big data
- search engines
tumblr_url: https://blog.vespa.ai/post/182190889026/efficient-personal-search-at-large-scale
---
**[Vespa](https://vespa.ai/) includes a relatively unknown mode which provides personal search at massive scale for a fraction of the cost of alternatives: streaming search. In this article we explain streaming search and how to use it.**

Imagine you are tasked with building the next Gmail, a massive personal data store centered around search. How do you do it? An obvious answer is to just use a regular search engine, write all documents to a big index and simply restrict queries to match documents belonging to a single user.

This works, but the problem is cost. Successful personal data stores has a tendency to become _massive_ — the amount of personal data produced in the world outweighs public data by many orders of magnitude. Storing indexes in addition to raw data means paying for extra disk space for all this data and paying for the overhead of updating this massive index each time a user changes or adds data. Index updates are costly, especially when they need to be handled in real time, which users often expect for their own data. Systems like Gmail handle billions of writes per day so this quickly becomes the dominating cost of the entire system.

However, when you think about it there’s really no need to go through the trouble of maintaining global indexes when each user only searches her own data. What if we just maintain a separate small index per user? This makes both index updates and queries cheaper, but leads to a new problem: Writes will arrive randomly over all users, which means we’ll need to read and write a user’s index on every update without help from caching. A billion writes per day translates to about 25k read-and write operations per second peak. Handling traffic at that scale either means using a few thousand spinning disks, or storing all data on SSD’s. Both options are expensive.

Large scale data stores already solve this problem for appending writes, by using some variant of multilevel log storage. Could we leverage this to layer the index on top of a data store like that? That helps, but means we need to do our own development to put these systems together in a way that performs at scale every time for both queries and writes. And we still pay the cost of storing the indexes in addition to the raw user data.

Do we need indexes at all though? With some reflection, it turns out that we don’t. Indexes consists of pointers from words/tokens to the documents containing them. This allows us to find those documents faster than would be possible if we had to read the content of the documents to find the right ones, of course at the considerable cost of maintaining those indexes. In personal search however, any query only accesses a small subset of the data, and the subsets are know in advance. If we take care to store the data of each subset together we can achieve search with low latency by simply reading the data at query time — what we call _streaming search_. In most cases, most subsets of data (i.e most users) are so small that this can be done serially on a single node. Subsets of data that are too large to stream quickly on a single node can be split over multiple nodes streaming in parallel.

## Numbers

How many documents can be searched per node per second with this solution? Assuming a node with 500 Mb/sec read speed (either from an SSD or multiple spinning disks), and 1k average compressed document size, the disk can search max 500Mb/sec / 1k/doc = 500,000 docs/sec. If each user store 1000 documents each on average this gives a max throughput per node of 500 queries/second. This is not an exact computation since we disregard time used to seek and write, and inefficiency from reading non-compacted data on one hand, and assume an overly pessimistic zero effect from caching on the other, but it is a good indication that our solution is cost effective.

What about latency? From the calculation above we see that the latency from finding the matching documents will be 2 ms on average. However, we usually care more about the 99% latency (or similar). This will be driven by large users which needs to be split among multiple nodes streaming in parallel. The max data size per node is then a tradeoff between latency for such users and the overall cost of executing their queries (less nodes per query is cheaper). For example, we can choose to store max 50.000 documents per user per node such that we get a max latency of 100 ms per query. Lastly, the total number of nodes decides the max parallelism and hence latency for the very largest users. For example, with 20 nodes in total a cluster we can support 20 \* 50k = 1 million documents for a single user with 100 ms latency.

## Streaming search

All right — with this we have our cost-effective solution to implement the next Gmail: Store just the raw data of users, in a log-level store. Locate the data of each user on a single node in the system for locality (or, really 2–3 nodes for redundancy), but split over multiple nodes for users that grow large. Implement a fully functional search and relevance engine on top of the raw data store, which distributes queries to the right set of nodes for each user and merges the results. This will be cheap and efficient, but it sounds like a lot of work! It sure would be nice if somebody already did all of it, ran it at large scale for years and then released it as open source.

Well, as luck would have it we already did this in [Vespa](https://vespa.ai/). In addition to the standard _indexing_ mode, Vespa includes a _streaming_ mode for documents which provides this solution, implemented by layering the full search engine functionality over the raw data store built into Vespa. When this solution is compared to indexed search in Vespa or more complicated sharding solutions in Elastic Search for personal search applications, we typically see about an order of magnitude reduction in cost of achieving a system which can sustain the query and update rates needed by the application with stable latencies over long time periods. It has been used to implement various applications such as storing and searching massive amounts of mails, personal typeahead suggestions, personal image collections, and private forum group content.

## Using streaming search on Vespa

The steps to using streaming search on [Vespa](https://vespa.ai/) are:

- Set [_streaming mode_](https://docs.vespa.ai/en/reference/services-content.html#document) for the document type(s) in question in services.xml.
- Write documents with a group name (e.g a user id) in their id, by setting g=[groupid] in the third part of the [document id](https://docs.vespa.ai/en/reference/services-content.html#document), as in e.g id:mynamespace:mydocumenttype:g=user123:doc123
- Pass the group id in queries by setting the query property [streaming.groupname](https://docs.vespa.ai/en/streaming-search.html#streaming.groupname) in queries.

That’s it! With those steps you have created a scalable, battle-proven personal search solution which is an order of magnitude cheaper than any alternative out there, with full support for [structured and text search](https://docs.vespa.ai/en/query-language.html), [advanced relevance including natural language and machine-learned models](https://docs.vespa.ai/en/ranking.html), and powerful [grouping and aggregation](https://docs.vespa.ai/en/grouping.html) for features like faceting. For more details see the [documentation on streaming search](https://docs.vespa.ai/en/streaming-search.html). Have fun with it, and as usual let us know what you are building!


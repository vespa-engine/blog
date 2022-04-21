---
layout: post
title: Vespa Newsletter, April 2022
author: kkraune
date: '2022-04-21'
categories: [newsletter]
image: assets/images/ilya-pavlov-OqtafYT5kTw-unsplash.jpg
skipimage: true
tags: [big data serving, big data, search engines, search, database]
index: false
excerpt: >
    Advances in Vespa features and performance include tensor and ranking configuration improvements,
    pyvespa usability features and grouping configuration.
    Also find new guides for performance and ANN. And a podcast!
    
---

In the [previous update]({% post_url /newsletter/2022-01-31-vespa-newsletter-january-2022 %}),
we mentioned faster node recovery and re-balancing, reindexing speed, WeakAnd, synonyms and language detection.
Today, we’re excited to share the following updates:


#### In the news
In [Dimitry Khan](https://twitter.com/DmitryKan)’s
[Vector Podcast](https://open.spotify.com/show/13JO3vhMf7nAqcpvlIgOY6),
enjoy [Jo Kristian Bergum](https://twitter.com/jobergum) from the Vespa Team in the
[Journey of Vespa from Sparse into Neural Search](https://open.spotify.com/episode/5eiywuzKrRRcd1EaUp4ZMo).
This is a great 90 minutes of Vespa, vector search, multi-stage ranking and approximate nearest neighbor, and more!

#### Compact tensor format
Vespa now supports short form parsing for unbound dense (e.g. `tensor(d0[],d1[])`),
and partially unbound (e.g. `tensor(d0[],d1[128]`).
Available since Vespa 7.459.15.
Refer to [document-json-format.html#tensor](https://docs.vespa.ai/en/reference/document-json-format.html#tensor) and
[presentation.format.tensors](https://docs.vespa.ai/en/reference/query-api-reference.html#presentation.format.tensors).

#### Modular rank profiles
A [rank-profile](https://docs.vespa.ai/en/reference/schema-reference.html#rank-profile)
is a named set of ranking expression functions and -settings which can be selected in the query.
Complex applications typically have multiple schemas and rank profiles.
Now, multiple inheritance of rank profiles and support for defining profiles in separate files
is supported from Vespa 7.538.

#### Grouping
[Result Grouping](https://docs.vespa.ai/en/grouping.html) is used to aggregate data in fields in query hits,
to implement use cases like number of items per category, inventory check, maximum values per category, etc.
As the aggregation functions possibly spans the full corpus, temporary memory usage can be a problem for some queries.
Use the new configuration parameters
[defaultMaxGroups](https://docs.vespa.ai/en/reference/query-api-reference.html#grouping.defaultMaxGroups),
[defaultMaxHits](https://docs.vespa.ai/en/reference/query-api-reference.html#grouping.defaultMaxHits) and 
[globalMaxGroups](https://docs.vespa.ai/en/reference/query-api-reference.html#grouping.globalMaxGroups)
to control grouping result set sizes.

#### pyvespa
[pyvespa](https://pyvespa.readthedocs.io/) is Vespa’s simplified python bindings for query and ranking experiments.
With pyvespa 0.16.0, it is possible to specify the
[Docker image](https://pyvespa.readthedocs.io/en/latest/reference-api.html#vespadocker) -
use this for M1 testing, ref [pyvespa#231](https://github.com/vespa-engine/pyvespa/issues/231).
With pyvespa 0.17.0, one can deploy to Docker using POST, without using a disk mount -
see [pyvespa#296](https://github.com/vespa-engine/pyvespa/issues/296).

#### New query guides
Vespa has unmatched query performance for (approximate) nearest neighbor search
with filters and real-time update-able fields.
It can however be a challenge to balance the cost/performance tradeoffs to get the configuration optimal.
The new guides [practical search performance](https://docs.vespa.ai/en/performance/practical-search-performance-guide.html)
and [nearest neighbor search](https://docs.vespa.ai/en/nearest-neighbor-search-guide.html) are great resources,
exploring multithreaded queries, use of embeddings, HNSW configuration and multivalue query operators and more -
including advanced query tracing.

#### Get ready for Vespa 8
Vespa uses [semantic versioning](https://vespa.ai/releases) and releases new features continuously on _minor_ versions.
_Major_ version changes are used to mark versions which break compatibility,
by removing previously deprecated features, changing default values and similar.
The next time this happens will be in June, when we release Vespa 8. 
Review the [release notes](https://docs.vespa.ai/en/vespa8-release-notes.html) to make sure your applications
are compatible with Vespa 8.

---
layout: post
title: Vespa Newsletter, January 2022
author: kkraune
date: '2022-01-31'
categories: [newsletter]
image: assets/images/scott-graham-5fNmWej4tAA-unsplash.jpg
skipimage: true
tags: [big data serving, big data, search engines, search, database]
index: false
excerpt: >
    Advances in Vespa features, performance and operability improvements include:
    Improved synonym support, faster node recovery, re-balancing and re-indexing,
    WeakAnd query type and new pyvespa features and sample applications.
    
---

In the [previous update]({% post_url /newsletter/2021-12-22-vespa-newsletter-december-2021 %}),
we mentioned Tensor performance improvements, Match features and the Vespa IntelliJ plugin.
Today, we’re excited to share the following updates:


#### Faster node recovery and re-balancing
When Vespa content nodes are added or removed,
data is [auto-migrated between nodes](https://docs.vespa.ai/en/elastic-vespa.html)
to maintain the configured data distribution.
The throughput of this migration is throttled to avoid impact to regular query and write traffic.
We have worked to improve this throughput by using available resources better,
and since November we have been able to approximately double it -
read the [blog post]({% post_url /2022-01-19-doubling-the-throughput-of-data-redistribution %}).

#### Reindexing speed
Most schema changes in Vespa are effected immediately,
but some require [re-indexing](https://docs.vespa.ai/en/operations/reindexing.html).
Reindexing the corpus can take time, and consumes resources.
It is now possible to configure how fast to re-index in order to balance this tradeoff,
see [reindex speed](https://docs.vespa.ai/en/cloudconfig/deploy-rest-api-v2.html#reindex).
Read more about [schema changes](https://docs.vespa.ai/en/reference/schema-reference.html#modifying-schemas).

#### pyvespa
pyvespa 0.14.0 is released with the following changes:
* Add retry strategy to delete_data,
  get_data and update_data ([#222](https://github.com/vespa-engine/pyvespa/pull/222)).
* Deployment parameter disk_folder defaults to the current working directory for both Docker and Cloud deployments
  ([#225](https://github.com/vespa-engine/pyvespa/pull/225)).
* Vespa connection now accepts cert and key as separate arguments.
  Using both certificate and key values in the cert file continue to work as before
  ([#226](https://github.com/vespa-engine/pyvespa/pull/226)).

Explore the new [text-image](https://github.com/vespa-engine/sample-apps/tree/master/text-image-search/src/python)
and [text-video](https://github.com/vespa-engine/sample-apps/tree/master/text-video-search) sample applications with pyvespa,
and read more about [pyvespa](https://pyvespa.readthedocs.io/en/latest/index.html).

#### Improved support for Weak And and unstructured user input
You can now use `type=weakAnd` in the [Query API](https://docs.vespa.ai/en/reference/query-api-reference.html#model.type).
Used with [userInput](https://docs.vespa.ai/en/reference/query-language-reference.html#userinput),
it is easy to create a query using [weakAnd](https://docs.vespa.ai/en/using-wand-with-vespa.html#weakand)
with unstructured input data in a query, for a better relevance / performance tradeoff compared to all / any queries.

#### Synonyms
Semantic Rules have added better support for making synonym expansion rules through the * operator,
see [#20386](https://github.com/vespa-engine/vespa/issues/20386),
and proper stemming in multiple languages,
see [Semantic Rules directives](https://docs.vespa.ai/en/reference/semantic-rules.html#directives).
Read more about [query rewriting](https://docs.vespa.ai/en/query-rewriting.html).

#### Language detection
If no language is explicitly set in a document or a query, and stemming/nlp tokenization is used,
Vespa will run a language detector on the available text.
Since Vespa 7.518.53, the default has changed from Optimaize to OpenNLP.
[Read more](https://docs.vespa.ai/en/linguistics.html#language-handling).

#### New blog posts
* [ML model serving at scale]({% post_url /2022-01-07-ml-model-serving-at-scale %})
  is about model serving latency and concurrency,
  and is a great primer on inference threads, intra-operation threads and inter-operation threads.
* [Billion-scale knn part two]({% post_url /2022-01-27-billion-scale-knn-part-two %})
  goes in detail on tensor vector precision types, memory usage, precision and performance
  for both nearest neighbor and approximate nearest neighbor search.
  Also learn how HNSW works with number of links in the graph and neighbors to explore at insert time,
  and how this affects precision.

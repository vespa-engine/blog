---
layout: post
title: Vespa Newsletter, December 2023
author: kkraune
date: '2023-12-18'
categories: [newsletter]
image: assets/images/scott-graham-5fNmWej4tAA-unsplash.jpg
image_credit: 'Photo by <a href="https://unsplash.com/@homajob?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Scott Graham</a> on <a href="https://unsplash.com/photos/5fNmWej4tAA?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>'
skipimage: true
tags: [big data serving, big data, search engines, search, database]
index: false
excerpt: >
    Advances in Vespa features and performance include rank score normalization in the global ranking phase,
    improved feeding using PyVespa, token authentication, and query match debugging!
---


It’s December, and still time to complete the [Advent of Tensors](https://blog.vespa.ai/advent-of-tensors-2023/) challenge!
This is a great way to get into tensors, how to use them - and be in the race to win Vespa swag!

<img src="/assets/2023-12-01-advent-of-tensors-2023/andreer_vespa_99582_a_cartoon_santa_doing_mathematics_with_rein_abcc3133-6019-41c1-88c7-15bf48652252.png"
     alt="advent-of-tensors image" width="300px" height="auto">

### 2023 Vespa Open Source Survey
It’s been a great year both for search/recommendation as an industry, but also for Vespa!
You are using Vespa in so many innovative ways we did not think of, which is awesome!
To help us improve the feature set and hopefully remove some pain points,
we kindly ask you to spend a few minutes on the
[2023 Vespa Open Source Survey](https://docs.google.com/forms/d/e/1FAIpQLSePvzM2GcQ2N1a45AsbsUwnYpRakIyf6_q0QCYVZwvGmJXpcA/viewform?usp=sf_link).
Thanks in advance!


----

In the [previous update]({% post_url /newsletter/2023-10-31-vespa-newsletter-october-2023 %}),
we mentioned Vespa Cloud Enclave, Lucene Linguistics integration, faster fuzzy matching,
cluster-specific model-serving settings, and automated BM25 reconfiguration.
Today, we’re excited to share the following updates:


### Global-phase cross-hit normalization
Vespa provides two-phase ranking which lets you rerank hits using a ranking function
that is too expensive to evaluate for all matches.
Both these phases are executed locally on content nodes.

In 8.246 we introduced a third ranking phase - global-phase, which is executed on container nodes.
As this operates on the global list of hits after merging all content nodes,
it makes it possible to evaluate normalizing functions that need access to the global top list of hits.
You can now add _global-phase_ to your rank profile to evaluate any ranking function on container nodes,
and here you also have access to the new normalizing functions
_normalize_linear_, _reciprocal_rank_ and _reciprocal_rank_fusion_.
For example, use _normalize_linear_ to normalize scores into a [0,1] range:

```
global-phase {
    expression {
        normalize_linear(my_bm25_sum) +
        normalize_linear(my_model_out) +
        normalize_linear(attribute(popularity))
    }
}
```

With this, it is easier to control each factor so it does not dominate too much - e.g., _bm25_ has an unbounded range.

_reciprocal_rank_ is a useful function where the order of hits is relevant, but not necessarily the rank scores.
Think of it as another normalization function with a [0,1] range, where only the rank information is preserved.
Read more in [cross-hit normalization including reciprocal rank fusion](https://docs.vespa.ai/en/phased-ranking.html#cross-hit-normalization-including-reciprocal-rank-fusion),
and the blog post using [reciprocal_rank_fusion](https://blog.vespa.ai/scaling-personal-ai-assistants-with-streaming-mode/).


### New features in Pyvespa
Pyvespa has a new API for feeding collections of data, with better performance -
see _feed_iterable_ in [0.38](https://github.com/vespa-engine/pyvespa/releases/tag/v0.38.0) and
[0.39](https://github.com/vespa-engine/pyvespa/releases/tag/v0.39.0) -
[example use](https://pyvespa.readthedocs.io/en/latest/examples/scaling-personal-ai-assistants-with-streaming-mode-cloud.html).
Please note that the previous batch feed functions were deprecated and subsequently removed from pyvespa.

New features also include support for [global-phase](https://docs.vespa.ai/en/phased-ranking.html#global-phase)
ranking expressions and support for using [streaming](https://docs.vespa.ai/en/streaming-search.html) mode.

Special thanks to [maxice8](https://github.com/maxice8) for adding support for configuring an alias
for fields in [#633](https://github.com/vespa-engine/pyvespa/pull/633)!


### Token Authentication for Data Plane Access
Vespa and Vespa Cloud support mTLS for security.
Since November, we have added support for data plane Token Authentication in Vespa Cloud -
see the [announcement](https://blog.vespa.ai/announce-tokens-and-anonymous-endpoints/).
You can use this to get API access without using certificates:

    $ curl -H "Authorization: Bearer vespa_cloud_...." \
      https://ed82e42a.eeafe078.z.vespa-app.cloud/


### More new features
* You can now download the active application package using _vespa fetch_ -
  see the [cheat sheet](https://docs.vespa.ai/en/vespa-cli.html#deployment).
  This makes it easier to get the active configuration to replicate application instances.
* [unpack_bits(t)](https://docs.vespa.ai/en/reference/ranking-expressions.html#unpack-bits)
  is a new function on ranking which unpacks bits from int8 input to 8 times as many floats.
  The innermost indexed dimension will expand to have 8 times as many cells,
  each with a float value of either 0.0 or 1.0 determined by one bit in the 8-bit input value.
  This function is comparable to _numpy.unpackbits_, which gives the same basic functionality.
  Since Vespa 8.256.
* You can now get the [tokens](https://docs.vespa.ai/en/reference/schema-reference.html#tokens)
  indexed by Vespa returned with a query.
  This is helpful for debugging linguistics transformations,
  see this [example](https://docs.vespa.ai/en/text-matching.html#tokens-example).
  Since Vespa 8.243.


### Blog posts since last newsletter
* [Announcing our series A funding](https://blog.vespa.ai/announcing-our-series-a-funding/)
* [Yahoo Mail turns to Vespa to do RAG at scale](https://blog.vespa.ai/yahoo-mail-turns-to-vespa-to-do-rag-at-scale/)
* [Anonymized endpoints and token authentication in Vespa Cloud](https://blog.vespa.ai/announce-tokens-and-anonymous-endpoints/)
* [Changes in OS support for Vespa](https://blog.vespa.ai/Changes-in-OS-support-for-Vespa/)
* [Hands-On RAG guide for personal data with Vespa and LLamaIndex](https://blog.vespa.ai/scaling-personal-ai-assistants-with-streaming-mode/)
* [Advent of Tensors 2023 🎅](https://blog.vespa.ai/advent-of-tensors-2023/)
* [A new visual identity for a new era](https://blog.vespa.ai/a-new-visual-identity-for-a-new-era/)
* [Turbocharge RAG with LangChain and Vespa Streaming Mode for Sharded Data](https://blog.vespa.ai/turbocharge-rag-with-langchain-and-vespa-streaming-mode/)

----

Thanks for reading! Try out Vespa by
[deploying an application for free to Vespa Cloud](https://cloud.vespa.ai/en/getting-started)
or [install and run it yourself](https://docs.vespa.ai/en/vespa-quick-start.html).

---
layout: post
title: Vespa Newsletter, February 2024
author: kkraune
date: '2024-02-15'
categories: [newsletter]
image: assets/images/ilya-pavlov-OqtafYT5kTw-unsplash.jpg
image_credit: 'Photo by <a href="https://unsplash.com/pt-br/@ilyapavlov?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Ilya Pavlov</a> on <a href="https://unsplash.com/photos/OqtafYT5kTw?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>'
skipimage: true
tags: []
index: false
excerpt: >
    Advances in Vespa features and performance include the YQL IN operator,
    new streaming search features, and embed using parameter substitution.
---


In the [previous update]({% post_url /newsletter/2023-12-18-vespa-newsletter-december-2023 %}),
we mentioned rank score normalization in the global ranking phase, improved feeding using PyVespa,
token authentication, and query match debugging.
Today, we’re excited to share the following updates:


### GigaOm Sonar for Vector Databases Positions Vespa as a Leader
Although we're more than a vector database, we're happy to be recognized as a leader in this category.
See the press release [here](https://www.businesswire.com/news/home/20240213670564/en/GigaOm-Sonar-for-Vector-Databases-Positions-Vespa-as-a-Leader-and-Forward-Mover)
and access the full report [here](https://content.vespa.ai/gigaom-report-2024), courtesy of Vespa.


### A native ColBERT embedder in Vespa
ColBERT embeddings allows you to achieve state-or-the-art ranking, while also providing
explainability through syntax highlighting like with lexical search. With the new ColBERT
embedder in Vespa you can use ColBERT out of the box. [Read more](https://blog.vespa.ai/announcing-colbert-embedder-in-vespa/).


### YQL IN operator
Using sets in queries is useful to express "find any of" without a massive "a OR b OR c OR ...".
The negation is also useful, e.g to exclude documents in the result set,
e.g. do not show users results that are previously returned, using the NOT operator.

In Vespa you can use the `weightedSet` query item to express this.
Many Vespa users have requested an IN operator in YQL instead, and this was released in 8.293.
Now you can write queries like:

    select id, name from product where id in (10, 20, 30)

Or the inverse, to exclude items from the result:

    select id, name from product where !(id in (10, 20, 30))

A pro-tip is using parameter substitution to speed up the YQL-parsing even more:

    select id, name from product where id in (@my_set)&my_set=10,20,30

This also simplifies integration with the query interface.
Read more in [multi-lookup-set-filtering](https://docs.vespa.ai/en/performance/feature-tuning.html#multi-lookup-set-filtering).
As an added bonus, performance for such queries is improved, too!
See the [blog post](https://blog.vespa.ai/announcing-in-query-operator/) to learn more.


### Streaming search: fuzzy and regexp matching
Vespa in indexed mode supports both [regexp](https://docs.vespa.ai/en/text-matching.html#regular-expression-match)
and [fuzzy](https://docs.vespa.ai/en/text-matching.html#fuzzy-match) matching.
Since 8.290, regexp and fuzzy searches are also supported in 
[streaming mode](https://docs.vespa.ai/en/streaming-search.html) - examples:

    select * from music where ArtistAttribute matches "the week[e]*nd"

    select * from music where ArtistAttribute contains
        ({maxEditDistance: 1}fuzzy("the weekend"))

Performance generally differs between the indexing modes,
and both regex and fuzzy matches are slower than exact matching using indexes.
Streaming mode is optimized for writes and low resource usage, it does not use index structures.
Regexp and fuzzy matching are implemented without index structures, so a good fit for streaming search -
performance degradation is relatively smaller!

As a side note, fuzzy matching performance for indexed search was also greatly improved last October,
see the [announcement](https://blog.vespa.ai/vespa-newsletter-october-2023/).


### Embed with @Parameter substitution
Vespa makes it easy to create embeddings on the fly, both at write and query time, using the `embed` function.
With hybrid queries, the text to be searched must be input to both lexical search and vector embedding, leading to duplication in the query.

Since Vespa 8.287, one can use parameter substitution to simplify.
Add the user input <span style="text-decoration: underline">once</span> in a request parameter,
and refer to this elsewhere in the expression - for example, using **@query**:
<pre>
$ vespa query 'yql=select id, from product where
    {targetHits:10}nearestNeighbor(embedding, query_embedding) or <strong>userInput(@query)</strong>' \
    'input.query(query_embedding)=embed(transformer, <strong>@query</strong>)' \
    '<strong>query=running shoes for kids, white</strong>'
</pre>
[Read more](https://docs.vespa.ai/en/query-api.html#parameter-substitution).


### Embedding an array of strings into multiple tokens
If you want to embed multiple chunks of data into a vector-per-token representation,
as in ColBERT, you can now do this using the built-in embed functionality in Vespa.
Just declare the receiving tensor field as a rank-3 tensor, such as 
<code>tensor(chunks{}, tokens{}, x[32])</code>
and embed with <code>embed colbert chunks</code>, see 
[this example](https://github.com/vespa-engine/system-test/blob/master/tests/search/embedding/app_colbert_multivector_embedder/schemas/doc.sd).
Available since 8.303.


### Vespa does hackathons
We are proud to sponsor hackathons at Stanford and Berkeley later this month!
Meet the Vespa Team at the sites on the following dates:
* [TreeHacks](https://treehacks.com/) - Stanford, Feb 16-18
* [Hack for Impact](https://hackforimpact.calblueprint.org/) - Berkeley, Feb 25


### New posts from our blog

You may have missed some of these new posts since the last newsletter:

* [When you're using vectors you're doing search](https://blog.vespa.ai/when-you-are-using-vectors-you-are-doing-search/)
* [Announcing the Vespa ColBERT embedder](https://blog.vespa.ai/announcing-colbert-embedder-in-vespa/)
* [GigaOm Sonar for Vector Databases Positions Vespa as a Leader](https://blog.vespa.ai/gigaom-sonar-for-vector-databases-positions-vespa-as-a-leader/)
* [Exploring the potential of OpenAI Matryoshka 🪆 embeddings with Vespa](https://blog.vespa.ai/matryoshka-embeddings-in-vespa/)
* [Announcing IN query operator](https://blog.vespa.ai/announcing-in-query-operator/)
* [Redefining hybrid search possibilities with vespa](https://blog.vespa.ai/redefining-hybrid-search-possibilities-with-vespa/)
* [Vespa Cloud enclave](https://blog.vespa.ai/vespa-cloud-enclave/)

----

Thanks for reading! Try out Vespa by
[deploying an application for free to Vespa Cloud](https://cloud.vespa.ai/en/getting-started)
.

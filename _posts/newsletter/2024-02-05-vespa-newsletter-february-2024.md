---
layout: post
title: Vespa Newsletter, February 2024
author: kkraune
date: '2024-02-05'
categories: [newsletter]
image: assets/images/ilya-pavlov-OqtafYT5kTw-unsplash.jpg
image_credit: 'Photo by <a href="https://unsplash.com/pt-br/@ilyapavlov?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Ilya Pavlov</a> on <a href="https://unsplash.com/photos/OqtafYT5kTw?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>'
skipimage: true
tags: [big data serving, big data, search engines, search, database]
index: false
excerpt: >
    Advances in Vespa features and performance include YQL IN operator,
    new streaming search features, and embed using parameter substitution.
---


In the [previous update]({% post_url /newsletter/2023-12-18-vespa-newsletter-december-2023 %}),
we mentioned rank score normalization in the global ranking phase, improved feeding using PyVespa,
token authentication, and query match debugging.
Today, we’re excited to share the following updates:


### Placeholder for press release
...


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

Also, fuzzy matching performance for indexed search was also greatly improved last October,
see the [announcement](https://blog.vespa.ai/vespa-newsletter-october-2023/).


### Embed with @Parameter substitution
Vespa makes it easy to create embeddings on the fly, both at write and query time, using the `embed` function.
End-user queries are used both for text matching and in embeddings, possibly making queries more complex than needed.

Since Vespa 8.287, one can use parameter substitution to simplify.
Add the user input <span style="text-decoration: underline">once</span> in a request parameter,
referring to this elsewhere in the expression - for example, using **@query**:
<pre>
$ vespa query 'yql=select id, from product where
    {targetHits:10}nearestNeighbor(embedding, query_embedding) or <strong>userQuery()</strong>' \
    'input.query(query_embedding)=embed(transformer, <strong>@query</strong>)' \
    'input.query(query_tokens)=embed(tokenizer, <strong>@query</strong>)' \
    '<strong>query=running shoes for kids, white</strong>'
</pre>
[Read more](https://docs.vespa.ai/en/query-api.html#parameter-substitution).


### Match-features
Use `match-features` to list rank feature scores to be included with each result hit - useful to analyze ranking.
Match-features are inherited in child rank profiles.
As match-features can be a lot of data,
one can since Vespa 8.290 disable match-feature output in child rank profiles using `match-features {}` in the schema.
[Read more](https://docs.vespa.ai/en/reference/schema-reference.html#match-features).


### Hackathons
We are proud to sponsor hackathons at Stanford and Berkeley later this month!
Meet the Vespa Team at the sites on the following dates:
* [TreeHacks](https://treehacks.com/) - Stanford, Feb 16-18
* [Hack for Impact](https://hackforimpact.calblueprint.org/) - Berkeley, Feb 25


### Blog posts since last newsletter
* [Announcing IN query operator](https://blog.vespa.ai/announcing-in-query-operator/)
* [Redefining hybrid search possibilities with vespa](https://blog.vespa.ai/redefining-hybrid-search-possibilities-with-vespa/)
* [Vespa Cloud enclave](https://blog.vespa.ai/vespa-cloud-enclave/)

----

Thanks for reading! Try out Vespa by
[deploying an application for free to Vespa Cloud](https://cloud.vespa.ai/en/getting-started)
or [install and run it yourself](https://docs.vespa.ai/en/vespa-quick-start.html).

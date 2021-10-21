---
layout: post
title: Vespa Product Updates, May 2021
author: kkraune
date: '2021-05-20'
categories: [product updates]
image: assets/images/ilya-pavlov-OqtafYT5kTw-unsplash.jpg
skipimage: true
tags: [big data serving, big data, search engines, search, database]
index: false
excerpt: >
    Advances in features and performance include new int8 and bfloat16 tensor cell types,
    compact tensor feed format, Approximate Nearest Neighbor using Hamming distance,
    hash-based attribute dictionaries and case-sensitive attribute search
    
---

In the [previous update]({% post_url /product-updates/2021-03-30-vespa-product-updates-march-2021 %}),
we mentioned document/v1/, weakAnd.replace, Improved feed-block at full node and Reduced memory at stop/restart.
Subscribe to the [mailing list](https://vespa.ai/mailing-list.html) to get these updates delivered to your inbox.

This month, we’re excited to share the following updates:


#### Bfloat16 and int8 tensor value types
Since Vespa-7.396.22, bfloat16 and int8 are supported as tensor cell types.
This enables model serving of larger models without increasing memory use,
or reducing cost by using lower precision types (e.g. 50% smaller with bfloat16 compared to 32 bit float).
Find details in the [value type reference](https://docs.vespa.ai/en/reference/tensor.html#tensor-type-spec)
and learn more about [performance considerations](https://docs.vespa.ai/en/tensor-user-guide.html#cell-value-types).
For int8, one can use a compact hex-form string field to write indexed tensors representing binary data,
see [JSON feed format](https://docs.vespa.ai/en/reference/document-json-format.html#tensor).


#### Case-sensitive attribute search
Search in string attributes is by default done in word match mode.
This means that the attribute’s value is stored unchanged,
and subsequent matching is done by on-the-fly lowercasing query terms / attribute data +
a few heuristics to filter out punctuation.
Some use cases require case sensitive matching, e.g. ID lookup,
and is enabled by using the cased match mode - available since Vespa-7.397.65.
[Read more](https://docs.vespa.ai/en/reference/schema-reference.html#match)


#### Attributes with hashed dictionary.
[Attributes](https://docs.vespa.ai/en/attributes.html) are in-memory fields,
in its simplest form stored in a table-like data structure.
By using [fast-search](https://docs.vespa.ai/en/attributes.html#fast-search),
one can speed up lookups by adding a dictionary, default a b-tree, to avoid a full table scan.
As of Vespa-7.397.65, a hash-based dictionary can be configured -
it is intended for use in fields with many unique terms with few occurrences (i.e. short postinglists),
where the dictionary lookup cost is significant.
Combine with cased match mode for best performance.
[Read more](https://docs.vespa.ai/en/reference/schema-reference.html#dictionary)


#### Hamming distance metric for ANN search
Since Vespa-7.401.18, a
[hamming distance metric](https://docs.vespa.ai/en/reference/schema-reference.html#distance-metric)
using `tensor<int8>` cell types is supported for Approximate Nearest Neighbor Search using Vespa’s 
[nearestNeighbor](https://docs.vespa.ai/en/reference/query-language-reference.html#nearestneighbor) query operator.
This distance metric is useful for computing edit distance between two sentences.


___
About Vespa: Largely developed by Yahoo engineers,
[Vespa](https://github.com/vespa-engine/vespa) is an open source big data processing and serving engine.
It’s in use by many products, such as Yahoo News, Yahoo Sports, Yahoo Finance, and the Yahoo Ad Platform.
Thanks to feedback and contributions from the community, Vespa continues to grow.

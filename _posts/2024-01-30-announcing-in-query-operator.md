---  
layout: post 
title: "Announcing IN query operator"
author: geirst
date: '2024-01-30'
image: assets/2024-01-30-announcing-in-query-operator/chuttersnap-9cCeS9Sg6nU-unsplash.jpg
image_credit: 'Photo by <a href="https://unsplash.com/@chuttersnap?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">CHUTTERSNAP</a> on <a href="https://unsplash.com/photos/birds-photo-of-cityscape-9cCeS9Sg6nU?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>'
skipimage: true 
tags: [] 
excerpt: "The new IN operator is a shorthand for multiple OR conditions, enabling writing more concise queries with better performance"
---

![Decorative
image](/assets/2024-01-30-announcing-in-query-operator/chuttersnap-9cCeS9Sg6nU-unsplash.jpg)
<p class="image-credit">Photo by <a href="https://unsplash.com/@chuttersnap?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">CHUTTERSNAP</a> on <a href="https://unsplash.com/photos/birds-photo-of-cityscape-9cCeS9Sg6nU?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
</p>

Today, we are pleased to announce a new query operator in Vespa.
The [IN](https://docs.vespa.ai/en/reference/query-language-reference.html#in)
operator is useful in various scenarios where we need to filter documents based on whether
a given field matches at least one of a set of values.
This is a shorthand for multiple OR conditions
that enables writing more concise queries with much better performance.


## Example

Consider a scenario where we want to retrieve product documents with specific IDs:
```
schema product {
    document product {
        field id type int {
            indexing: attribute | summary
            attribute: fast-search
            rank: filter
        }
        field name type string {
            indexing: attribute | summary
        }
        ...
    }
}
```

Instead of using multiple
[OR](https://docs.vespa.ai/en/reference/query-language-reference.html#or) conditions,
```
select id,name from product where id = 10 or id = 20 or id = 30
```

we simplify this by using the *IN* operator instead:
```
select id,name from product where id in (10, 20, 30)
```

In this case product documents with IDs 10, 20 or 30 are retrieved.
We can also retrieve documents that do not match any of these IDs by using the
[NOT](https://docs.vespa.ai/en/reference/query-language-reference.html#not) operator:

```
select id,name from product where !(id in (10, 20, 30))
```


## Performance
The [weightedSet](https://docs.vespa.ai/en/reference/query-language-reference.html#weightedset)
query operator has previously been used to solve similar filter use cases
the *IN* operator is tailored for.
However, *weightedSet* was mainly optimized for searching
[weightedset](https://docs.vespa.ai/en/reference/schema-reference.html#weightedset) attribute fields.
The *IN* operator however has been optimized for searching all supported types:
singlevalue and multivalue fields with basic type byte, int, long, or string.
The *weightedSet* operator also benefit from these optimizations,
as they share most of the low-level matching code.

The illustration below shows historic results from one test case in the
[IN operator performance test](https://github.com/vespa-engine/system-test/tree/master/tests/performance/in_operator).
It shows the average end-to-end latency when querying
a corpus with 10M documents using an *IN* operator over a
singlevalue integer attribute field with [fast-search](https://docs.vespa.ai/en/attributes.html#fast-search).
The queries return 1M documents, and the different graphs
use different amount of values in the operator: 1, 10, 100, 1000.
1 [thread per search](https://docs.vespa.ai/en/reference/schema-reference.html#num-threads-per-search)
is used on the content node.

The baseline performance is equal to the previous performance of the *weightedSet* operator.
After optimizations the performance when searching for many values has been greatly improved.
With 100 values the latency went from 150ms to 60ms, a 2.5x speedup.
With 1000 values the latency went from 1200ms to 95ms, a 12.5x speedup.
Note that similar improvements does not necessary apply when using the
*IN* operator in combination with other query filters.

![](/assets/2024-01-30-announcing-in-query-operator/in-operator-performance.png "image_tooltip")
<font size="3"><i>Historic latency graphs from IN operator performance test</i></font><br/>


## Summary
The new *IN* operator replaces the *weightedSet* operator for filtering use cases,
making it easy to write concise queries with much better performance than using multiple OR conditions.
The operator is supported for singlevalue and multivalue fields with basic type byte, int, long, or string.
See the [IN operator reference documentation](https://docs.vespa.ai/en/reference/query-language-reference.html#in)
for more details, and
[Multi lookup set filtering](https://docs.vespa.ai/en/performance/feature-tuning.html#multi-lookup-set-filtering)
for more examples. The new operator is available in Vespa 8.293.15.

Got questions? Join the Vespa community in [Vespa Slack](http://slack.vespa.ai/).


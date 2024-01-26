---  
layout: post 
title: "Announcing IN query operator"
author: geirst
date: '2024-01-29' 
image: assets/2024-01-29-announcing-in-query-operator/chuttersnap-9cCeS9Sg6nU-unsplash.jpg
image_credit: 'Photo by <a href="https://unsplash.com/@chuttersnap?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">CHUTTERSNAP</a> on <a href="https://unsplash.com/photos/birds-photo-of-cityscape-9cCeS9Sg6nU?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>'
skipimage: true 
tags: [] 
excerpt: "The new IN operator is a shorthand for multiple OR conditions, enabling writing more concise queries with better performance"
---

![Decorative
image](/assets/2024-01-29-announcing-in-query-operator/chuttersnap-9cCeS9Sg6nU-unsplash.jpg)
<p class="image-credit">Photo by <a href="https://unsplash.com/@chuttersnap?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">CHUTTERSNAP</a> on <a href="https://unsplash.com/photos/birds-photo-of-cityscape-9cCeS9Sg6nU?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
</p>

Today, we are pleased to announce a new query operator in Vespa.
The IN operator is useful in various scenarios where we need to filter documents based on whether
a given field matches at least one of a set of values.
This is a shorthand for multiple OR conditions
that enables writing more concise queries with much better performance.

Consider a scenario where we want to retrieve product documents with specific IDs:
```
schema product {
    document product {
        field id type long {
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

we simplify this by using the IN operator instead:
```
select id,name from product where id in (10, 20, 30)
```

In this case product documents with IDs 10, 20 or 30 are retrieved.
We can also retrieve documents that do not match any of these IDs by using the
[NOT](https://docs.vespa.ai/en/reference/query-language-reference.html#not) operator:

```
select id,name from product where !(id in (10, 20, 30))
```

The IN operator is supported for byte, int, long, and string fields, both singlevalue and multivalue.
See the [IN operator reference documentation](https://docs.vespa.ai/en/reference/query-language-reference.html#in) for more details,
and [Multi lookup set filtering](https://docs.vespa.ai/en/performance/feature-tuning.html#multi-lookup-set-filtering) for more examples.
The new operator is available in Vespa 8.293.15.

Got questions? Join the Vespa community in [Vespa Slack](http://slack.vespa.ai/).


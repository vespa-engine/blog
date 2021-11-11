---
layout: post
title: "Result diversification using Vespa result grouping"
date: '2021-11-11'
tags: []
author: jobergum 
image: assets/2021-11-11-result-diversification-with-vespa/robert-lukeman-_RBcxo9AU-U-unsplash.jpg
skipimage: true

excerpt: "This blog post dives into how to achieve result diversification using
Vespa's grouping framework."
---

![Decorative
image](/assets/2021-11-11-result-diversification-with-vespa/robert-lukeman-_RBcxo9AU-U-unsplash.jpg)
<p class="image-credit">
Photo by <a
href="https://unsplash.com/@robertlukeman?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Robert
Lukeman</a> on <a
href="https://unsplash.com/s/photos/nature?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
</p>

This blog post dives into how to achieve result diversification using Vespa's
grouping framework. The [Vespa grouping](https://docs.vespa.ai/en/grouping.html)
framework runs over hits selected by the
query formulation, supporting both to run over hits retrieved by traditional
query filters and keywords and nearest neighbor search. Thus, the Vespa grouping
framework allows building rich search experience result pages with facets and
diversification irrespective of the retrieval method.  Vespa result grouping is
used in many real-world production applications, implementing result
diversification for search and recommendation use cases. 


In the examples in this blog post, the result set is made diverse by grouping by
a <em>category</em> field
in the document schema. Fields used for grouping need to have the
[attribute](https://docs.vespa.ai/en/attributes.html)
declaration. 

<pre>
schema doc {
  document doc {
    field title type string {..}
    field category type int {
      indexing: summary | attribute
    }
    field doc_embedding type tensor&lt;int8&gt;(x[128]) {}
  }
  rank-profile my-ranking {
    first-phase { expression { .. }} 
  }
  document-summary short {
    summary title type string {
      source: title
    }
  }
}
</pre>

The following [YQL](https://docs.vespa.ai/en/query-language.html) query
groups results for a <em>userQuery()</em>.

<pre>
select * from doc where userQuery() limit 0 | all(group(category) max(10)
each(max(1) each(output(summary(short)))));
</pre>

The above query and grouping specification groups all hits retrieved by the
query by the category field. The original top ten (default limit) hits are
retained in the result set if one does not use <em>limit</em> zero. The default
hit limit
is ten, which is also controllable by the [native
hits](https://docs.vespa.ai/en/reference/query-api-reference.html#hits)
search API parameter.
Similar, result grouping is also supported when using dense retrieval with the
[nearest neighbor search query
operator](https://docs.vespa.ai/en/nearest-neighbor-search.html):

<pre>
select * from doc where
([{"targetHits":100}]nearestNeighbor(doc_embedding,query_embedding)) limit 0 |
all(group(journal) max(10) each(max(1) each(output(summary(short)))));
</pre>

In the dense retrieval case using nearest neighbor search operator, 
the number of hits exposed to grouping is limited when using
the nearest neighbor search operator. This behavior is due to the nature of the
approximate nearest neighbor search. There is no clear separation between a
match or no-match like with sparse term-based retrieval. 

Groups are by default sorted by the maximum hit relevancy score within the
group. The outer <em>max(10)</em> controls the maximum number of groups
returned. In
addition, the highest-ranking hit (<em>max(1)</em>) is emitted for each of the
unique
groups. The [ranking profile](https://docs.vespa.ai/en/ranking.html) 
used with the query assigns the hit relevance score.  

Note that if one increases the number of hits per group, the total number
increases with a
multiplicative factor. E.g., asking for three hits per group produces a total of
30 hits since the outer max specifies a maximum of ten groups. When using limits
on the number of groups or hits, 
the grouping API offers
[pagination](https://docs.vespa.ai/en/grouping.html#pagination) support
using continuation tokens. The support for per group pagination enables building
rich search result carousels. 

# Controlling group ordering 
The default
[ordering](https://docs.vespa.ai/en/grouping.html#ordering-and-limiting-groups)
of groups is, 
as mentioned, the maximum relevance score of
hits in the group. 
<pre>
all(group(category) order(-max(relevance())) max(10) each(max(1)
each(output(summary(short)))))
</pre>

Is the equivalent of 
<pre>
all(group(category) max(10) each(max(1) each(output(summary(short)))))
</pre>

The <em>-</em> in front of the max specifies the sorting order, - is descending,
which we
want (high relevancy score is better). 

It is possible to order groups by more complex expressions working on
aggregates like <em>sum()</em> and <em>count()</em>, for example:
- Number of hits in the group times the maximum relevance:
<em>order(-max(relevance())*count())</em> 
- The sum of a document ctr attribute for the hits in the group times the
  maximum
relevance: <em>order(-max(relevance())*sum(ctr))</em>

# Fine-tuning result diversification 
The grouped result computed in parallel over all cluster content nodes can be
post-processed in a [stateless
searcher](https://docs.vespa.ai/en/searcher-development.html). 
Then, the developer can further
diversify the result using custom business logic and finally present the
diversified results.  For example, when ordering groups by the max relevancy and
emitting more than one document per group, it
makes sense to check the relevance of the secondary hits from the group.
The searcher can also build and process the grouping request and response, see
[Searcher grouping api](https://docs.vespa.ai/en/grouping.html#search-container-api) 

# Serving performance  
Four main components drive serving performance when the query request includes
result grouping. In order of importance:

- The number of matches the query produces per node. All the document matches
  get
exposed to the grouping framework. The total result hit count of the query is
equal to the number of hits exposed to grouping. 
- The total number of unique values the field can take. 
- Ordering groups - using ordering expressions involving aggregates like count()
or sum() is more resource-intensive than using the default max relevance order. 
- Finally, the number of nodes involved in the query. 

The query selection logic controls the number of hits. Therefore, efficient
retrievers like
[weakAnd/wand](https://docs.vespa.ai/en/using-wand-with-vespa.html)
or [approximate nearest neighbor
search](https://docs.vespa.ai/en/approximate-nn-hnsw.html) 
expose fewer documents
to the ranking phases and the grouping framework. Thus, reducing the number of
hits can improve the performance significantly and also, in a way, enhance the
quality of the groups as low-scoring documents get excluded from the result
grouping. The downside is that aggregate statistics like count(), sum(), etc.
become inaccurate. 
The grouping language also allows limiting the number of hits that get grouped.
For example, to limit the number of hits per node, use an 
<pre>
all(max(K) all(group(category) .... ))
</pre>

In this expression, <em>K</em> is the maximum number of hits per
node that grouping runs over. 

It's also possible to limit the number of documents exposed to grouping by using 
the [match-phase
degradation](https://docs.vespa.ai/en/graceful-degradation.html#match-phase-degradation)
feature, which sets an upper limit on the number of documents ranked
, using a document attribute. This feature also includes diversity criteria
so that the results exposed to grouping also are diversified.

The number of unique values the field can take is data-dependent. A few ten
thousand unique values is usually a breeze. The number of nodes in the cluster
to which the query is fan out increases network bandwidth. The performance
impact could be mitigated using the precision parameter, limiting the number of
unique groups returned to the stateless container nodes.  


# Summary
This blog post covered how to use Vespa result grouping to produce a mixed
result set for both search and recommendation use cases. This post only covered 
single-level groups. However, the Vespa grouping framework also allows
running multi-level grouping. For
example, group by category, then by brand to further diversify the result. 
For further reading, see [result
grouping](https://docs.vespa.ai/en/grouping.html) and
[result grouping
reference](https://docs.vespa.ai/en/reference/grouping-syntax.html).

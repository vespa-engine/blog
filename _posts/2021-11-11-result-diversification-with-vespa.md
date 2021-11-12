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

Result diversification is a broad topic, and this blog post only scratches the surface of
the problem. One might classify result diversification as a multi-objective list optimization
problem. Conceptually, the core search or recommendation ranking procedure produces a ranked list of documents
scored on a per-document basis.  On the other hand, diversification looks at the overall list of ranked
documents. From a high level perspective, the diversity constraints could be expressed as a 
similarity function which re-order or remove similar matches to obtain an
ordering that optimizes variety. This post does not cover query intent diversification where
query specification is ambiguous and where the engine might show different types of results based on most probable query intents. 

# Life of a query in Vespa

Before getting into the details on result diversification with
Vespa, one needs to have a basic understanding of the distributed query execution in
Vespa.  For a query request that asks for a list of 100 best-ranking hits, the Vespa
stateless content layer will fan out the query to the content nodes. Each content node
produces a locally ranked list of top 100 <em>hits</em> out of potentially hundreds of millions of
documents <em>matching</em> the query specification. The stateless layer
merges the top 100 ranking <em>matches</em> from
all the content nodes and retains the global 100 top-ranking hits. 
The number of hits that are returned is controlled by the
[hits](https://docs.vespa.ai/documentation/reference/query-api-reference.html#hits)
or the [YQL limit
](https://docs.vespa.ai/en/reference/query-language-reference.html#limit-offset) parameter. 
See also [Vespa search sizing](https://docs.vespa.ai/en/performance/sizing-search.html)
for more details on Vespa query execution and scaling Vespa deployments.

In the following sections, a differentiation is made between between <em>hits</em> and
<em>matches</em>, where
matches are documents that match the query formulation. <em>Hits</em> are a typically a small subset of the
matches that are surfaced to the stateless search container. 


# Introducing Vespa Grouping Language
The [Vespa grouping language](https://docs.vespa.ai/en/grouping.html) is a list processing 
language that describes how the query
<em>matches</em> should be grouped, aggregated, and presented in results as <em>hits</em>. A grouping
statement takes the list of all <em>matches</em> to a query as input and groups/aggregates it,
possibly in multiple nested and parallel ways to produce the result output. 

The Vespa grouping list processing language runs over matches selected by the query formulation,
supporting matches retrieved by traditional query filters, keywords, and nearest neighbor
search. Thus, the Vespa grouping framework allows building rich search experience result
pages with facets and list diversification irrespective of the query retrieval method.  

# Using Vespa Grouping Language 
The following [YQL](https://docs.vespa.ai/en/reference/query-language-reference.html) query 
asks for ten best ranking <em>hits</em> from a <em>doc</em> document type 
[ranked](https://docs.vespa.ai/en/ranking.html) by the default ranking profile:

<pre>
select * from doc where userQuery() limit 10;
</pre>

The list of <em>hits</em> is not diversified in any way, just a flat list
of ten top ranking hits out of possible millions of <em>matches</em> out of billions of
documents in the corpus. 

In the first example of using Vespa grouping language, one can imagine there has been an 
offline process which have categorized documents
into a predefined <em>category</em>, uniquely identified by a numeric identifier. 
<pre>
schema doc {
  document doc {
    field title type string {..}
    field category type int {
      indexing: summary | attribute
    }
    field doc_embedding type tensor&lt;int8&gt;(x[128]) {}
  }
  rank-profile default inherits default {
    first-phase { expression { .. }} 
  }
  document-summary short {
    summary title type string {
      source: title
    }
  }
}
</pre>

Fields used in grouping expressions must be declared with [attribute](https://docs.vespa.ai/en/attributes.html).

The following [YQL](https://docs.vespa.ai/en/query-language.html) query
groups results for a <em>userQuery()</em> by <em>category</em>.

<pre>
select * from doc where userQuery() limit 10 | all(group(category) max(10)
each(max(2) each(output(summary(short)))));
</pre>

The above query and grouping specification groups all matches 
by the category field. The undiversified ranked list of ten hits are
retained in the result set when using <em>limit 10</em>. 
The hits from the diversified result set is emitted 
by the <em>each(output(summary()))</em> expression.

To remove the un-diversified ranked list use <em>limit 0</em>: 

<pre>
select * from doc where userQuery() limit 0 | all(group(category) max(10)
each(max(2) each(output(summary(short)))));
</pre>

Groups are by default sorted by the maximum hit relevancy score within the
group. The outer <em>max(10)</em> controls the maximum number of groups
returned. In
addition, the two highest-ranking hits (<em>max(2)</em>) is emitted for each of the
unique groups, in this case, categories.
The Vespa grouping API supports [pagination](https://docs.vespa.ai/en/grouping.html#pagination) 
using continuation tokens. 
In the above example, the grouping expression used a single document attribute, it is also
possible to group by expressions. See the [grouping
reference](https://docs.vespa.ai/en/reference/grouping-syntax.html) documentation.
In the below example the group identifier is a concatenation of category and brand: 
<pre>
all(group(cat(category,brand)) max(10)
each(max(2) each(output(summary(short)))));
</pre>

### Dense retrieval with nearest neighbor search 

Result grouping is also supported when using dense retrieval with the
[nearest neighbor search query
operator](https://docs.vespa.ai/en/nearest-neighbor-search.html):

<pre>
select * from doc where
([{"targetHits":100}]nearestNeighbor(doc_embedding,query_embedding)) limit 0 |
all(group(journal) max(10) each(max(2) each(output(summary(short)))));
</pre>

In the dense retrieval case, using the (approximate) nearest neighbor search operator, 
the number of <em>matches</em> exposed to grouping is limited by the <em>targetHits</em>. 
This behavior is due to the nature of the
approximate nearest neighbor search. There is no clear separation between a
<em>match</em> or no-match like with sparse term-based query retrieval. 

# Controlling group ordering 
The default
[ordering](https://docs.vespa.ai/en/grouping.html#ordering-and-limiting-groups)
of groups is, as mentioned, the maximum relevance score of the hits in the group. 

<pre>
all(group(category) max(10) each(max(1) each(output(summary(short)))))
</pre>
Is the equivalent of 
<pre>
all(group(category) order(-max(relevance())) max(10) each(max(1)
each(output(summary(short)))))
</pre>
The <em>-</em> denotes descending sort order.

It is possible to order groups by more complex expressions working on
<em>match</em> aggregates like <em>sum()</em> and <em>count()</em>, for example:
- Number of <em>matches</em> in the group times the maximum relevance:
<em>order(-max(relevance())*count())</em> 
- The sum of a document attribute times the
  maximum relevance <em>order(-max(relevance())*sum(ctr))</em>

# Fine-tuning result diversification with phased execution
The grouping examples in previous sections 
are using "bucketing" as the diversity similarity
function. The advantage of group bucketing is scalability. It is fast to compute globally over many nodes,
over many matches. The downside is that the expressiveness of the diversity similarity function is limited.

Once the grouped result <em>hits</em> have been computed in parallel over all content nodes 
, the resulting <em>hits</em> can be post-processed using a more complex diversity similarity function. At 
the post processing stage the potential large number of matches have been reduced to lists of top ranked hits. Therefore, 
the diversity similarity function can use a richer set of features and compute complexity.  

This type of architecture is a phased or tiered architecture where the first phase selects
diverse "bucketed" candidates efficiently over potentially a large number of matches and
the subsequent phases post processes the results using a more complex diversity function:

- Vespa grouping language is used to fetch candidate documents which are diversified and
  ranked using bucketing. 
- Post processing logic on the top result ranking lists from the parallel grouping execution and
  implements a more complex diversity similarity function

It is also considerably easier to implement custom business logic like "Never display more than four of type x for users of type z" in
the post processing stage. The downside of custom post-processing is that it complicates pagination support.
 
Post-processing diversity and business logic routines are best added by writing [stateless
searcher](https://docs.vespa.ai/en/searcher-development.html), for example implementing
this [diversity algorithm](https://tech.ebayinc.com/engineering/diversity-in-search/). 
Deploying the post processing logic in a searcher avoids network round trips and serialization and
de-serialization. The internal communication protocol between stateless and stateful Vespa nodes
is binary and is secured using mTLS so there is considerably less overhead doing round trips between
a stateless searcher component and the content nodes. 

The custom searcher function can also build and process the grouping request and response programmatically, see
[Searcher grouping api](https://docs.vespa.ai/en/grouping.html#search-container-api).

# Serving performance  
Four main components drive serving performance of query requests that 
use Vespa result grouping. In order of importance:

- The number of matches the query produces per node. All the document matches
  get
exposed to the grouping framework. The total result hit count of the query is
equal to the number of <em>matches</em> exposed to grouping. 
- The total number of unique values in the field. 
- Ordering groups - using ordering expressions involving aggregates like count()
or sum() is more resource-intensive than using the default max relevance order. 
- Finally, the number of nodes involved in the query. 

The query selection logic controls the number of <em>matches</em>. 
Therefore, efficient
retrievers like [weakAnd/wand](https://docs.vespa.ai/en/using-wand-with-vespa.html)
or [approximate nearest neighbor
search](https://docs.vespa.ai/en/approximate-nn-hnsw.html) expose
expose fewer matches to configurable ranking and grouping.
Thus, reducing the number of matches can improve the serving performance significantly and
also,enhance the quality of the groups as low-scoring documents are excluded from the
result grouping. 
The grouping language also allows limiting the number of <em>matches</em> that are grouped.
For example, to limit the number of <em>matches</em> per node, use an 
<pre>
all(max(K) all(group(category) .... ))
</pre>

In this expression, <em>K</em> is the maximum number of matches per
node that grouping runs over. 

It's also possible to limit the number of <em>matches</em> exposed to grouping by using 
the [match-phase
degradation](https://docs.vespa.ai/en/graceful-degradation.html#match-phase-degradation)
feature, which sets an upper limit on the number of documents ranked
, using a document side quality attribute. The match phase degradation feature supports diversity criteria
so that the matches exposed to grouping also are diversified. The <em>match-phase</em> diversification is 
currently not supported for the approximate nearest neighbor search operator. 

The number of unique values the field is data-dependent, fewer unique values is better. 
The number of nodes in the cluster
to which the query is fanned out increases network bandwidth. The performance
impact could be mitigated using the
[precision](https://docs.vespa.ai/en/reference/grouping-syntax.html#precision) parameter, 
limiting the number of
unique groups returned to the stateless container nodes and reducing network bandwidth
usage.  


# Summary
This blog post covered how to use Vespa result grouping to produce a mixed
result set for both search and recommendation use cases. As many search and recommendation
use cases it is best solved using a phased execution with gradually increasing complexity.

This post only covered 
single-level grouping expressions. 
However, the Vespa grouping framework also allows
running multi-level grouping. For
example, group by category, then by brand to further diversify the result. 
For further reading, see [result
grouping](https://docs.vespa.ai/en/grouping.html) and
[result grouping
reference](https://docs.vespa.ai/en/reference/grouping-syntax.html).

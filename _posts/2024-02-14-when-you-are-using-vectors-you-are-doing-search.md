---  
layout: post
title: "When you're using vectors you're doing search"
author: bratseth
date: '2024-02-14'
image: assets/2024-02-14-when-you-are-using-vectors-you-are-doing-search/coral.jpg
image_credit: Photo by <a href="https://unsplash.com/@neom?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">NEOM</a> on <a href="https://unsplash.com/photos/an-aerial-view-of-a-body-of-water-D1jr0Mevs-c?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Unsplash</a>
skipimage: true
tags: [vector, search]
excerpt: "Combining scale and quality takes more than vector similarity search"
---
The legends tell us that in the ancient times you could only put numbers in your databases. 
Then somebody invented the string, and
the revolutionary **string database** was born, giving you somewhere to stash these strings until you needed them.
But soon enough, the incumbent *number databases* realized that strings are really just lists of numbers 
and they could handle them just fine, so every database became a string database and nowadays we just call them databases, 
the end.

No, I'm kidding - it wasn't the end, because there was a tiny problem: You want to be able to find the strings 
that are most relevant to some task at hand, and this is very, very, very non-trivial. To solve
*that* problem, databases weren't very useful, so the **search engine** was born.

Why do we call them "search engines" and not "string databases"? Because the hard part, the important part, isn't
to hold on to your strings for later, but to *compute what's most relevant to a given task*.

### Fine, it's about vector databases

By now, you have of course gotten the analogy to vector databases, but it isn't perfect: 
Strings are actually quite useful on their own, while in almost all cases when somebody 
uses vectors it is to help elicit some *other* data.

So, the question then is: What does it take to make vectors help eliciting some data?
According to common imagination as of 2023 all you needed was to embed with some off-the-shelf model,
retrieve by approximate nearest neighbor, and you were set!

However, this is simply not true (and 2024 is the year of reckoning). 
[Time and time again](https://twitter.com/jobergum/status/1756018718864195872/photo/1) 
we see that when it comes to retrieving by text,
even simple approaches such as lexical search+bm25 beats vector-only relevance handily, which is unfortunate for the
vectors since employing them is orders of magnitude more expensive.

In other cases such as image search and approximate retrieval of structured data, good alternatives are scarce, 
and baselines may be missing entirely, but it might still be a good idea to make the best of the data you have.

### Let's not ask for too little to get the job done

So what does is take to create a quality solution involving vector embeddings?

- **Hybrid search**: If you are working with text, retrieving both lexically and by vector similarity is 
[superior to just one or the other](https://blog.vespa.ai/improving-zero-shot-ranking-with-vespa/): 
Lexical search lets you find specific data precisely, 
while vectors allows you to overcome vocabulary mismatch and retrieve by semantic similarity.
<br/><br/>Make sure to not take the lexical search too lightly - you need an engine that incorporates linguistic processing 
for the languages you are dealing with to do this well.

- **Multiple vectors, collections of vectors**: So, you have a vector, some structured data, and
maybe some text - together a [document](https://docs.vespa.ai/en/reference/schema-reference.html#document) 
in search engine speak. Is that enough?
<br/><br/>Well, normally not.
For example, you might want to have an embedding for a title, a description and an image - 
all in the same document. Or, even if your data is very simple you must be able to switch to a 
new embedding while one is in use. And if you are dealing with text longer than a paragraph, 
a single embedding won't really work. You need one per chunk of text, 
or maybe even [one per token](https://blog.vespa.ai/announcing-colbert-embedder-in-vespa/).<br/><br/>
You need to be able to add multiple vector fields to your documents, and those may be a 
[collection of vectors](https://blog.vespa.ai/semantic-search-with-multi-vector-indexing/), 
not just a single one.

- **Structured data**: In any real application you won't just have vectors, but also structured data
  going along with it. This can be everything from simple numbers or strings to complex collections and structs.
  You need to be able to use this data flexibly and [efficiently](https://blog.vespa.ai/constrained-approximate-nearest-neighbor-search/)
  in queries, and to determine the relevance
  of the documents to return.

- **Ranking**: So, we have documents, that contains structured data, text, and vector fields. 
We retrieve a subset of them with a query which is a tree of conditions over these field.
Now, how do we *rank* them so that we end up with the very best ones? Ranking just by nearest 
neighbor in some vector space won't do; it is disregarding all our other information - for example
if we have a popularity score or a recency among our structured data, and if we're doing hybrid search
we should take into account how well we match lexically.
<br/><br/>What we need is to combine *all* the signals we have - vectors, structured data, text matching and so on - 
into a single score. The right way to do this depends on the data and application, and it must
scale [from simple business heuristics to large machine-learned models](https://docs.vespa.ai/en/ranking.html#). 
*This* is the central task of creating a 
quality application, once you have mastered the basics.<br/><br/> 
And by the way, when it comes to text, bm25 is just a good 
start. Text matching contains so much information, and to create a good hybrid application you need
to be able to [get all that detail information](https://docs.vespa.ai/en/reference/rank-features.html#field-match-features-normalized) 
as input to your ranking.

And here I won't so much as mention the other things you'll need to create a typical production application, 
such as [grouping and aggregation](https://docs.vespa.ai/en/grouping.html), 
realtime partial updates, contextual snippets, multiple types of ranking, and 
[safe continuous deployments](https://cloud.vespa.ai/en/automated-deployments).

### Divide and conquer?

Okay, so all this is needed, but maybe we can divide and conquer? Let the experts on each thing handle
their part and work together at runtime? Unfortunately, this just doesn't scale -
the network bandwidth needed to handle <code>query rate * candidate documents * signals</code> 
per document is really not feasible, I encourage you to plug in your own numbers to check. 
This was the case even before vectors, when all signals were scalars,
which is why search engines do ranking internally.
Not that all the integration work and multiple dependencies would be too much fun either.

To create something with quality using vectors and scale for success, 
you need a single platform that handles all of this at once, where you can
define applications that models all the information you have and specifies how
to search it and use it to compute ranking and other inferences, 
and deploy them at any scale without changing anything about how they work.
This is the conviction that led us to design the Vespa platform the way we have.

---  
layout: post
title: "When you're using vectors you're doing search"
author: bratseth
date: '2024-02-13'
image: assets/2024-02-13-when-youre-using-vectors-youre-doing-search/TODO
skipimage: true
tags: [vector, search]
excerpt: "TODO"
---
In the ancient times you could only put numbers in your databases. Then somebody invented the string, and
the revolutionary **string database** was born, allowing you to put in these strings, and then find them later.
But soon enough, the incumbent *number databases* realized that a string is just a list of numbers and they could
handle them just fine, so every database became a string database and nowadays we just call them databases, the end.

No, I'm kidding - it wasn't the end, because there was a tiny problem: You want to be able to find the documents
with the strings that are most relevant to some task at hand, and this is very, very, very non-trivial. To help solve
*that* problem, databases wasn't very useful, so the **search engine** was born.

Why do we call them search engines and not string databases? Because the hard part, the important part, isn't
to put in some strings and get them back later, but to compute what data is most relevant to some given task.

You have obviously gotten the analogy to vector databases, but it isn't perfect: Strings are actually quite useful
on their own, while in almost all cases when somebody uses vectors it is to help elicit some other data.

So, the question then is: What does it take to make vectors helpful in surfacing some data?
According to common imagination as of 2023 all you need to do is use some off-the-shelf embedding model,
and retrieve by approximate nearest neighbor and you're set!

However, this is simply not true. Time and time again we see that when it comes to retrieving by text,
even simple approaches such as lexical search+bm25 beats vector relevance handily, which is unfortunate for the
vectors since employing them is orders of magnitude more expensive.

In other cases such as image search, or approximate retrieval of structured data, good alternatives are scarce, 
but you still want to make the best of the data you have.

So what does is take to create a quality solution which involves vector embeddings?

- Hybrid search: If you are working with text, retrieving both lexically and by vector similarity is 
always superior to just one or the other: Lexical search lets you find specific data precisely, 
e.g when searching for names or bvery specific concepts, while vectors allows you to overcome  
vocabulary mismatch and retrieve by semantic similarity. Don't take the lexical search too lightly -
you need an engine that incorporates linguistic processing for the languages you are dealing with
to do this with reasonable quality.

- Structured data: In any real application you won't just have vectors, you'll also have some
structured data - in addition to vectors and text - going along with it. A vector database
will often call this "metadata", but it's not clear why this is more 'meta' than the vectors.
Structured data can be simple numbers or strings, or complex collections and structs,
and you need to be able to use them flexibly and efficiently in queries, and to determine
the relevance of the documents to return.

- Multiple vectors and collections of vectors: So, you have a vector and some structured data, and
then maybe some text - a document in search engine speak. Is that enough? Well, normally not.
For example, if your documents are products you should be able to create an embedding from a picture of it, 
and another from the description.  Or, even if your data is very simple you must be able to switch to a 
new embedding while in use. And what if you are dealing with text linger than a paragraph, 
then a single embedding doesn't really work. Or maybe you want to represent each token as a vector to 
achieve state of the art quality.
You need to be able to add multiple different vector fields to your documents, and each of those fields
must be able to be a collection of vectors, not just a single vector.

- Ranking: So, we have documents, that contains structured data fields, text fields, as well as one or more 
vectors. We recall among those by giving a query which is a boolean tree of conditions over these and retrieve
a subset of them, now how do we rank them so that we end up with the very best ones? Of course ranking by nearest 
neighbor in some vector space won't do since it is disregarding all our other information.
What we need is to combine all the signals we have - vectors and similarities, structured data and text matching - 
into a single score. There is no single right way to do this as it depends on the data and application, and it must
scale from simple business heuristics to large machine-learned models. *This* is the central task of creating a 
quality application, once you have the basics in place. And by the way, when it comes to text, bm25 is just the 
start. Text matching contains so much information, and to create a good hybrid application you need
to be able to get all that detail information as input to your ranking.

Okay, so all this is needed, but maybe we can divide and conquer? Let the experts on each thing handle
it and just orchestrate them to work together at runtime? Unfortunately, this doesn't scale -
the network bandwidth needed to handle query rate * candidate documents * signals per document is
just not feasible to achieve. This was the case even before vectors, when all signals were scalars,
which is why search engines do ranking internally.
Not that all the integration work and multiple dependencies would be too fun either.

To create something with quality using vectors and meet the scaling demands of success, 
you really do need a single platform that handles all of these needs well in a single package.





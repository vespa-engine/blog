---  
layout: post
title: "Embedding flexibility in Vespa"
author: bratseth
date: '2024-02-16'
image: assets/2024-02-12-gigaom-radar-sonar-for-vector-databases-positions-vespa-as-a-leader/Gigaom_leader.png
skipimage: true
tags: [embeddings]
excerpt: "Why did Vespa score \"Exceptional\" on Embedding Flexibility in GigaOm's report on Vector Databases?"
---
In the recent [GigaOm Sonar Report on Vector Databases](https://content.vespa.ai/gigaom-report-2024) 
where Vespa came out as *Leading*, one of the criteria where we scored *Exceptional* were
*Embedding Flexibility*.

<img src="/assets/2024-02-15-newsletter/GigaOm-badge-2024_leader-11.png"
alt="Vespa Recognized as a Leader and Forward Mover in GigaOm Sonar for Vector Databases"
width="150px" height="auto" />

What's so great about the embedding flexibility in Vespa? You have the choice of doing embeddings in four ways:
- On your own, outside Vespa: Just [pass tensors directly](https://docs.vespa.ai/en/reference/document-json-format.html#tensor) in documents and queries.
- With your own model, run by Vespa: Add the model to the application package and 
[reference it in <code>embed</code> expressions](https://docs.vespa.ai/en/embedding.html#embedding-a-document-field).
- With a model provided by Vespa: [Reference a model on the model hub](https://cloud.vespa.ai/en/model-hub#hugging-face-embedder) in your embed expression.
- With custom code doing what you want in a [custom Embedder](https://docs.vespa.ai/en/embedding.html), or, if you want full control 
over the process, a custom [Searcher](https://docs.vespa.ai/en/searcher-development.html) and 
[Docproc](https://docs.vespa.ai/en/document-processing.html)

In addition to creating single embeddings for a field, all these methods also allows you to 
create and index a [collection of embeddings](https://blog.vespa.ai/semantic-search-with-multi-vector-indexing/) 
for a single document, either by using an embedding model
that [creates an embedding for each token of the text](https://blog.vespa.ai/announcing-colbert-embedder-in-vespa/), 
by embedding an array of strings,
or doing both at the same time. You can use multiple of these methods at the same time for different fields,
and change method at any time without changing any other aspect of the application.
This lets you get started easily with embeddings while also empowering you to add more sophisticated methods
gradually.

And if you add fields that derives an embedding for a field to an existing application,
it will be automatically populated. Combined with the support for having multiple embeddings in the same
document and choose which ones to use in queries and ranking, this makes it exceptionally easy to experiment with new 
embedding models.

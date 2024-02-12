---  
layout: post
title: "GigaOm Radar Sonar for Vector Databases Positions Vespa as a Leader"
author: bratseth
date: '2024-02-05'
image: assets/2024-02-05-gigaom-radar-sonar-for-vector-databases-positions-vespa-as-a-leader/Gigaom_Logo.png
skipimage: true
tags: []
excerpt: "Although we're more than a vector database, we're happy to be recognized as a leader in this category"
---

Vector databases have evolved from an obscure term to a crowded product category over the last few years. 
As the platform for applications combining AI and data to deliver online experiences, 
we at Vespa generally take a broader view of the features we need to deliver 
than those usually included in this category.

Still, vector database features are important, and we aim for Vespa to always come out on top also when 
evaluated purely on this subset of features. Therefore I’m very pleased that the analyst firm GigaOm today is 
recognizing Vespa as a leader and forward mover in their 
[Sonar for Vector Databases](https://content.vespa.ai/gigaom-report-2024).

We have focused solely for many years on delivering the complete set of features that enables 
developers to build real data and AI-driven applications that perform at any scale, 
and it is gratifying to see that the groundswell created by this engineering-first approach 
has now risen to reach leading independent analysts like GigaOm.

The research cites Vespa as a platform leader “because of its widespread embedding flexibility, 
rapid time for updating, and hybrid search capabilities–with neural network rankings. 
These are critical to maximizing the ROI for vector similarity search engines.”

This touches upon several important needs faced by real world applications in this space:

- They need to be able to control and evolve the embedding models they use in their applications - 
  and they need to be able to do so while they are serving queries and handling writes as normal. 
  It must be possible to use embeddings of any size, have both multiple kinds and multiple instances of vectors 
  per data item, and to use any value type with embeddings.

- Both vectors, text and metadata must be changeable in real time, and independently of each other, 
  such as to make very high volume changes to some scalar signal without having to rewrite any vectors.

- Most applications dealing with text find that they also need to lexically index the text, 
  and combine vector similarity with text match signals - vector similarity can’t recall specific terms 
  in your data such as names, and quality relevance goes way beyond vector similarity and a simple bm25 score.

- Achieving quality results requires combining many signals in addition to vectors, both from metadata 
  and (often) text matching. Only machine-learned models can do this job well, and to make it scale 
  and perform these must run locally on the data nodes to avoid running out of bandwidth.

The nice thing with Vespa is that you can start simple, and as you need to deliver world leading quality, 
or scale to hundreds of thousands of requests per second, you know we have your back as Vespa has been 
used to do that many times before.

Read GigaOm’s full report [here](https://content.vespa.ai/gigaom-report-2024).

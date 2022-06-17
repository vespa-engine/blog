---
layout: post
title: Vespa at Berlin Buzzwords 2022 
date: '2022-06-17'
categories: []
tags: []
image: assets/2022-06-18-vespa-at-berlin-buzzwords/cover.png
author: kkraune
skipimage: true
excerpt: >
    Find videos and links from four Vespa-related talks at Berlin Buzzwords 2022,
    Germany’s most exciting conference on storing, processing, streaming and searching large amounts of digital data.
---

<img src="/assets/2022-06-18-vespa-at-berlin-buzzwords/cover.png"
     alt="Lester Solbakken presenting at Berlin Buzzwords 2022"/>
<p class="image-credit">
Lester Solbakken presenting at Berlin Buzzwords 2022
</p>

[Berlin Buzzwords 2022](https://2022.berlinbuzzwords.de/) has just finished and we thought it would be great to summarize 
the event. Berlin Buzzwords is Germany's most exciting conference on storing, processing, streaming and searching large amounts of digital data, with a focus on open source software projects.

## AI-powered Semantic Search; A story of broken promises?
Jo Kristian Bergum from the Vespa team gave a talk on [AI-powered Semantic Search; A story of broken promises?](https://pretalx.com/bbuzz22/talk/7TYXQN/). 


> Semantic search using AI-powered vector embeddings of text, where relevancy is measured using a vector similarity function, has been a hot topic for the last few years. As a result, platforms and solutions for vector search have been springing up like mushrooms. Even traditional search engines like Elasticsearch and Apache Solr ride the semantic vector search wave and now support fast but approximative vector search, a building block for supporting AI-powered semantic search at scale.

>Without doubt, sizeable pre-trained language models like BERT have revolutionized the state-of-the-art on data-rich text search relevancy datasets. However, the question search practitioners are asking themself is, do these models deliver on their promise of an improved search experience when applied to their domain? Furthermore, is semantic search the silver bullet which outcompetes traditional keyword-based search across many search use cases? This talk delves into these questions and demonstrates how these semantic models can dramatically fail to deliver their promise when used on unseen data in new domains.


<iframe width="560" height="315" src="https://www.youtube.com/embed/7ozfzKLTFV4" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

If you were interested in this talk, why don't you check out some of our previous work on state-of-the-art text ranking:

- [Pretrained Transformer Language Models for Search - part 1](https://blog.vespa.ai/pretrained-transformer-language-models-for-search-part-1/)
- [Pretrained Transformer Language Models for Search - part 2](https://blog.vespa.ai/pretrained-transformer-language-models-for-search-part-2/)
- [Pretrained Transformer Language Models for Search - part 3](https://blog.vespa.ai/pretrained-transformer-language-models-for-search-part-3/)
- [Pretrained Transformer Language Models for Search - part 4](https://blog.vespa.ai/pretrained-transformer-language-models-for-search-part-4/)

Also check out the Vespa [MS Marco sample application](https://github.com/vespa-engine/sample-apps/tree/master/msmarco-ranking)
which demonstrates how to represent state-of-the-art ranking methods with Vespa. 

See also our blog posts on Vector search:
- [Billion-scale vector search using hybrid HNSW-IF](https://blog.vespa.ai/vespa-hybrid-billion-scale-vector-search/)
- [Query Time Constrained Approximate Nearest Neighbor Search](https://blog.vespa.ai/constrained-approximate-nearest-neighbor-search/)
- [Billion-scale vector search with Vespa - part two](https://blog.vespa.ai/billion-scale-knn-part-two/)
- [Billion-scale vector search with Vespa - part one](https://blog.vespa.ai/billion-scale-knn/)

## Hybrid search > sum of its parts?
Lester Solbakken from the Vespa team gave a talk on [Hybrid search > sum of its parts?](https://pretalx.com/bbuzz22/talk/YEHRTE/). 

>Over the decades, information retrieval has been dominated by classical methods such as BM25. These lexical models are simple and effective yet vulnerable to vocabulary mismatch. With the introduction of pre-trained language models such as BERT and its relatives, deep retrieval models have achieved superior performance with their strong ability to capture semantic relationships. The downside is that training these deep models is computationally expensive, and suitable datasets are not always available for fine-tuning toward the target domain.

>While deep retrieval models work best on domains close to what they have been trained on, lexical models are comparatively robust across datasets and domains. This suggests that lexical and deep models can complement each other, retrieving different sets of relevant results. But how can these results effectively be combined? And can we learn something from language models to learn new indexing methods? This talk will delve into both these approaches and exemplify when they work well and not so well. We will take a closer look at different strategies to combine them to get the best of both, even in zero-shot cases where we don't have enough data to fine-tune the deep model.

<iframe width="560" height="315" src="https://www.youtube.com/embed/R5BLbnXPR5c" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

## Understanding Vespa with a Lucene mindset
Atita Arora from [OpenSource connections](https://opensourceconnections.com/) gave a great talk on
[Understanding Vespa with a Lucene mindset](https://pretalx.com/bbuzz22/talk/WNYRZF/). Fantastic overview
of Vespa, Vespa's strengths and how Vespa compares to Apache Lucene based search engines. 

>Vespa is no more a 'new kid on the block' in the domain of search and big data. Everyone is wooed over reading about its capabilities in search, recommendation, and machine-learned aspects augmenting search especially for large data-sets. With so many great features to offer and so less documentation to how to get started on Vespa , we want to take an opportunity to introduce it to the lucene based search users.
We will cover about Vespa architecture , getting started , leveraging advance features , important aspects all in the analogies easier for someone with a fresh or lucene based search engines mindset.

<iframe width="560" height="315" src="https://www.youtube.com/embed/_ML-QB0Zxvg" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

## Matscholar: The search engine for materials science researchers
John Dagdelen from the department of materials science and engineering at UC Berkeley,  
gave a insightful talk on [Matscholar: The search engine for materials science researchers](https://pretalx.com/bbuzz22/talk/GAGCJ3/). This talk demonstrates how Vespa can be used to power advanced search use cases, including entity recognition, 
embedding, grouping and aggregation. 

>Matscholar (Matscholar.com) is a scientific knowledge search engine for materials science researchers. We have indexed information about materials, their properties, and the applications they are used in for millions of materials by text mining the abstracts of more than 5 million materials science research papers. Using a combination of traditional and AI-based search technologies, our system extracts the key pieces of information and makes it possible for researchers to do queries that were previously impossible. Matscholar, which utilizes Vespa.ai and our own bespoke language models, greatly accelerates the speed at which energy and climate tech researchers can make breakthroughs and can even help them discover insights about materials and their properties that have gone unnoticed.
<iframe width="560" height="315" src="https://www.youtube.com/embed/5rLOO10hUeY" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>


## Summary
Berlin Buzzwords is a great industry conference, and the 2022 edition was no exception. Lots of interesting discussions, talks 
and new friends and connections were made. 

If you were inspired by the Vespa talks you can get started by the following Vespa sample applications:

- [State-of-the-art text ranking](https://github.com/vespa-engine/sample-apps/blob/master/msmarco-ranking/passage-ranking.md): 
Vector search with AI-powered representations built on NLP Transformer models for candidate retrieval. 
The application has multi-vector representations for re-ranking, using Vespa's [phased retrieval and ranking](https://docs.vespa.ai/en/phased-ranking.html) 
pipelines. Furthermore, the application shows how embedding models, which map the text data to vector representation, can be 
deployed to Vespa for [run-time inference](https://blog.vespa.ai/stateless-model-evaluation/) during document and query processing.

- [State-of-the-art image search](https://github.com/vespa-engine/sample-apps/tree/master/text-image-search): AI-powered multi-modal vector representations
to retrieve images for a text query. 

- [State-of-the-art open-domain question answering](https://github.com/vespa-engine/sample-apps/tree/master/dense-passage-retrieval-with-ann): AI-powered vector representations
to retrieve passages from Wikipedia, which are fed into an NLP reader model which extracts the answer. End-to-end represented using Vespa.

These are examples of applications built using AI-powered vector representations and where real-world deployments 
need query-time constrained nearest neighbor search. 

Vespa is available as a cloud service; see [Vespa Cloud - getting started](https://cloud.vespa.ai/en/getting-started),
or self-serve [Vespa - getting started](https://docs.vespa.ai/en/getting-started.html).  

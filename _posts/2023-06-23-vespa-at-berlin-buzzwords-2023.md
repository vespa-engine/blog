---
layout: post
title: Vespa at Berlin Buzzwords 2023 
date: '2023-06-23'
categories: []
tags: []
image: assets/2023-06-23-vespa-at-berlin-buzzwords-2023/bb2023.png
author: kkraune
skipimage: true
excerpt: >
    Summarizing Berlin Buzzwords 2023,
    Germany’s most exciting conference on storing, processing, streaming and searching large amounts of digital data.
---

<img src="/assets/2023-06-23-vespa-at-berlin-buzzwords-2023/bb2023.png"
     alt="Jo Kristian Bergum presenting at Berlin Buzzwords 2023"/>
<p class="image-credit">
Jo Kristian Bergum presenting on using LLMs for training ranking models at Berlin Buzzwords 2023
</p>

[Berlin Buzzwords 2023](https://2023.berlinbuzzwords.de/) has just finished and we thought it would be great to summarize 
the event. Berlin Buzzwords is Germany's most exciting conference on storing, processing, streaming and searching large amounts of digital data, with a focus on open source software projects. This year, the conference was filled with exciting talks about Large Language Models (LLMs) and neural search techniques. 

## Boosting Ranking Performance with Minimal Supervision
Jo Kristian Bergum from the Vespa team gave a talk on [Boosting Ranking Performance with Minimal Supervision](https://2023.berlinbuzzwords.de/sessions/?id=YTLX8T). 

> Using generative Large Language Models (LLMs) to generate synthetic labeled data to train in-domain ranking models. Distilling the knowledge and power of generative LLMs into effective ranking models.

<iframe width="560" height="315" src="https://www.youtube.com/embed/GDM4cUsvaWg" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>

If you were interested in this talk, why don't you check out some of our previous work on zero-shot ranking and 
adapting ranking models to new domains using LLMs:

- [Improving Search Ranking with Few-Shot Prompting of LLMs](/improving-text-ranking-with-few-shot-prompting/)
- [Improving Zero-Shot Ranking with Vespa Hybrid Search](/improving-zero-shot-ranking-with-vespa/)
- [Improving Zero-Shot Ranking with Vespa Hybrid Search - part two](/improving-zero-shot-ranking-with-vespa-part-two/)

In the context of ranking and retrieving context for LLMs we can also recommend:

- [Minimizing LLM Distraction with Cross-Encoder Re-Ranking](/improving-llm-context-ranking-with-cross-encoders/)
- [Vespa support in langchain](/vespa-support-in-langchain/)

## The Debate Returns (with more vectors): Which Search Engine?
Jo Kristian Bergum from the Vespa team joined [a panel](https://2023.berlinbuzzwords.de/sessions/?id=73UNZD) 
of search engine and vector search experts to discuss and contrast search technologies. 

<iframe width="560" height="315" src="https://www.youtube.com/embed/iI40L4wMtyI" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>
<p></p>

## Privacy-Preserving Web Search
[Lara Perinetti](https://www.linkedin.com/in/lara-perinetti-7a0632b9/) 
from [Qwant.com](https://www.qwant.com/) gave a talk about building privacy preserving web search. 
Qwant uses Vespa for indexing and ranking 5B web documents. 

<iframe width="560" height="315" src="https://www.youtube.com/embed/ciCh85w8FfM" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>
<p></p>

## Bar Camp at Berlin Buzzwords 2023
Berlin Buzzword's Barcamp is an informal session with a schedule decided on the day. This
session was not recorded. 

[Tom Gilke](https://www.linkedin.com/in/tom-gilke) 
from otto.de ([see their Tech Blog](https://www.otto.de/jobs/en/technology/techblog/)), Germany's second
largest e-commerce site, presented on using Vespa for search suggestions. 

<img src="/assets/2023-06-23-vespa-at-berlin-buzzwords-2023/otto-talk.jpeg"
     alt="Tom Gilke from Otto.de presenting at Berlin Buzzwords 2023"/>
<p class="image-credit">
Tom Gilke from Otto.de presenting at Berlin Buzzwords 2023.
</p>

[Tom Gilke](https://www.linkedin.com/in/tom-gilke) presented on introducing semantic search suggestions using 
[Vespa nearest neighbor search](https://docs.vespa.ai/en/approximate-nn-hnsw.html) 
combined with [Vespa's embedding inference capabilities](https://blog.vespa.ai/enhancing-vespas-embedding-management-capabilities/).

We also recommend a talk on how the otto.de team migrated their infrastructure for powering search suggestions. They 
present their iterations moving from Elasticsearch to a simple python solution and in the end to Vespa in 
[How we built the autosuggest infrastructure for otto.de](https://www.youtube.com/watch?v=hZ9sCxj5fEk).  

## Learning to hybrid search
<iframe width="560" height="315" src="https://www.youtube.com/embed/TBGkis0U1bg" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>
[Roman Grebennikov](https://www.linkedin.com/in/romangrebennikov/) 
and [Vsevolod Goloviznin](https://www.linkedin.com/in/vgoloviznin/) presented on hybrid search ranking alternatives, all evaluated on 
the Amazon's ESCI product ranking dataset.

We at the Vespa team have also worked with this large e-commerce ranking dataset in our blog series on 
<em>Improving Product Search with Learning to Rank</em>:

- [Part one: introduction to ESCI product ranking dataset](/improving-product-search-with-ltr/)
- [Part two: neural methods ](https://blog.vespa.ai/improving-product-search-with-ltr-part-two/)
- [Part three: GBDT methods (hybrid)](https://blog.vespa.ai/improving-product-search-with-ltr-part-three/)

## Vectorize Your Open Source Search Engine

<iframe width="560" height="315" src="https://www.youtube.com/embed/U7PQNyeQrXQ" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>

In this talk, [Atita Arora](https://opensourceconnections.com/team/atita-arora/) gave a talk on vector search using 
[bi-encoders](https://blog.vespa.ai/pretrained-transformer-language-models-for-search-part-2/) that maps queries and documents
into a latent embedding vector space and performs similarity search using nearest neighbor search.  

<img src="/assets/2023-06-23-vespa-at-berlin-buzzwords-2023/Fy-UpZkXsAE30Uw.jpeg"
     alt="Atita Arora from https://opensourceconnections.com/ presenting at Berlin Buzzwords 2023"/>
<p class="image-credit">
Atita Arora from Open Source Connections presenting at Berlin Buzzwords 2023.
</p>

One key takeaway from the talk was a relevance evaluation breakdown by query type intent, where 
we clearly can see that vector search alone [does not solve all search use cases](https://blog.vespa.ai/will-vector-dbs-dislodge-search-engines/).

## The state of Neural Search and LLMs, interview with Jo Kristian Bergum - Berlin Buzzwords 2023
Jo Kristian Bergum from the Vespa team joined Founder and CEO [Jakub Zavrel](https://www.linkedin.com/in/jakubzavrel/) 
at Zeta Alpha to talk about the state of Neural Search and LLMs. 

<iframe width="560" height="315" src="https://www.youtube.com/embed/vVhfgRS_IAo" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>
<p></p>

## Hybrid search is buzzing
This year, the conference was filled with talks on hybrid search and we think it's worthwile mentioning Lester Solbakken's great talk
from Berlin Buzzwords 2022 where he presented [Hybrid search > sum of its parts?](https://pretalx.com/bbuzz22/talk/YEHRTE/) 

<iframe width="560" height="315" src="https://www.youtube.com/embed/R5BLbnXPR5c" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
<p></p>

## Summary

Berlin Buzzwords is a highly regarded industry conference that brings together experts and professionals from various fields to discuss the latest trends and advancements in storage, processing, streaming, and search. One noticeable aspect of the 2023 edition was the significant emphasis on search-related topics, LLMs role in search, and neural hybrid search. 

If you are interested to learn more about Vespa; See [Vespa Cloud - getting started](https://cloud.vespa.ai/en/getting-started),
or self-serve [Vespa - getting started](https://docs.vespa.ai/en/getting-started.html). 
Got questions? Join the Vespa community in [Vespa Slack](http://slack.vespa.ai/).

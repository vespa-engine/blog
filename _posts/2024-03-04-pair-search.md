---  
layout: post
title: "The Singaporean government deploys state of the art semantic search"
author: bratseth
date: '2024-03-04'
image: assets/2024-03-04-pair-search/smart-search-made-simple.jpg
skipimage: true
image_credit: 'The Singapore Government <a href="https://hack.gov.sg/hack-for-public-good-2024/2024-projects/pairsearch/">Pair Search</a>'
tags: [semantic search, RAG]
excerpt: "The Singaporean government leverages Vespa to do semantic search in every word ever said in Parliament"
---
The Singaporean government has deployed Vespa to *search every word ever said in their Parliament*.

![pair search gui](/assets/2024-03-04-pair-search/A4_part.jpg)
<p class="image-credit inline">Credit: The Singapore Government <a href="https://hack.gov.sg/hack-for-public-good-2024/2024-projects/pairsearch/">Pair Search</a></p>

Why are systems like this so important?

> A good decision is an informed one.

and

> The heart of a good RAG system is a good search engine to retrieve the relevant data chunks for ingestion.

The combines both document and chunk level embeddings with text features into a single ranking to
achieve superior quality: 

![pair search process](/assets/2024-03-04-pair-search/process.jpg)
<p class="image-credit inline">Credit: The Singapore Government <a href="https://hack.gov.sg/hack-for-public-good-2024/2024-projects/pairsearch/">Pair Search</a></p>

Many teams are racing to make use of these new methods, but the Singaporean government 
may have been first to put them in production! Color us impressed. 

The blog post from the team contains lots of informative detail - read it 
<a href="https://hack.gov.sg/hack-for-public-good-2024/2024-projects/pairsearch/">here</a>.

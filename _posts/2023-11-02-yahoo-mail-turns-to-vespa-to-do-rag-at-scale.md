--- 
layout: post
title: "Yahoo Mail turns to Vespa to do RAG at scale"
author: bratseth
date: '2023-11-02'
image: assets/2023-11-02-yahoo-mail-turns-to-vespa-to-do-rag-at-scale/evgeni-tcherkasski.jpg
image_credit: 'Photo by <a href="https://unsplash.com/@evgenit?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Evgeni Tcherkasski</a> on <a href="https://unsplash.com/photos/red-and-black-bridge-over-water-XBJtNRyZUx4?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Unsplash</a>
'
skipimage: true
tags: [rag, vectors, streaming]
excerpt: Vespa is becoming its own company!
---

Yahoo Mail is one of the largest mail providers in the world. Now they’re also taking a shot at being the most 
innovative with their recent release of AI-driven features which lets you 
[ask questions of your mailbox](https://www.fastcompany.com/90945096/yahoo-unveils-an-ai-email-assistant-and-it-works-with-gmail)
and tell it to do things for you.

<video autoplay muted preload="auto">
  <source src="/assets/2023-11-02-yahoo-mail-turns-to-vespa-to-do-rag-at-scale/video2.mp4" type="video/mp4">
  Your browser does not support the video tag.
</video>

At the core of these features you find 1) a large language model which can understand and generate text, 
and 2) a retrieval system that finds the relevant information in your inbox to feed into this model, 
typically by a semantic search using vector embeddings. These two components together with the orchestration 
which combines them nowadays goes under the moniker RAG - Retrieval Augmented Generation.

We’re in the middle - or at the feeble start? - of a massive boom of this technology, and so there’s no 
lack of tools that allows you to build your own RAG demos. However, Yahoo’s aim is to make this work for all of 
their users while being so cost-effective that it can still be offered for free, and for this they have 
naturally turned to Vespa.ai. Vespa is the only vector database technology that:

- lets you implement a [cost-effective RAG system using personal data](https://blog.vespa.ai/announcing-vector-streaming-search/),
- support vector embeddings, structured data and full text in the same queries and ranking functions, and
- is proven to operate effectively, reliably storing and searching *trillions* of documents.

Making interaction with email an order of magnitude simpler and faster for this many people is a massively 
meaningful endeavor, and we’re excited to be helping the team as they build the new intelligent Yahoo Mail, 
and to see what features they’ll be adding next. To see for yourself, you can sign up at 
[Yahoo Mail levelup](https://overview.mail.yahoo.com/levelup), 
and if you want to build your own production scale RAG system, we recommend our fully open source 
[documentation search RAG application](https://github.com/vespa-cloud/vespa-documentation-search) as a starting point.

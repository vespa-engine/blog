---
layout: post
title: Open Sourcing Vespa, Yahoo’s Big Data Processing and Serving Engine
date: '2017-09-26T18:00:20-07:00'
tags: []
tumblr_url: https://blog.vespa.ai/post/165763618906/open-sourcing-vespa-yahoos-big-data-processing
---
_By Jon Bratseth, Distinguished Architect, Vespa_

Ever since we open sourced Hadoop in 2006, Yahoo – and now, Oath – has been committed to opening up its big data infrastructure to the larger developer community. Today, we are taking another major step in this direction by making [Vespa](http://vespa.ai), Yahoo’s big data processing and serving engine, available as open source on GitHub.

<figure class="tmblr-full" data-orig-height="370" data-orig-width="554" title="" style=""><img src="/assets/2017-09-26-open-sourcing-vespa-yahoos-big-data-processing/tumblr_inline_oww84watnX1s12bpj_540.png" data-orig-height="370" data-orig-width="554"></figure>

Building applications increasingly means dealing with huge amounts of data. While developers can use the Hadoop stack to store and batch process big data, and Storm to stream-process data, these technologies do not help with serving results to end users. Serving is challenging at large scale, especially when it is necessary to make computations quickly over data while a user is waiting, as with applications that feature search, recommendation, and personalization.

By releasing Vespa, we are making it easy for anyone to build applications that can compute responses to user requests, over large datasets, at real time and at internet scale – capabilities that up until now, have been within reach of only a few large companies.

Serving often involves more than looking up items by ID or computing a few numbers from a model. Many applications need to compute over large datasets at serving time. Two well-known examples are search and recommendation. To deliver a search result or a list of recommended articles to a user, you need to find all the items matching the query, determine how good each item is for the particular request using a relevance/recommendation model, organize the matches to remove duplicates, add navigation aids, and then return a response to the user. As these computations depend on features of the request, such as the user’s query or interests, it won’t do to compute the result upfront. It must be done at serving time, and since a user is waiting, it has to be done fast. Combining speedy completion of the aforementioned operations with the ability to perform them over large amounts of data requires a lot of infrastructure – distributed algorithms, data distribution and management, efficient data structures and memory management, and more. This is what Vespa provides in a neatly-packaged and easy to use engine.

With over 1 billion users, we currently use Vespa across many different Oath brands – including Yahoo.com, Yahoo News, Yahoo Sports, Yahoo Finance, Yahoo Gemini, Flickr, and others – to process and serve billions of daily requests over billions of documents while responding to search queries, making recommendations, and providing personalized content and advertisements, to name just a few use cases. In fact, Vespa processes and serves content and ads almost 90,000 times every second with latencies in the tens of milliseconds. On Flickr alone, Vespa performs keyword and image searches on the scale of a few hundred queries per second on tens of billions of images. Additionally, Vespa makes direct contributions to our company’s revenue stream by serving over 3 billion native ad requests per day via Yahoo Gemini, at a peak of 140k requests per second (per Oath internal data).

With Vespa, our teams build applications that:

- Select content items using SQL-like queries and text search  
- Organize all matches to generate data-driven pages  
- Rank matches by handwritten or machine-learned relevance models  
- Serve results with response times in the low milliseconds  
- Write data in real-time, thousands of times per second per node  
- Grow, shrink, and re-configure clusters while serving and writing data  

To achieve both speed and scale, Vespa distributes data and computation over many machines without any single master as a bottleneck. Where conventional applications work by pulling data into a stateless tier for processing, Vespa instead pushes computations to the data. This involves managing clusters of nodes with background redistribution of data in case of machine failures or the addition of new capacity, implementing distributed low latency query and processing algorithms, handling distributed data consistency, and a lot more. It’s a ton of hard work!

As the team behind Vespa, we have been working on developing search and serving capabilities ever since building alltheweb.com, which was later acquired by Yahoo. Over the last couple of years we have rewritten most of the engine from scratch to incorporate our experience onto a modern technology stack. Vespa is larger in scope and lines of code than any open source project we’ve ever released. Now that this has been battle-proven on Yahoo’s largest and most critical systems, we are pleased to release it to the world.

Vespa gives application developers the ability to feed data and models of any size to the serving system and make the final computations at request time. This often produces a better user experience at lower cost (for buying and running hardware) and complexity compared to pre-computing answers to requests. Furthermore it allows developers to work in a more interactive way where they navigate and interact with complex calculations in real time, rather than having to start offline jobs and check the results later.

Vespa can be run on premises or in the cloud. We provide both Docker images and rpm packages for Vespa, as well as guides for running them both on your own laptop or as an AWS cluster.

We’ll follow up this initial announcement with a series of posts on our [blog](http://blog.vespa.ai) showing how to build a real-world application with Vespa, but you can get started right now by following the [getting started guide](http://docs.vespa.ai/documentation/vespa-quick-start.html) in our comprehensive [documentation](http://docs.vespa.ai).

Managing distributed systems is not easy. We have worked hard to make it easy to develop and operate applications on Vespa so that you can focus on creating features that make use of the ability to compute over large datasets in real time, rather than the details of managing clusters and data. You should be able to get an application up and running in less than ten minutes by following the documentation.

We can’t wait to see what you’ll build with it!


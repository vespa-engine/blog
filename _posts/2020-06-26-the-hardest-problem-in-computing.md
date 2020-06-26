---
layout: post
title: The hardest problem in computing
date: '2020-06-26'
tags: []
excerpt: What is the hardest problem in applied computing? My bet is on big data serving — computing over large data sets online.
---

What is the hardest problem in applied computing? My bet is on _big data
serving_ &mdash; computing over large data sets _online_. It requires solving four
problems _at once_: Distributed state management, low latency computation with
stochastic load, high availability, and distributed computation, and all four
are known to be hard to solve separately.

![Decorative image](https://miro.medium.com/max/1000/1*oaBne7qoqqt7bTbaEha1rw.jpeg)
<p class="image-credit">Photo by
<a href="https://unsplash.com/@virussinside?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Artiom Vallat</a>
on <a href="https://unsplash.com/collections/3830666/vespa-blog-photos/ce50ee9e7cf7509dfc05b1544a700492?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a></p>

This is part three in a series of posts about big data serving. In the [first
post](https://blog.vespa.ai/the-big-data-maturity-levels/) we covered the
stages organizations advance through as they start putting their data to use.
In the [second post](https://blog.vespa.ai/why-most-computation-will-become-online/), 
we saw that moving computation online lets your systems make decisions with
up-to-date information and high precision at lower cost and complexity. In
this post we’ll look at the technological challenges that must be overcome to
achieve this, and see how they are solved in the first open source platform
available for this problem, [vespa.ai](https://vespa.ai/).


## Why big data serving is hard
In big data serving we’re computing over large data sets right at the moment
the computation is needed. A computation typically consists of finding the
right data items, evaluating machine-learned models over each item, and
organizing and aggregating the results.

As an example, consider a system making personalized recommendations of
movies, songs or articles, at the moment when a user shows up. To do this, you
need to find the items that should be considered for the situation at hand,
score each one using machine-learned personalization modeles, organize the
resulting recommendations by categories and similar, and return the necessary
data for display to the frontend or app.

Consider how to solve this problem efficiently. Can we solve it the usual way
server applications are implemented, by storing the items to be recommended in
a database and using stateless middle-tier to fetch data items to do the
processing and inference? If we have a 10Gbps (1.25GB/sec) network and each
item is 10kB large, we can evaluate max 125.000 movies per second. To achieve
an end-to-end response time which doesn’t annoy humans &mdash; about 400 ms &mdash; the
backend must typically respond in about 100 ms. This means we can scale to
evaluate at most 12.500 items in total per user request. Not good. But worse,
this uses _all_ the network capacity available! If we want to mostly return in
100 ms it means we can only handle 2–3 users per second _in total_, even with
this low number of items considered. Any more and we need to replicate the
entire database.

How can we do better? The obvious solution is to move the computation to the
data instead of the other way around. This is what systems such as Hadoop does
for batch computing, but those are not applicable here because they do not
provide low latency.

Therefore, to solve the big data serving problem, we need a _new kind of
system_. One which both stores all the data we are working with and is able to
compute locally where the data is stored, including making inferences in
machine-learned models.

## A new kind of system
That sounds like a lot of hard work, but we’re only getting started. To be
able to scale to more data than can be stored and computed over in time on a
single machine, we need distributed storage, and distributed algorithms
executing computation over multiple nodes in parallel to produce a response,
while still meeting latency requirements reliably. And since these systems are
online we need high availability, which translates to storing each piece of
data in multiple distributed copies, and automatically rebuilding copies
whenever nodes fail. To keep the data up to date with reality &mdash; one of the
goals of moving computation online &mdash; all of this must keep working while the
data is continuously modified. Further, to achieve high availability without
having redundant copies of the entire system, it must be possible to change
data schemas, logic, data layout, hardware and so on, without taking the
system offline at any time.

It’s not just solving all these problems, but _solving them so that they work
together_. Clearly, this is many man-years of work, and years of calendar time
regardless of the amount of money you are willing to spend, as accumulating
the practical detailed experience with what does and does not work just takes
time.

Building all this is out of the question for most applications, which is why
the advantages of computing online are so often left on the table.

## Web search to the rescue!
But are there any applications where the effort is economically justifiable?
Turns out there is one &mdash; _web search_.

Web search is the prototypical big data serving application: Computing over
big data sets (the web), including machine-learned model inference (relevance)
&mdash; and performing the computation offline is infeasible because there are just
too many queries to precompute them all. Furthermore, web search turned out to
be profitable enough to fund the kind of large multi-decade development
efforts required here.

The companies which funded their own web search technology have long since
started applying them to solve other problems important to them, such as
recommendation, personalization and targeting, but they have not made them
public.

## Vespa.ai

Luckily there is an exception to this. My team creates
[Vespa.ai](https://vespa.ai) &mdash; an engine solving the data serving
problem as open source. We first started working on this problem in the late
nineties as the web search engine alltheweb.com, competing with the other web
search engines such as Alta Vista back in those days. We were eventually
acquired by Yahoo! where we have been well funded ever since to work on
creating an ever better and more general big data serving engine. In 2017
[we were able to open source the platform](https://www.cnbc.com/2017/09/26/yahoo-open-sources-vespa-for-content-recommendations.html),
making big data serving a viable technology option for the wider world for the
first time.

About 700 man-years of development has gone into building Vespa so far, and
since we’ve been able to keep a stable core team of experts over many years,
most of that time has gone to improving it based on experience, instead of
continuously rebuilding pieces from scratch as the developers turn over &mdash; a
common problem often preventing progress on big and complex problems in the
industry.

Many companies have started using it to solve well-known big data serving
problems such as search and recommendation, but we’re also increasingly seeing
people using it in ingenious ways to solve problems that seem completely
different on the surface, but where there is an advantage to computing over
data with low latency. Looks like this will lead to a lot of new and
interesting solutions as people wrap their heads around the possibilities.

Enough for now, in the next and last post in this series, we’re finally set up
to dive into details on how Vespa solves the core problems in big data
serving.
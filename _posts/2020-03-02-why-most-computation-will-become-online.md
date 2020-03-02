---
layout: post
title: Why most computation will become online
date: '2020-03-02'
tags: []
---
In [the big data maturity levels](https://blog.vespa.ai/the-big-data-maturity-levels/) 
I wrote about how organizations progress from producing unused data, 
to doing analytics and learning *offline*, to eventually make decisions over data *online*, 
at the moment a decision is needed. *But why does this happen?*

![Decorative image](https://miro.medium.com/max/2893/1*12J8tZ0uiMGtX_y4Q3kvjA.jpeg)

Imagine you need to recommend movies to users, find the stocks most impacted by some event, 
or solve some other problem which involves computing over data. Solving such problems *offline* 
is safe and comfortable. You may need to deal with large amounts of data, but there are mature 
tools for that, and it’s ok to take your time making each computation, or even take the system 
down to make changes. Moving computations online on the other hand, exposes you to a whole world 
of new challenges. You need to complete computations with with low latency reliably, handle 
potentially large loads of concurrent computation and do this with high availability, 
including while changing the system.

How to overcome these challenges is the topic of my next post in this series, but first, 
given these challenges, why are the most advanced companies in the world still choosing to move 
so much of their computation online? It turns out doing so has four advantages that are important 
enough to make it worth the effort, once you are capable of doing it.

## 1. Decisions are up to date
First, by moving decisions online, you can make them with perfectly up to date information — 
both about the situation you are computing for, and the data used to make the computation.

For example, if you are computing movie recommendations for a user, you can take into account 
what the user has done right up to the moment you are making recommendations, include the most 
recent movies, and use the most recent data about the movies, such as which ones are trending right now.

## 2. No computation goes to waste
If you are computing offline you’re facing a problem: Since you don’t know yet which situations you 
need to handle online, you need to compute for all of them. To limit the staleness of your decisions 
you’ll also need to recompute them periodically. This means that much of the computation you are 
doing ends up being wasted, as many situations won’t occur until your next offline computation cycle.

For example when recommending movies, you’ll need to compute recommendations for every single user 
you know about, even though most of them won’t actually show up to see those recommendations until 
you recompute them.

## 3. High fidelity decisions
When computing offline, due to the problem of wasted computation, you need to limit how many different 
decisions you make. This usually means you need to view the world as somewhat blurry, such that many 
different situations appear the same and are covered by the same computation. When recommending movies 
offline, you won’t actually compute recommendations for every individual user as that is too costly. 
Instead you place each user in a smaller set of groups — say “young sci-fi and action fans” and compute 
recommendations for those.

When computing online on the other hand, you can use every bit of information about the concrete situation 
at hand, since you are making a unique one-off computation in any case. This obviously leads to better 
decisions. When recommending movies for example, you don’t need to stereotype users but can recommend 
based on the precise interests of each user.

## 4. Architectural simplicity
Computing offline is in itself often quite manageable — the batch computations are done within a single 
subsystem (such as Hadoop). However, you also need other subsystems to create a complete solution. 
You need to ship all the computed data to the serving system, and use a serving store to store and serve it. 
Since the computations are made in bulk you need capacity to handle the load peaks caused by replacing the 
data while serving, or else a more complicated solution to smooth the data replacement over time. Bucket 
testing computation variants becomes complex and time-consuming since you’ll need to ship and store separate 
data to cover each variant. To compensate for the staleness of offline computing it is also common to add 
auxiliary subsystems that try to compensate by looking at changes since the last offline computation to 
amend the results, which further complicates the full solution.

In contrast, computing at serving time is challenging to be sure, but once you have a subsystem that can 
do it — such that you can treat it more or less like a black box, the rest of your architecture becomes 
much simpler. All you need to do is to send a constant stream of writes to this box to keep it up to date 
about what it needs to know about the world, and issue queries specifying each real-time computation you 
want it to make. If you want to bucket test some variant of the computation all you need to do is to send 
different queries.

## When should you compute online?
These four advantages are general but not equally important in all cases. Some things do not make any sense 
to do offline at all. One example is *web search*, where you need to find documents that contains the relevant 
text and score them by some machine learned relevance model. Since there are so many potential queries users 
can make it is not possible to precompute the answer to every one (Google says 15% of the queries they see 
are still new to them), and reducing fidelity by computing the same result to many similar queries does not 
seem very useful. In fact, web search financed the development of the technologies that makes it possible 
to compute over big data online (more on that in a later post).

In many other cases however, it is possible to create working solutions both using offline and online 
computation, and it’s more a question of what quality you are capable of achieving. Moving computation 
online is more important when there is a larger advantage to being up to date, or to making decisions 
with high fidelity. It may also be advantageous when you start to notice that your architectural complexity, 
or friction in running experiments, is slowing you down.

It used to be the case that only the most advanced internet companies with the largest development budgets 
were able to create solutions where computation over big data is done online, and even in those companies 
it would only be applied in certain use cases such as web search or ad serving. This has changed somewhat 
with the open sourcing of the [vespa.ai](https://vespa.ai) platform which makes this technology broadly 
available. One thing I expect to see over the next few years is a much broader application of these kinds 
of solutions, as companies take advantage of the ability to move computation online to gain a competitive 
edge.

I hope this post has been informative. In the next in this series I’ll dive into the reasons it is so 
challenging to create technology capable of computing over big data online.
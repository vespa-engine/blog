---
layout: post
title: 'Vespa use case: shopping'
date: '2019-05-03T11:00:22-07:00'
tags: []
tumblr_url: https://blog.vespa.ai/post/184617258876/vespa-use-case-shopping
---
Imagine you are tasked with creating a shopping website. How would you proceed? What tools and technologies would you choose? You need a technology that allows you to create data-driven navigational views as well as search and recommend products. It should be really fast, and able to scale easily as your site grows, both in number of visitors and products. And because good search relevance and product recommendation drives sales, it should be possible to use advanced features such as machine-learned ranking to implement such features.

[Vespa](https://vespa.ai) - the open source big data serving engine - allows you to implement all these use cases in a single backend. As it &nbsp;is a general engine for low latency computation it can be hard to know where to start. To help with that, we have provided a detailed [shopping use case with a sample application](https://docs.vespa.ai/en/use-case-shopping.html).

This sample application contains a fully-functional shopping-like front-end with reasonably advanced functionality right out of the box, including sample data. While this is an example of a searchable product catalog, with customization it could be used for other application types as well, such as video and social sites.

The features highlighted in this use case are:

- **Grouping** - used for instance in search to aggregate the results of the query into categories, brands, item ratings and price ranges.
- **Partial update** - used in liking product reviews.
- **Custom document processors** - used to intercept the feeding of product reviews to update the product itself.
- **Custom handlers and configuration** - used to power the front-end of the site.
<figure data-orig-width="800" data-orig-height="536" class="tmblr-full"><img src="/assets/2019-05-03-vespa-use-case-shopping/tumblr_inline_pqx7jklznw1vpfrlb_540.png" alt="image" data-orig-width="800" data-orig-height="536"></figure>

The goal with this is to start a new series of example applications that each showcase different features of Vespa, and show them in context of practical applications. The use cases can be used as starting points for new applications, as they contain fully-functional Vespa application packages, including sample data for getting started quickly.

<figure data-orig-width="797" data-orig-height="671" class="tmblr-full"><img src="/assets/2019-05-03-vespa-use-case-shopping/tumblr_inline_pqx7k9mhgS1vpfrlb_540.png" alt="image" data-orig-width="797" data-orig-height="671"></figure>

The use cases come in addition to the quick start guide, which gives a very basic introduction to get up and running with Vespa, and the tutorial which is much more in-depth. With the use case series we want to fill the gap between these two with something closer to the practical problems user want to solve with Vespa.

Take a look for yourself. More information can be found at [https://docs.vespa.ai/en/use-case-shopping.html](https://docs.vespa.ai/en/use-case-shopping.html)


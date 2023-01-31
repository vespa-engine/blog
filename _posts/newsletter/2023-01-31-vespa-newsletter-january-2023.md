---
layout: post
title: Vespa Newsletter, January 2023
author: kkraune
date: '2023-01-31'
categories: [newsletter]
image: assets/images/scott-graham-5fNmWej4tAA-unsplash.jpg
skipimage: true
tags: [big data serving, big data, search engines, search, database]
index: false
excerpt: >
    Advances in Vespa features and performance include Better Tensor formats,
    AWS PrivateLink, Autoscaling, Data Plane Access Control and Container and Content Node Performance.
---

It's a busy winter at the Vespa HQ. We are working on some major new features, which will be announced soon, but we're also finding the time to make smaller improvements - see below!


### Interested in search ranking? Don't miss these blog posts
We have done some deep diving into using machine learning to improve ranking in search applications lately,
and of course, we're blogging and open-sourcing all the details to make it easy for you to build on what we are doing.
See these recent blog posts:
* [Improving product search with learning to rank]({% post_url /2022-12-05-improving-product-search-with-ltr-part-three %}).
* Improving zero-shot ranking with Vespa hybrid search:
  [Part 1]({% post_url /2023-01-06-improving-zero-shot-ranking-with-vespa %}) and
  [part 2]({% post_url /2023-01-10-improving-zero-shot-ranking-with-vespa-part-two %}).



### New Vespa improvements
In the [previous update]({% post_url /newsletter/2022-11-30-vespa-newsletter-november-2022 %}),
we mentioned ANN pre-filter performance, parent field hit estimates,
model training notebooks, and Vespa Cloud GCP Support.
This time, we have the following improvements:


### Simpler tensor JSON format
Since Vespa 8.111, Vespa allows tensor field values to be written in JSON
without the intermediate map containing "blocks", "cells" or "values".
The tensor type will then dictate the format of the tensor content.
Tensors can also be returned in this format in
[queries](https://docs.vespa.ai/en/reference/query-api-reference.html#presentation.format.tensors),
[document/v1](https://docs.vespa.ai/en/reference/document-v1-api-reference.html#format.tensors),
and [model evaluation](https://docs.vespa.ai/en/stateless-model-evaluation.html#format.tensors)
by requesting the format short-value -
see the [tensor format documentation](https://docs.vespa.ai/en/reference/document-json-format.html#tensor).



### Supplying values for missing fields during indexing
Vespa allows you to add fields outside the "document" section in the schema configuration
that get their values from fields in the document.
For example, you can add a vector embedding of a title and description field like this:

    field myEmbedding type tensor(x[128]) {
        indexing: input title . " " . input description | embed | attribute
    }

But what if descriptions are sometimes missing?
Then Vespa won't produce an embedding value at all, which may not be what you want.
From 8.116, you can specify an alternative value for expressions that don't produce a value
using the [|| syntax](https://docs.vespa.ai/en/reference/advanced-indexing-language.html#choice-example):

    field myEmbedding type tensor(x[128]) {
        indexing: input title . " " . (input description || "") | embed | attribute
    }



### AWS PrivateLink in Vespa Cloud
Since January 31, it is possible to set up private connectivity between a customer's VPC
and their Vespa Cloud application using [AWS PrivateLink](https://aws.amazon.com/privatelink/).
This provides clients safe, non-public access to their applications
using private IPs accessible from within their own VPCs -
[read more](https://cloud.vespa.ai/en/private-endpoints.html).



### Content node performance
Vespa content nodes store the data written to Vespa, maintain indexes over it, and run matching and ranking.
Most applications spend the majority of their hardware resources on content nodes.
* Improving query performance is made easier with new match phase profiling
  [trace.profiling.matching.depth](https://docs.vespa.ai/en/reference/query-api-reference.html#trace.profiling.matching.depth)
  since Vespa 8.114. This gives insight into what's most costly in matching your queries (ranking was already supported).
  Read more at [phased-ranking.html](https://docs.vespa.ai/en/phased-ranking.html).
* Since Vespa 8.116, Vespa requires minimum
 [Haswell microarchitecture](https://en.wikipedia.org/wiki/Haswell_(microarchitecture)).
  A more recent optimization target enables better optimizations and, in some cases, gives 10-15% better ranking performance.
  It is still possible to run on older microarchitectures, but then you must compile from source;
  see [#25693](https://github.com/vespa-engine/vespa/pull/25693).



### Vespa start and stop script improvements
Vespa runs in many environments, from various self-hosted technology stacks to Vespa Cloud -
see [multinode-systems](https://docs.vespa.ai/en/operations/multinode-systems.html)
and [basic-search-on-gke](https://github.com/vespa-engine/sample-apps/tree/master/examples/operations/basic-search-on-gke/).
To support running root-less in containers with better debug support,
the vespa start/stop-scripts are now refactored and simplified -
this will also make Vespa start/stop snappier in some cases.



### Container Performance and Security
With Vespa 8.111, Vespa upgraded its embedded [Jetty server](https://www.eclipse.org/jetty/) from version 9.x to 11.0.13.
The upgrade increases performance in some use cases, mainly when using HTTP/2,
and also includes several security fixes provided with the Jetty upgrade.



### Log settings in services.xml
During debugging, it is useful to be able to tune which messages end up in the log,
especially when [developing custom components](https://docs.vespa.ai/en/developer-guide.html).
This can be done with the [vespa-logctl](https://docs.vespa.ai/en/reference/vespa-cmdline-tools.html#vespa-logctl) tool on each node.
Since Vespa 8.100, you can also control log settings in services.xml -
see [logging](https://docs.vespa.ai/en/reference/services-admin.html#logging).
This is also very convenient when deploying on [Vespa Cloud](https://cloud.vespa.ai/).



### Vespa Cloud: Autoscaling with multiple groups
When allocating resources on [Vespa Cloud](https://cloud.vespa.ai/)
you can specify both the number of nodes and node groups you want in content clusters
(each group has one or more complete copies of all the data and can handle a query independently):

    <nodes count="20" groups="2">

If you want the system to automatically find the best values for the given load, you can configure ranges:

    <nodes count="[10, 30]" groups="[1, 3]">

This might lead to groups of sizes from 4 to 30, which may be fine,
but sometimes you want to control the size of groups instead?
From 8.116, you can configure group size instead (or in addition to) the number of groups:

    <nodes count="[10, 30]" group-size="10">

Like the other values, group-size can also be ranges.
See the [documentation](https://cloud.vespa.ai/en/reference/services#nodes).

In addition to choosing resources, a content cluster must also be configured with a redundancy -
the number of copies to keep of each piece of data in each group.
With variable groups this may cause you to have more copies than you strictly need to avoid data loss,
so since 8.116, you can instead configure the [_minimum_ redundancy](https://cloud.vespa.ai/en/reference/services#redundancy):

    <min-redundancy>2</min-redundancy>

The system will then ensure you have at least this many copies of the data,
but not make more copies than necessary in each group.



### Vespa Cloud: Separate read/write data plane access control
When configuring the client certificate to use for your incoming requests (data plane) on [Vespa Cloud](https://cloud.vespa.ai/),
you can now specify whether each certificate should have read- or write-access or both.
This allows you to e.g., use one certificate for clients with read access while having another –
perhaps less distributed – certificate for write access.
See the [Security Guide](https://cloud.vespa.ai/en/security/guide#data-plane-access-control-permissions)
for more details on how to configure it.


Thanks for reading! Try out Vespa on [Vespa Cloud](https://cloud.vespa.ai/)
or grab the latest release at [https://vespa.ai/releases](https://vespa.ai/releases) and run it yourself! &#x1F600;

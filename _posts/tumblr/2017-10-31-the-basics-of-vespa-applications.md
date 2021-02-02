---
layout: post
title: The basics of Vespa applications
date: '2017-10-31T13:00:06-07:00'
tags: []
tumblr_url: https://blog.vespa.ai/post/166978538586/the-basics-of-vespa-applications
---
Distributed computation over large data sets in real-time — what we call big data serving — is a complex task. We have worked hard to hide this complexity to make it as easy as possible to create your own production quality Vespa application. The [quick](https://docs.vespa.ai/en/vespa-quick-start.html) [start](https://docs.vespa.ai/en/vespa-quick-start-centos.html) [guides](https://docs.vespa.ai/en/vespa-quick-start-windows.html) take you through the steps of getting Vespa up and running, deploying a basic application, writing data and issuing some queries to it, but without room for explanation. Here, we’ll explain the basics of creating your own Vespa application. The&nbsp;[blog search and recommendation tutorial](https://docs.vespa.ai/en/tutorials/blog-search.html) covers these topics in full detail with hands-on instructions.

## Application packages

The configuration, components and models which makes out an application to be run by Vespa is contained in an [application package](https://docs.vespa.ai/en/cloudconfig/application-packages.html). The application package:

- Defines which clusters and services should run and how they should be configured
- Contains the document types the application will use
- Contains the ranking models to execute
- Configures how data will be processed during feeding and indexing
- Configures how queries will be pre- and post-processed  

The three mandatory parts of the application specification are the [search definition](https://docs.vespa.ai/en/search-definitions.html), the [services specification](https://docs.vespa.ai/en/reference/services.html), and the [hosts specification](https://docs.vespa.ai/en/reference/hosts.html) — all of which have their own file in the application package. This is enough to set up a basic production ready Vespa applications, like, e.g., the [basic-search](https://github.com/vespa-engine/sample-apps/tree/master/basic-search) [sample application](https://github.com/vespa-engine/sample-apps/tree/master). Most applications however, are much larger and may contain machine-learned ranking models and application specific Java components which perform various application specific tasks such as query enrichment and post-search processing.

**The search definition**

Data stored in Vespa is represented as a set of documents of a type defined in the application package. An application can have multiple document types. Each [search definition](https://docs.vespa.ai/en/search-definitions.html)&nbsp;describes one such document type: it lists the name and data type of each field found in the document, and configures the behaviour of these. Examples are like whether field values are in-memory or can be stored on disk, and whether they should be indexed or not. It can also contain ranking profiles, which are used to select the most relevant documents among the set of matches for a given query - and it specifies which fields to return.

**The services definition**

A Vespa application consists of a set of services, such as stateless query and document processing containers and stateful content clusters. Which services to run, where to run those services and the configuration of those services are all set up in services.xml. This includes the search endpoint(s), the document feeding API, the content cluster, and how documents are stored and searched.

**The hosts definition**

The deployment specification hosts.xml contains a list of all hosts that is part of the application, with an alias for each of them. The aliases are used in services.xml to define which services is to be started on which nodes.

## Deploying applications

After the application package has been constructed, it is deployed using&nbsp;[vespa-deploy](https://docs.vespa.ai/en/cloudconfig/application-packages.html#deploy). This uploads the package to the [configuration cluster](https://docs.vespa.ai/en/cloudconfig/config-introduction.html) and pushes the configuration to all nodes. After this, the Vespa cluster is now configured and ready for use.

One of the nice features is that new configurations are loaded without service disruption. When a new application package is deployed, the configuration pushes the new generation to all the defined nodes in the application, which consume and effectuate the new configuration without restarting the services. There are some rare cases that require a restart, the vespa-deploy command will notify when this is needed.

## Writing data to Vespa

One of the required files when setting up a Vespa application is the search definition. This file (or files) contains a document definition which defines the fields and their data types for each document type. Data is written to Vespa using Vespa’s JSON document format. The data in this format must match the search definition for the document type.

The process of writing data to Vespa is called feeding, and there are [multiple tools](https://docs.vespa.ai/en/writing-to-vespa.html) that can be used to feed data to Vespa for various use cases. For instance there is a REST API for smaller updates and a Java client that can be embedded into other applications.

An important concept in writing data to Vespa is that of [document processors](https://docs.vespa.ai/en/document-processing-overview.html). These processors can be chained together to form a processing pipeline to process each document before indexing. This is useful for many use cases, including enrichment by pulling in relevant data from other sources.

## Querying Vespa

If you know the id of the document you want, you can fetch it directly using the document API. However, with Vespa you are usually more interested in searching for relevant documents given some query.

Basic querying in Vespa is done through [YQL](https://docs.vespa.ai/en/query-language.html) which is an SQL-like language. An example is:

> _select title,isbn from music where artist contains “kygo”;_

Here we select the fields “title” and “isbn” from document type “music” where the field called “artist” contains the string “kygo”. Wildcards (\*) are supported in the result fields and the document types to return all available fields in all defined document types.

The example above shows how to send a query to Vespa over HTTP. Many applications choose to build the queries in Java components running inside Vespa instead. Such components are called [searchers](https://docs.vespa.ai/en/searcher-development.html), and can be used to build or modify queries, run multiple queries for each incoming request and filter and modify results. Similar to the document processor chains, you can set up chains of searchers. Vespa contains a set of default Searchers which does various common operations such as stemming and federation to multiple content clusters.

## Ranking models

[Ranking](https://docs.vespa.ai/en/ranking.html) executes a ranking expression specified in the search definition on all the documents matching a query. When returning specific documents for a query, those with the highest rank score are returned.

A ranking expression is a mathematical function over features (named values).

Features are either sent with the query, attributes of the document, constants in the application package or features computed by Vespa from both the query and document - example:

> _rank-profile popularity inherits default {  
> &nbsp; &nbsp; first-phase {  
> &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;expression: 0.7 \* nativeRank(title, description) +&nbsp;  
> &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; 0.3 \* attribute(popularity)  
> &nbsp; &nbsp; }  
> }_

Here, each document is ranked by the [nativeRank](https://docs.vespa.ai/en/reference/nativerank.html) function but boosted by a popularity score. This score can be updated at regular intervals, for instance from user feedback, using partial document updates from some external system such as a Hadoop cluster.

In real applications ranking expressions often get much more complicated than this.

For example, a recommendation application may use a deep neural net to compute a recommendation score, or a search application may use a machine-learned gradient boosted decision tree. To support such complex models, Vespa allows ranking expressions to compute over [tensors](https://docs.vespa.ai/en/tensor-intro.html) in addition to scalars. This makes it possible to work effectively with large models and parameter spaces.

As complex ranking models can be expensive to compute over many documents, it is often a good idea to use a cheaper function to find good candidates and then rank only those using the full model. To do this you can configure both a first-phase and second-phase ranking expression, where the second-phase function is only computed on the best candidate documents.

## Grouping and aggregation

In addition to returning the set of results ordered by a relevance score, Vespa can [group and aggregate](https://docs.vespa.ai/en/grouping.html) data over all the documents selected by a query. Common use cases include:

- Group documents by unique value of some field.
- Group documents by time and date, for instance sort bug tickets by date of creation into the buckets Today, Past Week, Past Month, Past Year, and Everything else.
- Calculate the minimum/maximum/average value for a given field.

Groups can be nested arbitrarily and multiple groupings and aggregations can be executed in the same query.

## More information

You should now have a basic understanding of the core concepts in building Vespa applications. To try out these core features in practice, head on over to the [blog search and recommendation tutorial](https://docs.vespa.ai/en/tutorials/blog-search.html). We’ll post some more in-depth blog posts with concrete examples soon.

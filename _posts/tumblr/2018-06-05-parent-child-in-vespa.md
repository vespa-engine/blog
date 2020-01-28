---
layout: post
title: Parent-child in Vespa
date: '2018-06-05T08:00:43-07:00'
tags: []
tumblr_url: https://blog.vespa.ai/post/174589826190/parent-child-in-vespa
---
Parent-child relationships let you model hierarchical relations in your data. This blog post talks about why and how we added this feature to Vespa, and how you can use it in your own applications. We’ll show some performance numbers and discuss practical considerations.

## Introduction

**The shortest possible background**

Traditional relational databases let you perform _joins_ between tables. Joins enable efficient normalization of data through foreign keys, which means any distinct piece of information can be stored in one place and then _referred_ to (often transitively), rather than to be duplicated everywhere it might be needed. This makes relational databases an excellent fit for a great number of applications.

However, if we require scalable, real-time data processing with millisecond latency our options become more limited. To see why, and to investigate how parent-child can help us, we’ll consider a hypothetical use case.

**A grand business idea**

Let’s assume we’re building a disruptive startup for serving the cutest possible cat picture advertisements imaginable. Advertisers will run multiple campaigns, each with their own set of ads. Since they will (of course) pay us for this privilege, campaigns will have an associated budget which we have to manage at serving time. In particular, we don’t want to serve ads for a campaign that has spent all its money, as that would be free advertising. We must also ensure that campaign budgets are frequently updated when their ads have been served.

Our initial, relational data model might look like this:

     Advertiser: id: (primary key) company\_name: string contact\_person\_email: string Campaign: id: (primary key) advertiser\_id: (foreign key to _advertiser.id_) name: string budget: int Ad: id: (primary key) campaign\_id: (foreign key to _campaign.id_) cuteness: float cat\_picture\_url: string 

This data normalization lets us easily update the budgets for all ads in a single operation, which is important since we don’t want to serve ads for which there is no budget. We can also get the advertiser name for all individual ads transitively via their campaign.

**Scaling our expectations**

Since we’re expecting our startup to rapidly grow to a massive size, we want to make sure we can scale from day one. As the number of ad queries grow, we ideally want scaling up to be as simple as adding more server capacity.

Unfortunately, scaling joins beyond a single server is a significant design and engineering challenge. As a consequence, most of the new data stores released in the past decade have been of the “NoSQL” variant (which might also be called “non-relational databases”). NoSQL’s horizontal scalability is usually achieved by requiring an application developer to explicitly de-normalize all data. This removes the need for joins altogether. For our use case, we have to store budget and advertiser name across multiple document types and instances (duplicated data here marked with bold text):

     Advertiser: id: (primary key) company\_name: string contact\_person\_email: string Campaign: id: (primary key) **advertiser\_company\_name** : string name: string budget: int Ad: id: (primary key) **campaign\_budget** : int **campaign\_advertiser\_company\_name** : string cuteness: float cat\_picture\_url: string 

Now we can scale horizontally for queries, but updating the budget of a campaign requires updating all its ads. This turns an otherwise _O(1)_ operation into _O(n)_, and we likely have to implement this update logic ourselves as part of our application. We’ll be expecting thousands of budget updates to our cat ad campaigns per second. Multiplying this by an unknown number is likely to overload our servers or lose us money. Or both at the same time.

**A pragmatic middle ground**

In the middle between these two extremes of “arbitrary joins” and “no joins at all” we have _parent-child relationships_. These enable a subset of join functionality, but with enough restrictions that they can be implemented efficiently at scale. One core restriction is that your data relationships must be possible to represented as a directed, acyclic graph (DAG).

As it happens, this is the case with our cat picture advertisement use case; _Advertiser_ is a parent to 0-n _Campaign_s, each of which in turn is a parent to 0-n _Ad_s. Being able to represent this natively in our application would get us functionally very close to the original, relational schema.

We’ll see very shortly how this can be directly mapped to Vespa’s parent-child feature support.

## Parent-child support in Vespa

**Creating the data model**

Vespa’s fundamental data model is that of _documents_. Each document belongs to a particular schema and has a user-provided unique identifier. Such a schema is known as a document type and is specified in a [search definition](http://docs.vespa.ai/documentation/search-definitions.html) file. A document may have an arbitrary number of fields of different types. Some of these may be indexed, some may be kept in memory, all depending on the schema. A Vespa application may contain many document types.

Here’s how the Vespa equivalent of the above _denormalized_ schema could look (again bolding where we’re duplicating information):

    _advertiser.sd:_ search advertiser { document advertiser { field company\_name type string { indexing: attribute | summary } field contact\_person\_email type string { indexing: summary } } } _campaign.sd:_ search campaign { document campaign { **field advertiser\_company\_name type string { indexing: attribute | summary }** field name type string { indexing: attribute | summary } field budget type int { indexing: attribute | summary } } } _ad.sd:_ search ad { document ad { **field campaign\_budget type int { indexing: attribute | summary attribute: fast-search } field campaign\_advertiser\_company\_name type string { indexing: attribute | summary }** field cuteness type float { indexing: attribute | summary attribute: fast-search } field cat\_picture\_url type string { indexing: attribute | summary } } }

Note that since all documents in Vespa must already have a unique ID, we do not need to model the primary key IDs explicitly.

We’ll now see how little it takes to change this to its normalized equivalent by using parent-child.

Parent-child support adds two new types of declared fields to Vespa; _references_ and _imported fields_.

A _reference field_ contains the unique identifier of a parent document of a given document type. It is analogous to a foreign key in a relational database, or a pointer in Java/C++. A document may contain many reference fields, with each potentially referencing entirely different documents.

We want each ad to reference its parent campaign, so we add the following to `ad.sd`:

     field campaign\_ref type reference\<campaign\> { indexing: attribute } 

We also add a reference from a campaign to its advertiser in `campaign.sd`:

     field advertiser\_ref type reference\<advertiser\> { indexing: attribute } 

Since a reference just points to a particular document, it cannot be directly used in queries. Instead, _imported fields_ are used to access a particular field within a referenced document. Imported fields are _virtual_; they do not take up any space in the document itself and they cannot be directly written to by put or update operations.

Add to `search campaign` in `campaign.sd`:

     import field advertiser\_ref.company\_name as campaign\_company\_name {} 

Add to `search ad` in `ad.sd`:

     import field campaign\_ref.budget as ad\_campaign\_budget {} 

You can import a parent field which itself is an imported field. This enables transitive field lookups.

Add to `search ad` in `ad.sd`:

     import field campaign\_ref.campaign\_company\_name as ad\_campaign\_company\_name {} 

After removing the now redundant fields, our _normalized_ schema looks like this:

    _advertiser.sd:_ search advertiser { document advertiser { field company\_name type string { indexing: attribute | summary } field contact\_person\_email type string { indexing: summary } } } _campaign.sd:_ search campaign { document campaign { field advertiser\_ref type _reference\<advertiser\>_ { indexing: attribute } field name type string { indexing: attribute | summary } field budget type int { indexing: attribute | summary } } import field advertiser\_ref.company\_name as campaign\_company\_name {} } _ad.sd:_ search ad { document ad { field campaign\_ref type _reference\<campaign\>_ { indexing: attribute } field cuteness type float { indexing: attribute | summary attribute: fast-search } field cat\_picture\_url type string { indexing: attribute | summary } } import field campaign\_ref.budget as ad\_campaign\_budget {} import field campaign\_ref.campaign\_company\_name as ad\_campaign\_company\_name {} }

**Feeding with references**

When feeding documents to Vespa, references are assigned like any other string field:

     [{ "put": "id:test:advertiser::acme", "fields": { “company\_name”: “ACME Inc. cats and rocket equipment”, “contact\_person\_email”: “wile-e@example.com” } }, { "put": "id:acme:campaign::catnip", "fields": { **“advertiser\_ref”: “id:test:advertiser::acme”** , “name”: “Most excellent catnip deals”, “budget”: 500 } }, { "put": "id:acme:ad::1", "fields": { **"campaign\_ref": "id:acme:campaign::catnip"** , “cuteness”: 100.0, “cat\_picture\_url”: “/acme/super\_cute.jpg” }] 

We can efficiently update the budget of a single campaign, immediately affecting all its child ads:

     [{ "update": "id:test:campaign::catnip", "fields": { "budget": { "assign": 450 } } }] 

**Querying using imported fields**

You can use imported fields in queries as if they were a regular field. Here are some examples using [YQL](http://docs.vespa.ai/documentation/query-language.html):

Find all ads that still have a budget left in their campaign:

     select \* from ad where ad\_campaign\_budget \> 0; 

Find all ads that have less than $500 left in their budget and belong to an advertiser whose company name contains the word “ACME”:

     select \* from ad where ad\_campaign\_budget \< 500 and ad\_campaign\_company\_name contains “ACME”; 

Note that imported fields are not part of the default [document summary](http://docs.vespa.ai/documentation/document-summaries.html), so you must add them explicitly to a separate summary if you want their values returned as part of a query result:

     document-summary my\_ad\_summary { summary ad\_campaign\_budget type int {} summary ad\_campaign\_company\_name type string {} summary cuteness type float {} summary cat\_picture\_url type string {} } 

Add `summary=my_ad_summary` as a query HTTP request parameter to use it.

**Global documents**

One of the primary reasons why distributed, generalized joins are so hard to do well efficiently is that performing a join on node A might require looking at data that is only found on node B (or node C, or D…). Vespa gets around this problem by requiring that all documents that may be joined against are _always present on every single node_. This is achieved by marking parent documents as _global_ in the `services.xml` declaration. Global documents are automatically distributed to all nodes in the cluster. In our use case, both advertisers and campaigns are used as parents:

     \<documents\> \<document mode="index" type="advertiser" global=”true”/\> \<document mode="index" type="campaign" global=”true”/\> \<document mode="index" type="ad"/\> \</documents\> 

You cannot deploy an application containing reference fields pointing to non-global document types. Vespa verifies this at deployment time.

## Performance

**Feeding of campaign budget updates**

Scenario: feed 2 million ad documents 4 times to a content cluster with one node, each time with a different ratio between ads and parent campaigns. Treat 1:1 as baseline (i.e. 2 million ads, 2 million campaigns). Measure relative speedup as the ratio of how many fewer campaigns must be fed to update the budget in all ads.

**Results**

- 1 ad per campaign: 35000 campaign puts/second
- 10 ads per campaign: 29000 campaign puts/second, **8.2x relative speedup**
- 100 ads per campaign: 19000 campaign puts/second, **54x relative speedup**
- 1000 ads percampaign: 6200 campaign puts/second, **177x relative speedup**

Note that there is some cost associated with higher fan-outs due to internal management of parent-child mappings, so the speedup is not linear with the fan-out.

**Searching on ads based on campaign budgets**

Scenario: we want to search for all ads having a specific budget value. First measure with all ad budgets denormalized, then using an imported budget field from the ads’ referenced campaign documents. As with the feeding benchmark, we’ll use 1, 10, 100 and 1000 ads per campaign with a total of 2 million ads combined across all campaigns. Measure average latency over 5 runs.

In each case, the budget attribute is declared as `fast-search`, which means it has a B-tree index. This allows for efficent value and range searches.

**Results**

- 1 ad per campaign: denormalized 0.742 ms, imported 0.818 ms, **10.2% slowdown**
- 10 ads per campaign: denormalized 0.986 ms, imported 1.186 ms, **20.2% slowdown**
- 100 ads per campaign: denormalized 0.830 ms, imported 0.958 ms, **15.4% slowdown**
- 1000 ads per campaign: denormalized 0.936 ms, imported 0.922 ms, **1.5% speedup**

The observed _speedup_ for the biggest fan-out is likely an artifact of measurement noise.

We can see that although there is generally some cost associated with the extra indirection, it is dwarfed by the speedup we get at feeding time.

## Practical concerns

Although a powerful feature, parent-child does not make sense for every use case.

Prefer to use parent-child if the relationships between your data items can be _naturally_ represented with such a hierarchy. The 3-level ad → campaign → advertiser example we’ve covered is such a use case.

Parent-child is limited to DAG relations and therefore can’t be used to model an arbitrary graph.

Parent-child in Vespa is currently only useful when searching in _child_ documents. Queries can follow references from children to parents, but can’t go from parents to children. This is due to how Vespa maintains its internal reference mappings.

You **CAN** search for

- “All campaigns with advertiser name X” (campaign → advertiser)
- “All ads with a campaign whose budget is greater than X” (ad → campaign)
- “All ads with advertiser name X” (ad → campaign → advertiser, via transitive import)

You **CAN’T** search for

- “All advertisers with campaigns that have a budget greater than X” (campaign ← advertiser)
- “All campaigns that have more than N ads” (ad ← campaign)

Parent-child references do not enforce referential integrity constraints. You can feed a child document containing a reference to a parent document that does not exist. Note that you can feed the missing parent document later. Vespa will automatically resolve references from existing child documents.

A lot of work has gone into minimizing the performance impact of using imported fields, but there is still some performance penalty introduced by the parent-child indirection. This means that using a denormalized data model may still be faster at search time, while a normalized parent-child model will generally be faster to feed. You must determine what you expect to be the bottleneck in your application and perform benchmarks for your particular use case.

There is a fixed per-document memory cost associated with maintaining the internal parent-child mappings.

Fields that are imported from a parent must be declared as `attribute` in the parent document type.

As mentioned in the Global documents section, all parent documents must be present on all nodes. This is one of the biggest caveats with the parent-child feature: _all_ nodes must have sufficient capacity for _all_ parents. A core assumption that we have made for the use of this feature is the number of parent documents is much lower than the number of child documents. At least an order of magnitude fewer documents per parent level is a reasonable heuristic.

## Comparisons with other systems

**ElasticSearch**

ElasticSearch also offers native support for parent-child in its data and query model. There are some distinct differences:

- In ElasticSearch it’s the user’s responsibility to ensure child documents are explicitly placed on the same shard as its parents ([source](https://www.elastic.co/guide/en/elasticsearch/guide/2.x/indexing-parent-child.html#indexing-parent-child)). This trades off ease of use with not requiring all parents on all nodes.
- Changing a parent reference in ElasticSearch requires a manual delete of the child before it can be reinserted in the new parent shard ([source](https://www.elastic.co/guide/en/elasticsearch/guide/2.x/indexing-parent-child.html#indexing-parent-child)). Parent references in Vespa can be changed with ordinary field updates at any point in time.
- In ElasticSearch, referencing fields in parents is done explicitly with “has\_parent” query operators ([source](https://www.elastic.co/guide/en/elasticsearch/guide/2.x/has-parent.html#has-parent)), while Vespa abstracts this away as regular field accesses.
- ElasticSearch has a “has\_child” query operator which allows for querying parents based on properties of their children ([source](https://www.elastic.co/guide/en/elasticsearch/guide/2.x/has-child.html#has-child)). Vespa does not currently support this.
- ElasticSearch reports query slowdowns of 500-1000% when using parent-child ([source](https://www.elastic.co/guide/en/elasticsearch/guide/2.x/parent-child-performance.html#parent-child-performance)), while expected overhead when using parent-child attribute fields in Vespa is on the order of 10-20%.
- ElasticSearch uses a notion of a “global ordinals” index which must be rebuilt upon changes to the parent set. This may take several seconds and introduce latency spikes ([source](https://www.elastic.co/guide/en/elasticsearch/guide/2.x/parent-child-performance.html#_global_ordinals_and_latency)). All parent-child reference management in Vespa is fully real-time with no additional rebuild costs at feeding or serving time.

**Distributed SQL stores**

In the recent years there has been a lot of promising development happening on the distributed SQL database (“NewSQL”) front. In particular, both the open-source CockroachDB and Google’s proprietary Spanner architectures offer distributed transactions and joins at scale. As these are both aimed primarily at solving OLTP use cases rather than realtime serving, we will not cover these any further here.

## Summary

In this blog post we’ve looked at Vespa’s new parent-child feature and how it can be used to normalize common data models. We’ve demonstrated how introducing parents both greatly speeds up and simplifies updating information shared between many documents. We’ve also seen that doing so introduces only a minor performance impact on search queries.

Have an exciting use case for parent-child that you’re working on? Got any questions? Let us know!

[vespa.ai](https://vespa.ai)  
[Vespa Engine on GitHub](https://github.com/vespa-engine/vespa)  
[Vespa Engine on Gitter](https://gitter.im/vespa-engine)


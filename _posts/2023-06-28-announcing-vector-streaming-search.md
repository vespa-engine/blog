---  
layout: post 
title: "Announcing vector streaming search: AI assistants at scale without breaking the bank"
author: geirst bratseth tegge
date: '2023-06-28' 
image: assets/2023-06-28-announcing-vector-streaming-search/marc-sendra-martorell--Vqn2WrfxTQ-unsplash.jpg
skipimage: true 
tags: [] 
excerpt: "When working with vector search in personal data, you need to handle large amounts of data and deliver complete results, but vector databases fail on both counts.
Here we introduce Vespa's Vector Streaming Search - a solution which delivers complete results in personal data at an order of magnitude lower cost."
---

![Decorative
image](/assets/2023-06-28-announcing-vector-streaming-search/marc-sendra-martorell--Vqn2WrfxTQ-unsplash.jpg)
<p class="image-credit">Photo by <a href="https://unsplash.com/@marcsm?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Marc Sendra Martorell</a> on <a href="https://unsplash.com/photos/-Vqn2WrfxTQ?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
</p>

If you are using a large language model to build a personal assistant
you usually need to give it access to personal data such as email, documents or images.
This is usually done by indexing the vectors in a vector database and retrieving by approximate nearest neighbor (ANN) search. 

In this post we’ll explain why this is not a good solution for personal data
and introduce an alternative which is an order of magnitude cheaper while actually solving the problem: Vector streaming search.


## Let’s just build an ANN index?

Let’s say you’re building a personal assistant who’s working with personal data averaging 10k documents per user,
and that you want to scale to a million users - that is 10B documents.
And let’s say you are using typical cost effective embeddings of 384 bfloat16s - 768 bytes per document.
How efficient can we make this in a vector database?

Let’s try to handle this the normal way by maintaining a global (but sharded) approximate nearest neighbor vector index.
Queries will need to calculate distances for vectors in a random access pattern as they are found in the index,
which means they’ll need to be in memory to deliver interactive latency.
Here, we need 10B * 768 bytes = 7.68 Tb of memory for the vector,
plus about 20% for the vector index for a total of about 9.2 Tb memory to store a single copy of the data.
In practice though you need two copies to be able to deliver a user’s data reliably,
some headroom for other in-memory data (say 10%), and about 35% headroom for working memory.
This gives a grand total of 9.2 * 2 * 1.1 / 0.65 = 31Tb.

If we use nodes with 128Gb memory that works out to 31Tb/128Gb = 242 nodes.
On AWS, we can use i4i.4xlarge nodes at a cost of about $33 per node per day, so our total cost becomes 242 * 33 = $8000 per day.

Hefty, but at least we get a great solution right? Well, not really. 

The A in ANN stands for approximate - the results from an ANN index will be missing some documents,
including likely some of the very best ones. That is often fine when working with global data,
but is it really acceptable to miss the one crucial mail, photo or document the user needs to complete some task correctly? 

In addition - ANN indexes shine when most of the vectors in the data are eligible for a given query,
that is when query filters are weak. But here we need to filter on the user’s own data,
so our filter is very strong indeed and our queries will be quite expensive despite all the effort of building the index.
In fact it would be cheaper to not make use of the index at all, (which is what Vespa would automatically do when given these queries).

Lastly, there’s write speed. A realistic speed here is about 8k inserts per node per second.
Since we have 2 * 10B/242 = 82 M documents per node that means it will take about
82M/(8k * 3600) = 2.8 hours to feed the entire data set even though we have this massive amount of powerful nodes.

To recap, this solution has four problems:

<style>
.styled-table {
    font-size: 0.9rem;
    border-collapse: separate;
    border-spacing: 5px;
}
.styled-table td,
.styled-table th {
  padding: 5px; 
}
</style>

{:.styled-table}

| Regular ANN for personal data |
|-------------------------------|------------------------------------------------------------------------|
| ❌ Cost                       | All the vectors must be in memory, which becomes very expensive.       |
| ❌ Coverage                   | ANN doesn’t find all the best matches, problematic with personal data. |
| ❌ Query performance          | Queries are expensive to the point of making an ANN index moot.        |
| ❌ Write performance          | Writing the data set is slow.                                          |


## Can we do better?
Let’s consider some alternatives.

The first observation to make is that we are building a global index capable of searching all user’s data at once,
but we are not actually using this capability since we always search in the context of a single user.
So, could we build a single ANN index per user instead?

This actually makes the ANN indexes useful since there is no user filter. However, the other three problems remain.

{:.styled-table}

| ANN with one index per user for personal data |
|-----------------------------------------------|------------------------------------------------------------------------|
| ❌ Cost                                       | All the vectors must be in memory, which becomes very expensive.       |
| ❌ Coverage                                   | ANN doesn’t find all the best matches, problematic with personal data. |
| ✅ Query performance                          | One index per user makes queries cheap.                                |
| ❌ Write performance                          | Writing the data set is slow.                                          |

Can we drop the ANN index and do vector calculations brute force?
This is actually not such a bad option (and Vespa trivially supports it).
Since each user has a limited number of documents, there is no problem getting good latency by brute forcing over a user’s vectors.

{:.styled-table}

| NN (exact nearest neighbor) for personal data |
|-----------------------------------------------|-------------------------------------------------------------------|
| ❌ Cost                                       | All the vectors must be in memory, which becomes very expensive.  | 
| ✅ Coverage                                   | All the best matches are guaranteed to be found.                  |
| ✅ Query performance                          | Cheap enough: One user’s data is a small subset of a node’s data. |
| ✅  Write performance                         | Writing data is an order of magnitude faster than with ANN.       |

However, we still store all the vectors in memory so the cost problem remains. 

Can we avoid that? Vespa provides an option to mark vectors paged, meaning portions of the data will be swapped out to disk.
However, since this vector store is not localizing the data of each user
we still need a good fraction of the data in memory to stay responsive, and even so both query and write speed will suffer.

{:.styled-table}

| NN (exact nearest neighbor) with paged vectors for personal data |
|---------------------------------------|--------------------------------------------------------------------|
| 🟡 Cost                               | Not all vector data must be in memory, but a significant fraction. |
| ✅ Coverage                           | All the best matches are guaranteed to be found.                   |
| 🟡 Query performance                  | Reading vectors from disk with random access is slow.              |
| ✅  Write performance                 | Writing data is an order of magnitude faster than with ANN.        |

Can we do even better, by localizing the vector data of each user
and so avoid the egregious memory cost altogether while keeping good performance?
Yes, with Vespa’s new vector streaming search you can!


## The solution: Vector streaming search
Vespa’s streaming search solution lets you make the user id a part of the document id
so that Vespa can use it to co-locate the data of each user on a small set of nodes and on the same chunk of disk.
This allows you to do searches over a user’s data with low latency without keeping any user’s data in memory
nor paying the cost of managing indexes at all.

This mode has been available for a long time for text and metadata search,
and we have now extended it to support vectors and tensors as well, both for search and ranking.

With this mode you can store billions of user vectors, along other data, on each node without running out of memory,
write it at a very high throughput thanks to Vespa’s log data store, and run queries with 

- high throughput since data is co-located on disk (or in memory buffers containing recently written data)
- low latency regardless of the size of a given user’s data, since Vespa will,
in addition to co-locating a user’s data, also automatically spread it over a sufficient number of nodes to bound query latency.

In addition you’ll see about an order of magnitude higher write throughput than with a vector solution.

The driving cost factor instead moves to disk I/O capacity, which makes this much cheaper.
To compare with our initial solution which required 242 128Gb nodes - streaming requires 45b to be stored in memory per document
so we’ll be able to cram about 128Gb / 45 * 0.65 = 1.84 B documents on each node.
We can then fit two copies of the 10B documents on 20B/1.84B = 11 nodes. 

Quite a reduction! 

{:.styled-table}

| Streamed vector search for personal data |
|------------------------------------------|---------------------------------------------------------------|
| ✅ Cost                                  | No vector data (or other document data) must be in memory.    |
| ✅ Coverage                              | All the best matches are guaranteed to be found.              |
| ✅ Query performance                     | Localized disk reads are fast.                                |
| ✅ Write performance                     | Writing data is faster even with less than 1/20 of the nodes. |

You may want a little more to deliver a sufficient query throughput for a highly successful application (see the performance case study),
but this is the kind of savings you’ll see for real production systems.

You can also use Vespa’s streaming support to combine personal vector search with regular text search
and search over metadata with little additional cost, and with advanced machine-learned ranking on the content nodes,
which are features you’ll also need if you want to create a solution with high quality.


## How to use streaming search
To use streaming search in your application, make these changes:

- Set streaming search mode for the document type in services.xml:

```
<documents>
    <document type="my-document-type" mode="streaming" />
</documents>
```

- Feed documents with ids that includes the user id of each document by
[setting the group value on ids](https://docs.vespa.ai/en/documents.html#document-ids): `id:my-namespace:my-document-type:g=my-user-id:my-locally-unique-id`
- Set the user id to search on each query by setting the parameter
[streaming.groupname](https://docs.vespa.ai/en/reference/query-api-reference.html#streaming.groupname) to the user id.

See the [streaming search documentation](https://docs.vespa.ai/en/streaming-search.html) for more details,
and try out the [vector streaming search sample application](https://github.com/vespa-engine/sample-apps/tree/master/vector-streaming-search)to get started.


## Performance case study
To measure the performance of Vespa’s vector streaming search we deployed a modified version of the
[nearest neighbor streaming performance test](https://github.com/vespa-engine/system-test/tree/master/tests/performance/nearest_neighbor_streaming)
to [Vespa Cloud](https://cloud.vespa.ai/).
We changed the [node resources](https://cloud.vespa.ai/en/reference/services#resources)
and count for container and content nodes to fit the large scale use case.

The dataset used is generated and consists of 48B documents, spread across 3.7M users.
The average number of documents per user is around 13000, and the document user distribution is as follows:  

{:.styled-table}

| Documents per user | Percentage of users |
|--------------------|---------------------|
| 100                | 35%                 |
| 1000               | 28%                 |
| 10000              | 22%                 |
| 50000              | 10%                 |
| 100000             | 5%                  |

We used 20 content nodes with the following settings to store around 2.4B documents per content node (redundancy=1).
These nodes equate to the AWS i4i.4xlarge instance with 1 3750Gb AWS Nitro local SSD disk.

```
<nodes deploy:environment="perf" count="20">
    <resources vcpu="16" memory="128Gb" disk="3750Gb" storage-type="local" architecture="x86_64"/>
</nodes>
```

![Content nodes](/assets/2023-06-28-announcing-vector-streaming-search/console_content_nodes.png "image_tooltip")
<font size="3"><i>Vespa Cloud console showing the 20 content nodes allocated to store the dataset.</i></font><br/>

We used the following settings for container nodes. The node count was adjusted based on the particular test to run.
These nodes equate to the AWS Graviton 2 c6g.2xlarge instance.

```
<nodes deploy:environment="perf" count="32">
    <resources vcpu="8" memory="16Gb" disk="20Gb" storage-type="remote" architecture="arm64"/>
</nodes>
```

### Feeding performance
The [schema](https://github.com/vespa-engine/system-test/blob/master/tests/performance/nearest_neighbor_streaming/app/schemas/test.sd)
in the application has two fields:
- `field id type long`
- `field embedding type tensor<bfloat16>(x[384])`

The embeddings are randomly generated by a [document processor](https://docs.vespa.ai/en/document-processing.html#document-processors)
while feeding the documents. In total each document is around 800 bytes, including the document id.
Example document put for user with id 10000021:

```
{"put":"id:test:test:g=10000021:81","fields":{"id":81, "embedding":[0.424140,0.663390,..,0.261550,0.860670]}}
```

To feed the dataset we used three instances of [Vespa CLI](https://docs.vespa.ai/en/vespa-cli-feed.html)
running in parallel on a non-AWS machine in the same geographic region (us east).
This machine has 48 CPUs and 256Gb of memory, and used between 40 and 48 CPU cores during feeding.
The total feed throughput was around 300k documents per second, and the total feed time was around 45 hours.

![Feed throughput](/assets/2023-06-28-announcing-vector-streaming-search/console_feed.png "image_tooltip")
<font size="3"><i>Vespa Cloud console showing feed throughput towards the end of feeding 48B documents.</i></font><br/>

![Feed throughput](/assets/2023-06-28-announcing-vector-streaming-search/console_container_nodes.png "image_tooltip")
<font size="3"><i>Vespa Cloud console showing the 32 container nodes allocated when feeding the dataset.</i></font><br/>


### Query performance

To analyze query performance we focused on users with 1k, 10k, 50k and 100k documents each.
For each of these four groups we drew between 160k and 640k random user ids to generate query files with 10k queries each.
Each query uses the [nearestNeighbor](https://docs.vespa.ai/en/reference/query-language-reference.html#nearestneighbor)
query operator to perform an exact nearest neighbor search over all documents for a given user.
Example query for user with id 10000021:

```
yql=select * from sources * where {targetHits:10}nearestNeighbor(embedding,qemb)
&input.query(qemb)=[...]
&streaming.groupname=10000021
&ranking.profile=default
&presentation.summary=minimal
&hits=10
```

This query returns the 10 closest documents according to the angular distance between the document embeddings and the query embedding.
See how the *default* [ranking profile](https://docs.vespa.ai/en/reference/schema-reference.html#rank-profile)
is defined in the [schema](https://github.com/vespa-engine/system-test/blob/master/tests/performance/nearest_neighbor_streaming/app/schemas/test.sd).
The *minimal* [summary class](https://docs.vespa.ai/en/document-summaries.html) ensures that only the *id* field
of each document is returned in the document summary. The query embedding is generated at random when creating the query files.

To measure query latency and throughput we used [vespa-fbench](https://docs.vespa.ai/en/performance/vespa-benchmarking.html#vespa-fbench)
from an AWS Graviton 2 c6g.2xlarge instance in the same zone as the deployed application (perf.aws-us-east-1c).
Each of the four “documents per user” groups were tested.
The following table and graph show the results from users with 10k documents each, around 8 Mb of data per user.
The application was deployed with 4 container nodes for this test.

{:.styled-table}

| Clients | Average latency (ms) | 99 percentile (ms) | QPS   | Disk Read (MB/s) | CPU usage (cores) |
|---------|----------------------|--------------------|-------|------------------|-------------------|
| 1       | 10.2                 | 15.1               | 98    | 35               | 0.3               |
| 2       | 10.1                 | 15.7               | 198   | 80               | 0.6               |
| 4       | 10.1                 | 16.3               | 393   | 150              | 1.0               |
| 8       | 10.5                 | 17.2               | 761   | 300              | 1.9               |
| 16      | 12.0                 | 20.7               | 1,332 | 520              | 3.5               |
| 32      | 15.5                 | 31.7               | 2,058 | 810              | 5.8               |
| 64      | 24.3                 | 75.0               | 2,627 | 1,050            | 7.5               |
| 128     | 46.9                 | 106.1              | 2,719 | 1,060            | 8.3               |

<font size="3"><i>Table showing query latencies, QPS, disk read speed per content node, and CPU usage per content node
for various number of vespa-fbench clients when running queries for users with 10k documents each.</i></font><br/>

![QPS vs query latency](/assets/2023-06-28-announcing-vector-streaming-search/graph_qps_vs_latency.png "image_tooltip")
<font size="3"><i>Graph showing QPS vs 99 percent latency when running queries for users with 10k documents each.</i></font><br/>

This shows that we start reaching the bottleneck of the disks on the content nodes when reading around 1Gb / sec per content node.
However, the sweet spot QPS is around 2000, with an average query latency of 15ms when reading around 800Mb / sec per content node.

![Query latency and throughput](/assets/2023-06-28-announcing-vector-streaming-search/console_query.png "image_tooltip")
<font size="3"><i>Vespa Cloud dashboard showing query latency and query throughput when running vespa-fbench
for users with 10k documents each. 4 container nodes were used.</i></font><br/>

The results are similar for users with 1k, 50k and 100k documents each.
The bottleneck is the read speed of the disk of the content nodes,
and the performance scales linearly with the number of documents per user.

{:.styled-table}

| Documents per user | Sweet spot QPS | 99 percent latency (ms) | Average query latency (ms) | Disk Read (MB/s) | Container nodes |
|--------------------|----------------|-------------------------|----------------------------|------------------|-----------------|
| 1000               | 19100          | 23                      | 13                         | 780              | 16              |
| 10000              | 2000           | 32                      | 15                         | 810              | 4               |
| 50000              | 365            | 44                      | 22                         | 710              | 1               |
| 100000             | 230            | 76                      | 35                         | 890              | 1               |

<font size="3"><i>Table showing the sweet spot QPS and query latencies for different “documents per user” groups.
For high QPS more container nodes are required to handle the traffic.</i></font><br/>


## How to scale vector streaming search
Based on the results in the previous section we observe that a sweet spot QPS is achieved
when reading around 800Mb / sec from the disk per content node. This uses 6 CPU cores per content node.
With this we can calculate the theoretical QPS of a given dataset.

The example used earlier in this blog post has 10B documents across 1M users.
We concluded that 11 content nodes are needed to store two copies of these documents.
With a document size of 800b, each content node is able to read around 1M documents / sec from disk, in total 11M documents / sec.
Each user has 10k documents, so the total QPS is 11M/10k = 1100.
The query capacity [scales linearly](https://docs.vespa.ai/en/performance/sizing-search.html#scaling-throughput)
with the number of content nodes, so to handle a higher load, add more nodes.


## Key takeaways
If you want to do vector search over personal data, the ANN indexes usually offered by vector databases
are a poor solution because of their high cost and inability to surface all of the user’s most relevant data.
By using Vespa’s vector streaming search you reduce cost by an order of magnitude while getting all the user’s relevant data. 

In addition, you can combine this solution with metadata search, hybrid text search,
advanced relevance and grouping with little additional cost.
Try it out now with Vespa 8.184.20, fully open source or on the [Vespa Cloud](https://cloud.vespa.ai/),
by cloning our
[vector streaming search sample application](https://github.com/vespa-engine/sample-apps/tree/master/vector-streaming-search).



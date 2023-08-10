---
layout: post 
title: "Doubling the throughput of data redistribution"
date: '2022-01-19'
tags: []
author: geirst vekterli
image: assets/2022-01-19-doubling-the-throughput-of-data-redistribution/andy-holmes-oEIFOoC3gi0-unsplash-crop.jpg
image_credit: 'Photo by <a href="https://unsplash.com/@andyjh07?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Andy Holmes</a> on <a href="https://unsplash.com/photos/oEIFOoC3gi0?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>'
skipimage: true

excerpt: Learn which improvements we made to double the throughput of data redistribution in Vespa.
---

<img src="/assets/2022-01-19-doubling-the-throughput-of-data-redistribution/andy-holmes-oEIFOoC3gi0-unsplash-crop.jpg"/>
<p class="image-credit">
Photo by <a href="https://unsplash.com/@andyjh07">Andy Holmes</a>
on <a href="https://unsplash.com/photos/oEIFOoC3gi0">Unsplash</a>
</p>

Vespa automatically keeps data distributed over content nodes and
redistributes data in the background when nodes are added or removed - examples are node failure,
optimized node configuration or cluster growth.

In the past months we have worked on improving the performance of this data redistribution.
We have been able to double the throughput, cutting the time it takes to replace a failing content node in half.

In this blog post we give an overview of which improvements we made,
with some performance numbers from a Vespa application.
All these improvements are part of Vespa 7.528.3.


## Introduction
Data in Vespa is modeled as [documents](https://docs.vespa.ai/en/documents.html).
The document space is split into logical chunks called [buckets](https://docs.vespa.ai/en/content/buckets.html),
and each document is mapped to a single bucket based on its [document id](https://docs.vespa.ai/en/documents.html#document-ids).
Buckets are automatically distributed over available nodes in a content cluster using a configured redundancy level.
Nodes can be [added to](https://docs.vespa.ai/en/elasticity.html#adding-nodes)
or [removed from](https://docs.vespa.ai/en/elasticity.html#removing-nodes) the content cluster at any time,
and Vespa will [redistribute](https://docs.vespa.ai/en/elasticity.html) data in the background
with minimal impact to query or write traffic.

No explicit sharding or manual decision making is needed. In the case of a failed node,
data redistribution is automatically run to rebuild the configured redundancy level of the data among the remaining nodes.
When retiring a node, its replicas are gradually moved to the remaining nodes.
It eventually ends up storing no data and receiving no traffic.
At this point the node can be safely removed from the cluster.

Data redistribution is an integral part of the automatic node management provided in [Vespa Cloud](https://cloud.vespa.ai/features#operations).
This includes the detection and replacement of nodes with hardware issues, upgrading OS version,
increasing or decreasing content cluster capacity,
and the optimization of node allocation using [autoscaling](https://cloud.vespa.ai/en/autoscaling).


## Data redistribution and improvements
Data redistribution in a content cluster is handled by a set of [maintenance operations](https://docs.vespa.ai/en/content/buckets.html#maintenance-operations).
The most important ones are *merge bucket* and *delete bucket*.

If bucket replicas across content nodes do not store the same document versions,
they are said to be out of sync. When this happens, a *merge bucket* operation is executed to re-sync the bucket replicas.
This operation is scheduled by the [distributor](https://docs.vespa.ai/en/content/content-nodes.html#distributor)
and sent to the content nodes ([proton](https://docs.vespa.ai/en/proton.html)) for processing.
It is a complex operation, involving multiple processes and threads, and bottlenecks were discovered in several components.

A *delete bucket* operation removes a bucket replica from a node.
It is primarily used to remove leftover data on a node after its replica contents have been copied to another node.
Removing a document requires it to be removed from all the field indexes and attributes it is part of.
This is similar in performance cost to inserting and indexing the document during feeding.
When deleting a replica, many documents are removed in one go.
This makes the *delete bucket* operation costly compared to client operations as put, update and remove,
and handling it must be as fast as possible to avoid latency spikes.

The following list summarizes on a high level which improvements were made to remove the bottlenecks found,
avoid latency spikes and improve the throughput of data redistribution.

Distributor:
- Enhanced the maintenance operation scheduling semantics to avoid potential head-of-line blocking of later buckets
in the priority database.
- Removed [distribution key](https://docs.vespa.ai/en/reference/services-content.html#nodes)
ordering requirements for merge chains to avoid load skew to content nodes with low distribution keys.

Proton:
- Made all operations related to data redistribution async to allow for better throughput.
- Prioritized merge bucket operations from content nodes ([proton](https://docs.vespa.ai/en/proton.html))
higher than merge operations from [distributor](https://docs.vespa.ai/en/content/content-nodes.html#distributor) nodes,
never rejecting them due to merge queue limits. 
- Optimized *delete bucket* handling in [document meta store](https://docs.vespa.ai/en/attributes.html#document-meta-store),
and for index and attribute fields.
- Moved extraction of document field values to index and attribute writer threads.
- Removed stop-the-world syncing of executor thread pools used in the feed pipeline.
- Changed the executor thread implementation used in the feed pipeline to one that is optimized for throughput instead of latency. 
- Changed writing of index fields to use the same executor thread pool for both
inverting fields and pushing the result to the memory index.


## Performance
Several Vespa applications running in the [Vespa Cloud](https://cloud.vespa.ai/)
were analyzed to pinpoint bottlenecks and to measure the effectiveness of the improvements made.

One of the applications uses a [grouped content distribution](https://docs.vespa.ai/en/performance/sizing-search.html#grouped-content-distribution)
with 3 groups of 4 content nodes each. The redundancy inside each group is 1,
meaning each document is 3-way replicated across the entire cluster.
Each content node has 72 vcpus, 128 GB memory, 400 GB disk,
and contains 230 million documents with a total size of 311 GB.
When replacing a content node, data is redistributed across the three other nodes in the group and the replacement node.
The bottleneck in this process is redistributing the data to the replacement node. 

The baseline throughput was an average of 22.5 MB/sec of data to the replacement node. The whole process took 3:50 hours.
With all improvements in place we achieved an average of 44 MB/sec, taking close to 2 hours.
The throughput of data redistribution was almost doubled. Similar improvements were observed for other applications.


## Summary
In this blog post we have looked at which improvements we made to double the throughput of data redistribution in Vespa
with minimal impact to query or write traffic. From an operational point of view this is important,
as the time it takes from a failing node is discovered until the redundancy level is re-established is cut in half.
All these improvements are part of Vespa 7.528.3.


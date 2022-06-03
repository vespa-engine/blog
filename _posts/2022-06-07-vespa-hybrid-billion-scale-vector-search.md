---
layout: post
title: Billion-scale vector search using hybrid HNSW-IF
date: '2022-06-03'
categories: []
tags: []
image: assets/2022-06-07-vespa-spann-billion-scale-vector-search//graham-holtshausen-fUnfEz3VLv4-unsplash.jpg
author: jobergum
skipimage: true
excerpt: This blog post describes Vespa support for hybrid HNSW-IF - A cost efficient solution for high-accuracy vector search over billion scale vector datasets.

---

<img src="/assets/2022-06-07-vespa-spann-billion-scale-vector-search//graham-holtshausen-fUnfEz3VLv4-unsplash.jpg"/>
<p class="image-credit">
Photo by <a href="https://unsplash.com/@freedomstudios">
Graham Holtshausen</a> on <a href="https://unsplash.com/photos/fUnfEz3VLv4">Unsplash</a>
</p>

The [first blog post](https://blog.vespa.ai/billion-scale-knn/) on billion-scale 
vector search covered methods for compressing real-valued vectors to binary representations 
and using hamming distance for efficient coarse level search. 
The [second post](https://blog.vespa.ai/billion-scale-knn-part-two/) described the many tradeoffs 
related to approximate nearest neighbor search using 
[Hierarchical Navigable Small World (HNSW)](https://docs.vespa.ai/en/approximate-nn-hnsw.html), 
including memory usage, indexing performance, and query performance versus quality. 

This post in this series on billion scale search covers a cost-efficient hybrid method for approximate nearest neighbor
search combining a graph method (`HNSW`) with disk based inverted file. We name this hybrid method for cost-efficient
high recall billion scale vector search for `HNSW-IF`.   

## Introduction

In-memory algorithms, like [HNSW](https://docs.vespa.ai/en/approximate-nn-hnsw.html), 
for approximate nearest neighbor search, offer fast, high-recall vector search
but can get expensive for massive vector datasets due to memory requirements. 
The `HNSW` algorithm requires storing the vector data in memory for quick access during query and indexing. 

For example, a billion scale vector dataset using 768 dimensions with float precision require 
close to 3TiB of memory. In addition, the `HNSW` graph data structure needs to be in-memory and, 
depending on `max-links-per-node (efConstruction)` setting, can add 20-40% in addition to the vector data (depending
on target accuracy).Given this, indexing a 1B dataset using `HNSW` will need about 4TiB of memory.

In 2022, many cloud provider offers [cloud instance types](https://aws.amazon.com/ec2/instance-types/high-memory/) 
supporting large amounts of memory, but these instance types also come with a high number of v-CPUs which 
drives production cost. These high-memory instance types supports massive queries per second and 
might be the optimal instance type for applications needing to support large query throughput with high recall. 
However, many real-world applications using vector search do not need enormous query throughput but still 
need to search billion-scale vector datasets with relatively low latency with high accuracy. 
Large cloud instance types with thousands of GiB of memory and hundreds 
of v-CPUs are not cost-efficient for those low query volume use cases. 

Due to this, there is increasing interest in hybrid approximate nearest neighbor search (ANNS) 
solutions using [solid-state disks (SSD)](https://en.wikipedia.org/wiki/Solid-state_drive) 
to store the majority of the vector data combined with compact in-memory graph data structures. 
[SPANN: Highly-efficient Billion-scale Approximate Nearest Neighbor Search](https://arxiv.org/abs/2111.08566) 
introduces a simple but effective solution for hybrid approximate nearest neighbor search. 

## Introducing SPANN 
*SPANN* combines the graph based in-memory method for ANNS with the classic Inverted File using clustering. 
*SPANN* partitions the vector dataset of `M` vectors into `N` clusters. 
The [paper](https://arxiv.org/abs/2111.08566) explores setting `N` to a number between 4% to 20% of `M`. 
A *centroid vector* represents each cluster. 
The [paper](https://arxiv.org/abs/2111.08566) describes different algorithms for 
clustering the vector dataset into `N` clusters and finds that *hierarchical balanced clustering* (HBC) works best. 
The paper also report that random centroid assignment also provides good accuracy.
(See *Figure 10* in the [paper](https://arxiv.org/abs/2111.08566): *Different types of centroid selection*).

The cluster centroid vectors point to a [posting list](https://en.wikipedia.org/wiki/Inverted_index) 
containing the vectors close to the cluster centroid. The posting lists of non-centroids are backed 
by disk-based data structures and centroids are indexed using an in-memory approximate nearest neighbor search algorithm. Unlike
quantization techniques for approximate nearest neighbor search, all vector distance calculations are performed 
on the original vector representation. 

At query time, *SPANN* searches for the `k` closest centroid vectors of the query vector using 
the in-memory data ANNS structure. Then, it reads the `k` associated posting lists for the retrieved 
nearest centroids and computes the distance between the query vector
and the vector data read from the posting list. Finally, the result of the two searches is merged.

<img src="/assets/2022-06-07-vespa-spann-billion-scale-vector-search/spann-posting-lists.excalidraw.png">
<em>**Figure 1** illustrates SPANN.</em>

Figure 1 gives a conceptual overview of *SPANN* for a small vector dataset of 10 vectors. 
There are two centroid vectors, vectors 4 and 9, both reference a posting list 
consisting of the vectors that are close to the cluster the centroid represents. 

A vector might be close to multiple cluster centroids, for example vector 5 and vector 8 in the figure above. 
These are examples of boundary vectors that lays in between multiple centroids. 

The offline clustering part of *SPANN* tries to balance the clusters so
that the posting lists are equal in size to reduce the time it takes to read the posting list from disk. 
For example, if the vector has 100 dimensions using `int8` precision and `int32` for the vector id,
each posting list entry uses 104 bytes. With a 4KiB disk read page size, 
one can read 1024 posting entries in a single IO read operation. 

## Hybrid HNSW-IF with Vespa 

Inspired by the *SPANN* [paper](https://arxiv.org/abs/2111.08566), we at the Vespa team 
implemented a simplified version of `SPANN` using Vespa primitives, released
as a Vespa [sample application](https://github.com/vespa-engine/sample-apps). We call this ANN method
`HNSW-IF`.  

Vespa features used to realize `HNSW-IF`:

* Real-time `HNSW` vector indexing 
* Real-time inverted index data structures
* Paged disk based vectors using Vespa tensors with `paged` option 
* Phased retrieval and ranking
* Stateless search and processor functions  

The following outlines the differences between the original `SPANN` paper and the
Vespa `HNSW-IF` implementation using Vespa primitives:

### Vector Indexing and Serving architecture

* Instead of clustering and computing centroids offline, let vectors from the original dataset 
represent centroids and use the original vector id as the centroid id.
This approach does not waste any distance calculations at query time as the 
centroids are valid eligible vectors. A subset of the vector dataset (20%) is 
selected randomly to represent centroids. Random centroid selection only 
requires one pass through the vector dataset, splitting the dataset effectively into two parts: 
*centroids* and *non-centroids*. 

* The vectors representing centroids are indexed in memory using
Vespa's support for vector indexing using
[Hierarchical Navigable Small World (HNSW)](https://docs.vespa.ai/en/approximate-nn-hnsw.html). 
Searching 200M centroid vectors using `HNSW` typically takes 2-3 milliseconds, single threaded (Depending on recall
target and `HNSW` settings). Both the graph data structure and the vector data is stored in-memory. 

* During indexing of vectors which are not cluster centroids,
search for the `k` closest centroids in the `HNSW` graph of centroids and index the 
closest centroid *ids* using Vespa's support for inverted indexes.
Later, when the index build is complete, a search for the centroid *id* efficiently retrieve
the closest non-centroid vector *ids*. 
The inverted index consists of a dictionary of centroid ids pointing to 
posting lists of non-centroid vector ids. For a given billion scale dataset with with 20% centroids, 
the max centroid dictionary vocabulary size is 200M. 

* A non-centroid vector might be present in multiple centroid clusters. 
Instead of storing the vector data in the posting lists, the vector data 
is stored in a separate Vespa data structure and avoids duplication 
caused by storing the same vector data in multiple posting lists. 

Instead, the Vespa posting list entry includes the inverted distance (closeness) to the centroid, 
scaled to integer weight. Only the vector ids are duplicated in centroid posting lists, 
not the vector data itself. 

### Querying Vectors 

For an input query vector, first search the `HNSW` content cluster for the `k` closest centroids, 
where `k` is a query time hyper-parameter balancing accuracy and search performance. 
Next, using the retrieved `k` nearest centroids from `HNSW` search, 
search the inverted index content cluster using logical disjunction (OR) of the centroid ids retrieved
by the `HNSW` graph search.

Each of the content nodes involved in the inverted index query ranks the retrieved non-centroids vectors by
calculating the distance between the vector and the query vector. Finally, the result of the two
searches is merged and returned. 

This serving flow can be optimized by 

* **Cluster centroid dynamic pruning**. After retrieving the `k` closest centroids from searching the `HNSW` graph, 
distant centroids (compared to the nearest centroid) could be pruned. 
This centroid pruning heuristic reduces the number of (potential) seeks and reads for the 
inverted index query evaluation as there are fewer posting list touched by the 
query evaluation. The centroid pruning is dynamic, a query vector which retrieves 
many equally close centroids will prune few, while a query vector which retrieves
centroids with a large closeness difference might prune many (depending on threshold).
Since the integer scaled closeness between the centroid and non-centroid vectors 
is stored in the postings, it is possible to perform a two-stage retrieval process to reduce 
the number of non-centroid vectors that needs to be read.  

* **Retrieve using dynamic pruning**. This heuristic sorts the retrieved vector ids by the 
`closeness(q, centroid) * closeness(v, centroid)` transitive closeness score before performing any 
paging of vectors from disk. the `closeness(v, centroid)` is stored in the posting list and `closeness(q, centroid)`
is present in inverted file query. 
This heuristic makes it possible to limit the total number of vector data page-ins by using Vespa's support
for controlling [phased ranking](https://docs.vespa.ai/en/phased-ranking.html). 
The local per node second-phase ranking calculates the closeness calculation `(closeness(q,v)` which involves 
paging the vector data into memory from disk. The re-ranking depth (per node) is
a query time hyper-parameter. 

The following hyper-parameters impact performance, resource footprint (cost) and accuracy of Vespa `HNSW-IF`:

**Indexing**:
* The number of random centroid vectors.
* The number of centroid clusters a given non-centroid vector can belong to.  
* The `HNSW` settings for the centroid indexing. 

**Query parameters** 
* The number of centroid vectors to retrieve by searching the `HNSW` graph. 
* The dynamic centroid pruning threshold.
* The re-ranking depth controlling the max number of vector page-ins per node in the inverted index cluster. 

## Real-world considerations
Real-world applications of vector search needs both batch and real-time vector indexing:

* **Batch**: A new embedder model which maps data to vector representation is trained and embeddings are produced for all data items. 
* **Incremental Real-time**: A new data item is added and encoded with the current version of the embedder model. 

In addition, data items (with vector representation) needs to be updated and deleted. The hybrid method
described in this blog post supports all CRUD (Create, Read, Update, Delete) operations using the standard Vespa
API's.  

* Batch indexing with a new model is handled by adding a model version field to the schema, serving queries
must restrict the search for vectors to the given model id using standard inverted index query evaluation and constrained
Vector search. 
See [Query Time Constrained Approximate Nearest Neighbor Search](https://blog.vespa.ai/constrained-approximate-nearest-neighbor-search/) and
[Embedding model hot swap](https://docs.vespa.ai/en/tutorials/models-hot-swap.html). 
Having multiple model versions active increases the deployment cost linearly with the number of models that needs to be active at any time.  

* New vectors using an existing embedding model is added to the non-centroid content cluster, with 20% centroids, 
one can expect to grow document volume significantly from baseline bootstrap size, without severely degrading accuracy. 

The only thing which the application owner need to consider is that deleting large amounts of centroid vectors
will impact recall negatively. For most large scale vector use cases this is not a realistic problem. If the use case requires
deleting large amount of vector items, one can consider decoupling centroids from vectors, so that centroids are in-fact real centroids,
and not vectors part of the dataset. 

## Vespa Experimental Setup
The following section describes our experiments with the Vespa `HNSW-F` sample application using 
Vespa Cloud's [performance environment](https://cloud.vespa.ai/en/reference/environments#perf). 
The Vespa Cloud performance environment makes it easy to iteratively develop applications and choosing the ideal instance types 
for any size vector dataset. 

<img src="/assets/2022-06-07-vespa-spann-billion-scale-vector-search/Vespa-cloud-indexing.png"/>
<em>Vespa Cloud Console - spann deployment in Vespa Cloud *perf* environment in *aws-us-east-1c*.</em>

<img src="/assets/2022-06-07-vespa-spann-billion-scale-vector-search/Spann-serving.excalidraw.png">
<em>Vespa `HNSW-IF` serving architecture.</em>

The Vespa `HNSW-IF` representation uses the same 
Vespa document schema to represent centroid and non-centroid vectors.
They are differentiated using a single field of type `bool`.    

Using two content clusters with the same document schema 
enables using different instance types for the two vector types: 
 
* High memory instances with remote and slower storage for the centroid vectors using in-memory `HNSW`.
* Inexpensive low memory instances with fast local storage for the non-centroid vectors.

This optimizes the deployment and resource cost - the vectors indexed using `HNSW` 
does not need fast local disks since queries will never page data from disk during queries. 
Similar, for vectors indexed using inverted file, content cluster instances don't 
need an awful amount of memory, but higher memory instance can improve query performance due to caching.  

The Vespa inverted index posting lists do not contain the vector data. 
Instead, vector data is stored using Vespa [paged attributes](https://docs.vespa.ai/en/attributes.html#paged-attributes),
a type of disk-backed memory mapped forward-index.  

The downside from not storing the vector data in the postings file is that 
paging in a vector from disk for distance calculation requires one 
additional disk seek. However, in our experience, 
local attached SSD disks are rarely limited by random seek capacity, 
but by read GiB/s throughput bandwidth. 

### Vector Dataset
For experiments we use the 1B *Microsoft SPACEV-1B* vector dataset:

>Microsoft SPACEV-1B is a new web search-related dataset
 released by Microsoft Bing for this competition. 
 It consists of document and query vectors encoded by the 
 Microsoft SpaceV Superior model to capture generic intent representation.

The *SPACEV-1B* vector dataset consists of 1-Billion 100-dimensional vectors using `int8` precision
and 29,3K queries with 100 ground truth (exact neighbors) per query. 
The [distance-metric](https://docs.vespa.ai/en/reference/schema-reference.html#distance-metric) used for the dataset
is `euclidean` which is the default Vespa nearest neighbor search distance-metric. 

The datasets ground truth neighbors is used to evaluate the 
accuracy (recall) of the hybrid `HNSW-IF` approach. 

### Vespa Schema 
The sample application uses the following Vespa [document schema](https://docs.vespa.ai/documentation/schemas.html).
Supported Vespa schema [field types](https://docs.vespa.ai/en/reference/schema-reference.html#field-types) 
include `string`, `long`, `int`, `float`, `double`, geo `position`, `bool`, `byte`, and `tensor` fields. 
Vespa’s first-order dense [tensor](https://docs.vespa.ai/en/tensor-user-guide.html) fields represent vector fields. 
Vespa's tensor fields support different [tensor cell precision](https://docs.vespa.ai/en/tensor-user-guide.html#cell-value-types) types,
including `int8`, `bfloat16`, `float`, and `double` for real-valued vectors. The SPACEV-1B vector dataset uses `int8` precision. 

<pre>
schema vector {

  document vector {

    field id type int {}

    field vector type tensor&lt;int8&gt;(x[100]) {
      indexing: attribute | index
    }

    field neighbors type weightedset&lt;string&gt; {
      indexing: summary | index
    }

    field disk_vector type tensor&lt;int8&gt;(x[100]) {
      indexing: attribute
      attribute: paged
    }

    field in_graph type bool {}
  }
}
</pre>

The random centroid selection is performed outside of Vespa using a simple routine which reads the 
input vector data file and randomly selects 20% to represent centroids and sets the `in_graph` field
of type `bool`. The feeder first feed the vector data which have `in_graph` set to `true` which populates
the `HNSW` content cluster first.  

The `neighbors` field is of type 
[weightedset&lt;string&gt;](https://docs.vespa.ai/en/reference/schema-reference.html#type:weightedset). This
field is populated by a custom document processor which searches the HNSW graph during ingress. For example
for vector 8 from *figure 1*, the field would be populated with two centroids found from searching the `HNSW` graph:

<pre>
{
    "put": "id:spann:vector::8"
    "fields": {
        "id": "8",
        "neighbors": {
            "4": 45
            "9": 100
        },
        "in_graph": false,
        "disk_vector": {
            "values": [12, -8, 1, ..]
        }
    }
}
</pre>

This `neighbors` field is inverted by Vespa content node process, so that a query for 
`where neighbors contains "4"` would retrieve vector 8 and expose it to Vespa ranking. 
The integer weight represent the closeness to the centroid id. 
Closeness is the inverted distance, low distance means higher closeness.
The original `float` closeness value returned from the `HNSW` search is scaled to integer weight by
multiplying with a constant and rounded to the closest integer. 

The document processor clears the incoming `vector` field and instead creates 
the `disk_vector` field which uses the `attribute: paged` option for paging in
the vector data at ranking time.  

The schema also have two `rank-profile`'s which determines how vectors are ranked performing
distance calculations.  One profile used for the `HNSW` search and one for the `Inverted File` search
implementing phased ranking heuristic.

### Vespa deployment specification (services.xml) 
For our experiments we use multiple stateless and stateful Vespa clusters in the same Vespa application. Everything
is is configured using [Vespa services.xml](https://cloud.vespa.ai/en/reference/services). 

* A stateless `feed` container cluster handling feed operations running a custom document processor
which searches the HNSW graph for non-centroid vectors. 
This cluster uses default resources which is 2 v-cpu, 8GiB of memory and 50GiB of disk:
<pre>
    &lt;nodes deploy:environment="perf" count="4"/&gt;
</pre>
* A stateless `default` container cluster handling search queries. This cluster also uses default resources.
<pre>
    &lt;nodes deploy:environment="perf" count="2"/&gt;
</pre>
* A stateful content cluster `graph` which is used with high memory instance types and `HNSW`. 
<pre>
 &lt;nodes deploy:environment="perf" count="1" groups="1"&gt;
    &lt;resources memory="128GB" vcpu="16" disk="200Gb" storage-type="remote"/&gt;
 &lt;/nodes&gt;
 </pre>
* A stateful content cluster `if` which is used for inverted indexing (inverted file) for non-centroid vectors. 
<pre>
&lt;nodes deploy:environment="perf" count="4" groups="1"&gt;
    &lt;resources memory="128GB" vcpu="16" disk="200Gb" storage-type="remote"/&gt;
 &lt;/nodes&gt;
</pre>

The Vespa Cloud hourly cost for this deployment, supporting 1B vectors comfortably is 8.38$ per hour, or
6,038 $ per month. 

<img src="/assets/2022-06-07-vespa-spann-billion-scale-vector-search/clusters.png"/>
<em>Screenshot from Vespa Cloud console with app's cluster's and allocated resources.</em>

As can be seen from the figure above, the deployment is slightly over-provisioned and could easily support larger vector volumes
comfortably. Vespa Cloud also allow a wide range of resource combinations (more memory, more cpu, more disk) and as many nodes. 

### Vespa stateless function components 
Custom stateless Vespa functions implements the serving and processing logic. The
components are deployed inside the Vespa cluster, where communication is secured and data transfer
is using optimized binary protocols. The gist of the custom 
[searcher](https://docs.vespa.ai/en/searcher-development.html) implementing
the search logic is given below:

<pre>
@Override
public Result search(Query query, Execution execution) {
    Tensor queryVector = query.getTensor("query(q)");
    CentroidResult centroidResult = clustering.getCentroids(
        queryVector,
        nClusters,
        hnswExploreHits,
        execution);
    List&lt;Centroid&gt; centroids = clustering.prune(
        centroidResult.getCentroids(),
        pruneThreshold);

    DotProductItem dp = new DotProductItem("neighbors");
    for (Centroid c : centroids) {
        dp.addToken(c.getId(), c.getIntCloseness());
    }
    query.getModel().getQueryTree().setRoot(dp);
    query.getModel().setSources("if");
    query.getRanking().setRerankCount(reRankCount);
    return mergeResult(execution.search(query), centroidResult);
}
</pre>

Similar, a custom [document processor](https://docs.vespa.ai/en/document-processing.html) implements
the search in the `HNSW` and annotating of nearest centroids with closeness weight. 

## Vespa HNSW-IF Experiments 
The following experiments uses the these fixed indexing side hyper-parameters

- In-memory centroid indexing using `max-links-per-node: 18` and `neighbors-to-explore-at-insert: 100`.
- For any given non-centroid vector index 12 closest centroid vector ids. 


### Batch Indexing performance 
With the mentioned allocated resources in Vespa Cloud *perf*, indexing the *SPACEV-1B* dataset takes approximately 28 hours. The 200M vectors (centroids) are
fed first and indexed at around 9000 puts/s into the HNSW graph content cluster. The
remaining 800M non-centroid vectors is indexed with a similar puts/s rate, and also searches the `HNSW` index at the same rate.

Vectors are read from the dataset converted to [Vespa JSON feed format](https://docs.vespa.ai/en/reference/document-json-format.html)
by a simple python script. The resulting JSON files are feed using [Vespa feed client](https://docs.vespa.ai/en/vespa-feed-client.html)
for ultimate batch feed performance using `http/2` with `mTls` to secure the vector data in transit. 

<img src="/assets/2022-06-07-vespa-spann-billion-scale-vector-search/Vespa-cloud-indexing.png"/>

<em>Vespa Cloud console screenshot taken during indexing of non-centroids. During indexing, a document processor searches the HNSW graph,
and annotates the document with the closest centroids before forwarding the document to the `if` content cluster. </em>

<img src="/assets/2022-06-07-vespa-spann-billion-scale-vector-search/metrics.png"/>
<em>Vespa Cloud metrics dashboard.</em>
The [Vespa Cloud metrics](https://cloud.vespa.ai/en/monitoring) gives insight into resource usage with concurrent read and queries over 1B
vectors. 

### HNSW-IF Accuracy 
Any approximate vector search use case needs to quantify the accuracy impact of using approximate search instead of
exact search. Using the ground truth neighbors for the 29,3K *SPACEV-1B* query vectors, 
we can experiment with the hybrid `HNSW-IF` solution:

<img src="/assets/2022-06-07-vespa-spann-billion-scale-vector-search/recall.png"/>

<em>Recall@10 for 29,3K queries</em>

The above figure is produced by running all 29,3K queries with an increasing number of `k` centroids, ranging
from 1 centroid to 256 centroids (1, 2, 4, 8 , 16, 32, 64, 128, 256). The distance prune threshold was set to 0.6 and maximum
re-ranking depth 4K. Example run 

<pre>
python3 recall.py --endpoint https://spann.samples.aws-us-east-1c.perf.z.vespa-app.cloud/search/ \
  --query_file query.i8bin --query_gt_file public_query_gt100.bin --clusters 32 --distance_prune_threshold 0.6 --rank_count 4000 \
  --certificate data-plane-public-cert.pem --key data-plane-private-key.pem
</pre>

With 128 centroids we reach 90% recall@10 at 50 ms end to end. 50 ms is one order of magnitude larger than what
in-memory algorithms supports at the same recall level, but for many vector search use cases 50ms is perfectly acceptable, especially with high recall. 
To put the number is context, 9 out of 10 queries returns the same top-10 result as expensive exact nearest neighbor search, over 1B vectors! 


## Summary 

This blog post introduced a cost-effective hybrid method for billion scale vector search which enable 
many new real-world applications using AI-powered vector representations. You can get started today using the ready to deploy
Vespa sample application configured and ready for using `HNSW-IF` over at [Vespa sample applications](https://github.com/vespa-engine/sample-apps).

Also try out other [Vespa sample applications](https://github.com/vespa-engine/sample-apps) built using Vespa's approximate 
nearest neighbor search support using `HNSW`:

- [State-of-the-art text ranking](https://github.com/vespa-engine/sample-apps/blob/master/msmarco-ranking/passage-ranking.md): 
Vector search with AI-powered representations built on NLP Transformer models for candidate retrieval. 
The application has multi-vector representations for re-ranking, using Vespa's [phased retrieval and ranking](https://docs.vespa.ai/en/phased-ranking.html) 
serving pipelines. Furthermore, the application shows how embedding models, which maps the text data to vector representation, can be 
deployed to Vespa for [run-time inference](https://blog.vespa.ai/stateless-model-evaluation/) during both document and query processing.

- [State-of-the-art image search](https://github.com/vespa-engine/sample-apps/tree/master/text-image-search): AI-powered multi-modal vector representations
to retrieve images for a text query. 

- [State-of-the art open-domain question answering](https://github.com/vespa-engine/sample-apps/tree/master/dense-passage-retrieval-with-ann): AI-powered vector representations
to retrieve passages from Wikipedia, which are fed into a NLP reader model which identifies the answer. End-to-end represented using Vespa.

All these are examples of applications built using AI-powered vector representations, and where real-world deployments 
need query-time constrained nearest neighbor search. 

Vespa is available as a cloud service, see [Vespa Cloud - getting started](https://cloud.vespa.ai/en/getting-started),
or self-serve [Vespa - getting started](https://docs.vespa.ai/en/getting-started.html).  




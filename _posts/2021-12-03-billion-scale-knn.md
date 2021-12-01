---
layout: post
title: "Billion scale vector search with Vespa - part one"
date: '2021-11-29'
tags: []
author: jobergum 
image: assets/2021-12-03-binary-codes/federico-beccari-L8126OwlroY-unsplash.jpg
skipimage: true

excerpt: "Billion scale vector search using compact binary representations"
---


<img src="/assets/2021-12-03-binary-codes/federico-beccari-L8126OwlroY-unsplash.jpg"/>
<p class="image-credit">
Photo by <a href="https://unsplash.com/@federize?">Federico Beccari</a> 
on <a href="https://unsplash.com/s/photos/universe?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
</p>

<a href="https://www.nasa.gov/">Nasa</a> estimates that the Milky Way galaxy 
contains about <a href="https://asd.gsfc.nasa.gov/blueshift/index.php/2015/07/22/how-many-stars-in-the-milky-way/">
100 to 400 billion stars</a>. A mind-blowing large number of stars and solar systems, and also a stunning sight from planet earth on a clear night. 

Many organizations face challenges involving star-sized datasets, even orders of magnitude larger. 
AI-powered representations of unstructured data like image, text, and video have enabled search applications 
we could not foresee just a few years ago. 
For example, we covered vision and video search applications using 
<a href="https://blog.vespa.ai/text-image-search/">AI-powered vector space representations</a> 
in a previous blog post, and especially video and image datasets
can easily reach star-scale numbers. 

Searching star-sized AI-powered vector representations using (approximate) 
nearest neighbor search is a fascinating problem involving many trade-offs :

* Accuracy or the quality of the nearest neighbor search 
* Efficiency and complexity of the algorithm 
* Latency service level agreements (SLA)
* Read (queries) and write throughput, batch versus real-time  
* Distribution and partitioning of vector datasets which does not fit into a single machine 
* Cost ($), Total cost of ownership, including development efforts 

Also, when choosing infrastructure and technology to solve billion scale datasets, there are aspects like:

* Ease of use and developer friendliness of the platform technology
* Durability and consistency model, vector meta data and batch versus real time indexing  
* Operational cost - How hard is to manage the infrastructure and technology

This blog series looks at how to represent and search billion scale vector datasets using Vespa and we cover many of the mentioned 
vector search trade-offs.

In this first post we look at compact binary-coded AI-powered vector representations which can reduce storage and computational complexity
of nearest neighbor search. 
 
# Introduction
<a href="https://arxiv.org/abs/1712.02956">Deep Neural Hashing</a> is a catchy phrase 
for using deep neural networks for 
<a href="https://learning2hash.github.io/">learning
compact hash-like</a> binary-coded representations. The goal of <a href="https://arxiv.org/abs/1206.5538">representation
learning</a>, deep or not, is to transform any data into a suitable representation
that retains the essential information needed to solve a particular task, for
example, search or retrieval. Representation learning for retrieval usually involves
supervised learning with labeled or pseudo-labeled data from user-item interactions. 
 
Many successful retrieval systems use supervised representation
learning to transform text queries and documents into continuous
high-dimensional real-valued vector representations. A query and document
similarity, or relevancy,  is measured using a vector distance metric in the
representational vector space. To efficiently retrieve from a potentially large
collection of documents, one can turn to approximate nearest neighbor search
algorithms instead of exact. 
See for example the  
<a href="https://blog.vespa.ai/pretrained-transformer-language-models-for-search-part-2/">
pre-trained transformer language models for search </a> blog post for 
an introduction to state-of-the-art text retrieval using dense vector representations.

Recently, exciting research has demonstrated that it is possible to learn a
compact hash-like binary code representation instead of a dense continuous
vector representation that rivals the text retrieval accuracy of the continuous
representation. In <a href="https://arxiv.org/abs/2106.00882">
Efficient Passage Retrieval with Hashing for Open-domain Question Answering</a>, the authors describe
using a hashing layer on top of the bi-encoder transformer architecture 
to train a binary coded representation of documents and queries
instead of continuous real valued representation. 

<img src="/assets/2021-12-03-binary-codes/bpr.png"/>

A huge advantage over continuous vector
representations is that the binary-coded document representation significantly reduces
the document storage requirements. For example, representing text documents in a
768-dimensional vector space where each dimension uses float precision, the
storage requirement per document becomes 3072 bytes. Using a 768-bit
binary-coded representation instead, the storage requirement per document
becomes 96 bytes, a 32x reduction compared to the high precision float vector
representation. In the mentioned paper, the authors demonstrate that the entire 
English Wikipedia consisting of 22M passages can be reduced to 2GB of binary codes. 

Searching in binary-coded representations can be done using the <a href="https://en.wikipedia.org/wiki/Hamming_distance">hamming distance</a> metric. 
The hamming distance between code <em>q</em> and code <em>d</em> is simply the number of bit
positions that differ or, in other words, the number of bits that need to flip
to convert <em>q</em> into <em>d</em>.  Hamming distance is efficiently implemented on CPU
architectures using few instructions (xor combined with population count).  In
addition, hamming distance search makes it possible to rank a set of binary
codes for a binary coded query compared to exact hash table lookup. 

Compact binary-coded representations paired with hamming
distance is also successfully used for large-scale cost efficient vision search. 
See for example these papers on using binary codes for cost efficient vision search: 
* <a href="https://www.cv-foundation.org/openaccess/content_cvpr_workshops_2015/W03/papers/Lin_Deep_Learning_of_2015_CVPR_paper.pdf">
Deep Learning of Binary Hash Codes for Fast Image Retrieval (pdf)</a>.
* <a href="https://arxiv.org/pdf/2105.01823.pdf">
TransHash: Transformer-based Hamming Hashing for Efficient Image Retrieval (pdf)</a>.

# Representing hash-like binary-codes in Vespa
Vespa has first-class citizen support for representing high dimensional dense
vectors using the <a href="https://docs.vespa.ai/en/tensor-user-guide.html">
Vespa tensor</a> field type. Dense vectors are represented as
dense first-order tensors in Vespa. Tensor cell values in Vespa support four
<a href="https://docs.vespa.ai/en/tensor-user-guide.html#cell-value-types">numeric precision types</a>, 
in order of increasing precision:

* `int8` (8 bits, 1 byte) per dimension
* `bfloat16` (16 bits, 2 bytes) per dimension
* `float` (32 bits, 4 bytes) per dimension
* `double` (64 bits, 8 bytes) per dimension

All of which are signed data types. In addition, for dense first-order tensors
(vectors), Vespa supports fast approximate nearest neighbor search using Vespa's
<a href="https://docs.vespa.ai/en/approximate-nn-hnsw.html">HNSW implementation</a>. 
Furthermore, the nearest neighbor search operator in Vespa
supports several <a href="https://docs.vespa.ai/en/reference/schema-reference.html#distance-metric">
distance metrics</a>, including `euclidean`, `angular`, and bitwise
`hamming` distance. 

To represent binary-coded vectors in Vespa, one should use first-order tensors
with the `int8` tensor cell precision type. For example, to represent a 128-bit code using
tensors, one can use a 16-dimensional dense tensor using `int8` value type
(16*8 = 128 bits). The <a href="https://docs.vespa.ai/documentation/schemas.html">
Vespa document schema</a> below defines a numeric id field
of type `int`, representing the vector document id in addition to the binary-coded
vector using a dense first-order tensor. The `b` denotes the tensor dimension
name, and finally, `[16]` denotes the dimensionality.  

<pre>
schema code {
  document code {
    field id type int {}
    field binary_code type tensor&lt;int8&gt;(b[16]) {
      indexing: attribute
      attribute { 
        distance-metric:hamming
      } 
    }
  }
}
</pre>

Using <a href="https://en.wikipedia.org/wiki/Endianness">big-endian</a> ordering for the binary-coded representation, the
most significant bits from the binary-code at position 0 to 7 inclusive are the first
vector element at index 0, bits at position 8 to 15 inclusive in the second
vector element, and so on. For example, the following snippet uses <a href="https://numpy.org/">NumPy</a>
with python to
demonstrate a way to create a binary-coded representation from a 128-dimensional
real-valued vector representation by using an untrained thresholding function (sign
function):

```
import numpy as np
import binascii
vector = np.random.normal(3,2.5, size=(128))
binary_code = np.packbits(np.where(vector > 0, 1,0)).astype(np.int8)
str(binascii.hexlify(binary_code),'utf-8')
'e7ffef5df3bcefffbfffff9fff77fdc7'
```
The above <a href="https://en.wikipedia.org/wiki/Hexadecimal">hexadecimal</a> string representation 
can be fed to Vespa using the <a href="https://docs.vespa.ai/en/reference/document-json-format.html#tensor">
Vespa JSON feed</a> format. 

<pre>
{
  "id": "id:bigann:code::834221",
  "fields": {
    "id": 834221,
    "binary_code": {
      "values": "e7ffef5df3bcefffbfffff9fff77fdc7"
    }
  } 
}
</pre>

Indexing in Vespa is real-time and documents become searchable within single digit 
millisecond latency at high throughput. The JSON feed files can be indexed with 
high throughput using the <a href="https://docs.vespa.ai/en/vespa-feed-client.html">
Vespa feed client</a>.

<img src="/assets/2021-12-03-binary-codes/feeding.gif"/>

Dense first-order tensors can either be in memory all the time or paged in from
secondary storage on-demand at query time, for example, during scoring and
ranking phases in a <a href="https://docs.vespa.ai/en/phased-ranking.html">
multi-phased retrieval and ranking</a> pipeline. In any case,
the data is <a href="https://docs.vespa.ai/en/overview.html">
persisted and stored</a> for durability and <a href="https://docs.vespa.ai/en/elastic-vespa.html">data re-balancing</a>.

Furthermore, supporting in-memory and <a href="https://docs.vespa.ai/en/attributes.html#paged-attributes">
paged dense</a> first-order tensors enables
storing the original vector representation in the document model at a relatively
low cost (storage hierarchy economics).  For example, the following document schema keeps
the original float precision vector on disk using the `paged` tensor attribute option. 

<pre>
schema code {
  document code {
    field id type int {} 
    field binary_code type tensor&lt;int8&gt;(b[16]) {
      indexing: attribute
      attribute { 
        distance-metric: hamming 
      }
    }
    field vector type tensor&lt;float&gt;(r[128]) {
      indexing: attribute
      attribute: paged
    }
  }
}
</pre>

Storing the original vector representation on disk using the 
<a href="https://docs.vespa.ai/en/attributes.html#paged-attributes">paged
attribute option</a> enables phased retrieval and ranking close to the data.  First,
one can use the compact in-memory binary code for the coarse level search to
efficiently find a limited number of candidates. Then, the pruned number of
candidates from the coarse search can be re-scored and re-ranked using a more
advanced scoring function using the original document and query representation. Once
a document is retrieved and exposed to the ranking phases, one can also use more
sophisticated scoring models, for example using Vespa's support for evaluating 
<a href="https://docs.vespa.ai/en/onnx.html">ONNX</a> models.

<img src="/assets/2021-12-03-binary-codes/image-search.png"/>

A two-phased coarse to fine level search using hamming distance as the coarse-level search 
architecture illustration. Illustration from <a href="https://www.cv-foundation.org/openaccess/content_cvpr_workshops_2015/W03/papers/Lin_Deep_Learning_of_2015_CVPR_paper.pdf">  
Deep Learning of Binary Hash Codes for Fast Image Retrieval (pdf)</a>. 

The binary-coded representation and the original vector are co-located on the
same <a href="https://docs.vespa.ai/en/overview.html">Vespa content node(s)</a> 
since they live in the same document schema. Thus,
re-ranking or fine-level search using the real-valued vector representation does not require any
network round trips to fetch the original vector representation from some
external key-value storage system. 

In addition, co-locating both the coarse and fine representation avoid
data consistency and synchronizations issues between different data stores. 

# Searching binary-codes with Vespa's nearest neighbor search query operator

Using Vespa's nearest neighbor search query operator, one can search for the
semantically similar documents using the hamming distance metric. The following
example uses the exact version and does not use the approximate version using
Vespa's HNSW indexing support. The next blog post in this series will compare
exact with approximate search. The following Vespa document schema defines
two Vespa <a href="https://docs.vespa.ai/en/ranking.html">ranking profiles</a>:  

<pre>
schema code {
  document code {
    field id type int {..} 
    field binary_code type tensor&lt;int8&gt;(b[16]) {..}
 }
 rank-profile coarse-ranking {
    num-threads-per-search:12
    first-phase { expression { closeness(field,binary_code) } } 
 }
 rank-profile fine-ranking inherits coarse-ranking {
    second-phase { expression { .. } } 
 }
}
</pre>

The <em>coarse-ranking</em> <a href="https://docs.vespa.ai/en/ranking.html">ranking</a> 
profile ranks documents by the <a href="https://docs.vespa.ai/en/reference/rank-features.html#closeness(dimension,name)">
closeness rank feature</a> which in our case is the inverse hamming distance.
By default, Vespa sorts documents by descending relevancy score.
, hence the `closeness(field,name)` rank feature uses
`1/(1 + distance())` as the relevance score. 

The observant reader might have noticed the <a href="https://docs.vespa.ai/en/performance/sizing-search.html#num-threads-per-search">
num-threads-per-search</a> ranking profile setting.
This setting allows parallelizing the search and ranking using
multiple CPU threads, reducing the overall serving latency at the cost of
increased CPU usage per query. Another trade-off related parameter which allows utilizing multi-core CPU architectures
better. 

The second ranking profile `fine-tune` inherits the first phase 
ranking function from the `coarse-ranking` profile and re-ranks the top k results using a more sophisticated model,
for example using the original representation.

The nearest neighbor search is expressed using the <a href="https://docs.vespa.ai/en/query-language.html">Vespa YQL query
language</a> in a <a href="https://docs.vespa.ai/en/reference/query-api-reference.html">search api</a> http(s) request.  

A sample JSON POST query is given below, searching for the 10 nearest neighbors of a query vector 
<pre>
{
  "yql": "select id from vector where ([{\"targetHits\":10}]nearestNeighbor(binary_code, q_hash_code));",
  "ranking.profile": "coarse-ranking",
  "ranking.features.query(q_binary_code): [..],
  "hits":10
}
</pre>

Vespa also allows combining the nearest neighbor search query operator with
other query operators and filters which for the exact case reduces the complexity of the NN search as fewer candidates
as evaluated which saves memory bandwidth and CPU instructions. For example the below example filters on a `is_visible` 
`bool` type field.

<pre>
{
  "yql": "select id from vector where ([{\"targetHits\":10}]nearestNeighbor(binary_code, q_hash_code)) and is_visible=true;",
  "ranking.profile": "coarse-ranking",
  "ranking.features.query(q_binary_code): [-18,-14,28,...],
  "hits":10
}
</pre>
Note that input query tensors does not support the compact hex string representation. In the above query examples we use the short dense tensor input format.

# Summary 
This post introduced our blog post series on billion scale vector search, furthermore, we took a deep dive into representing binary-code using
Vespa's tensor field support with support for <em>int8</em> tensor cell precision. We also covered coarse-level to fine-level ranking using hamming
distance as the coarse-level search distance metric. 
In the next blog post in this series we will 
experiment with a 1B vector dataset from <a href="http://big-ann-benchmarks.com/">big-ann-benchmarks.com</a>, 
indexing it on Vespa using both exact and approximate with hamming distance and look at some of the trade-offs:

* Real-Time indexing throughput with and without HNSW graph enabled 
* Search accuracy degradation using approximate versus exact 
* Storage (disk and memory) footprint 
* Latency and throughput  
  
Stay tuned for the next blog post in this series!

---  
layout: post 
title: "Revolutionizing Semantic Search with Multi-Vector HNSW Indexing in Vespa"
author: geirst tegge jobergum 
date: '2023-03-28' 
image: assets/2023-03-29-semantic-search-with-multi-vector-indexing/peter-herrmann-aT88kga0g_M-unsplash.jpg
skipimage: true 
tags: [] 
excerpt: announcing multi-vector support in Vespa, which allows you to index multiple vectors per document and retrieve documents by the closest vector in each 
---

![Decorative
image](/assets/2023-03-29-semantic-search-with-multi-vector-indexing/peter-herrmann-aT88kga0g_M-unsplash.jpg)
<p class="image-credit">Photo by <a href="https://unsplash.com/@tama66?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Peter Herrmann</a> on <a href="https://unsplash.com/photos/aT88kga0g_M?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
</p>

Finding data items by nearest neighbor search in vector space has
become popular in recent years, but suffers from one big limitation:
Each data item must be well representable by a single vector. This
is often far from possible, for example, when your data is text
documents of non-trivial length. Now we are announcing multi-vector
support in Vespa, which allows you to index multiple vectors per
document and retrieve documents by the closest vector in each.


## Background

Advances in self-supervised deep learning models have revolutionized
how to represent unstructured data like text, audio, image, and
videos in a language native to machines; Vectors.

![overview](/assets/2023-03-29-semantic-search-with-multi-vector-indexing/image1.png "image_tooltip")
<font size="2"><i>Embedding data into vector space.</i></font><br/>

Encoding objects using deep learning models allows for representing
objects in a high-dimensional vector space. In this latent embedding
vector space, one can compare the objects using vector distance
functions, which can be used for search, classification, and
clustering, to name a few.

![embeddings and distances](/assets/2023-03-29-semantic-search-with-multi-vector-indexing/image2.png "image_tooltip")

<font size="2"><i>Documents (squared) and queries (circle) are mapped by a trainable
model to a vector space (here illustrated in two dimensions). The
two nearest neighbors of the query in vector space are documents A
and C. Using representation learning, the model is adjusted (by
gradient descent) so that relevant (q,d) pairs have a low distance,
and irrelevant pairs a have a higher distance.</i></font><br/>

For embedding text data, models based on the
[Transformer](https://en.wikipedia.org/wiki/Transformer_(machine_learning_model))
architecture have become the de-facto standard. A challenge with
Transformer based models is their input length limitation due to
the quadratic self-attention computational complexity. For example,
a popular open-source [text embedding
model](https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2) has
an absolute maximum input length of 512 [wordpiece
tokens](https://huggingface.co/course/chapter6/6?fw=pt). Still,
inputs are truncated during training at 128 tokens, and trying to
fit more tokens than used during fine-tuning of the model will
impact the quality of the vector representation[^1]. One
can view embedding encoding as a lossy compression technique, where
variable-length texts are compressed into a fixed dimensional vector
representation.

![Wikipedia snippet](/assets/2023-03-29-semantic-search-with-multi-vector-indexing/image5.png "image_tooltip")
<font size="3"><i>Highlighted text in blue from the
<a href="https://en.wikipedia.org/wiki/Metric_space">Wikipedia:Metric_space</a>
article. The highlighted text is exactly 128 wordpieces long after
tokenization. This illustrates the narrow context window of Transformer
based embedding models.</i></font><br/>

Due to the context length limited Transformers, developers that
want to index Wikipedia or any text dataset using embedding models
must split the text input into paragraph-sized chunks that align
with lengths used during fine-tuning of the model for optimal
embedding quality.

![Splitting into chunks](/assets/2023-03-29-semantic-search-with-multi-vector-indexing/image3.png "image_tooltip")

<font size="3"><i>Illustration of splitting or chunking of Wikipedia articles into
multiple paragraphs to overcome model length limitations. There are
several strategies for chunking longer text, from simple splitting
to more advanced methods using sliding windows, so the generated
chunks have overlapping wordpieces.</i></font><br/>

When changing the retrieval unit from articles to paragraphs, the
nearest neighbor search in the embedding space retrieves the nearest
paragraphs, not the nearest articles. To map the query-paragraph
distance to a query-article distance, one popular approach is to
use an aggregate function. For example, the minimum distance of
query-paragraph distances is used as a proxy for the query-article
distance.

With minimum distance aggregation, it’s possible to use a vector
search library and index paragraphs, combining the article id and
a paragraph id to form a new primary key. For example, using
incremental paragraph numbers per article, instead of indexing the
article _Metric_space_, developers could index _Metric_space_#1,
Metric_space_#2, Metric_space_#3_, and so forth. This might seem
easy at first sight, but there are many disadvantages to this
modeling approach.

### Relationships and fan-out

The developer needs to manage the fan-out relationship between
articles and paragraphs.  When the article changes, the user must
re-process the article into paragraphs which might leave orphaned
paragraphs in the paragraph index. Deletion of an article requires
a cascading deletion of all associated paragraphs from the index.
Similarly, updating an article-level meta field requires fan-out
to update the paragraphs associated with the article.

### Result presentation

The unit of retrieval complicates search result presentation and
linking to the source text. Consider searching Wikipedia; how do
you link to the chunked text with the minimal embedding distance,
which caused the article to be present on the search engine result
page?

### Result diversity

The closest k nearest neighbors in the paragraph level embedding
space could be from the same article. Increasing the diversity of
sources is especially important when used for retrieval-augmented
generative question answering, where the generative model also has
context length limitations.

### Constrained nearest neighbor search

For [constrained nearest neighbor
search](https://blog.vespa.ai/constrained-approximate-nearest-neighbor-search/)
on article-level metadata, developers must duplicate the article
metadata into the paragraph level for efficient filtering in
combination with vector search. Thus, the more properties that
naturally belong on the article level, the higher the duplication
factor.

### Hybrid ranking

[Hybrid](https://blog.vespa.ai/improving-zero-shot-ranking-with-vespa/)
combinations of text scoring functions, like
[BM25](https://docs.vespa.ai/en/reference/bm25.html), with vector
distance, outperform other efficient retrieval methods in a zero-shot
setting. Important text fields from the article, such as the title,
must be duplicated into the paragraph index to perform efficient
hybrid retrieval.

The following sections describe how to overcome these challenges
using Vespa’s multi-vector HNSW indexing feature. Multi-vector
indexing is available from Vespa 8.144.19. The post also looks
behind the scenes at the industry-unique implementation. Furthermore,
it also describes other use cases, which are greatly simplified
with multi-vector indexing support.


## Using multi-vector HNSW indexing with Vespa

This section highlights how developers configure and use multi-vector
indexing with Vespa. The highlights are from an open-source [sample
application](https://github.com/vespa-engine/sample-apps/tree/master/multi-vector-indexing)
that demonstrates the new multi-vector indexing functionality.


### Schema

Consider the following schema for Wikipedia articles, expressed
using [Vespa’s schema definition
language](https://docs.vespa.ai/en/schemas.html):

<pre>
schema wiki
  document wiki {
     field title type string {} 
     field content type string {}   
  }  
}
</pre>

This is straightforward, mapping the Wikipedia article schema to a
Vespa schema; as before, semantic search with vector embeddings
made their entry. With length-limited embedding models, developers
need to chunk the content into an array of strings to overcome
length limitations.

<pre>
schema wiki {
  document wiki {
     field title type string {}    
     field paragraphs type array&lt;string&gt; {}  
     field paragraph_embeddings type tensor&lt;float&gt;(p{},x[384]) {}
  } 
}
</pre>

Notice the `paragraph_embeddings` field, which is an example of a
mapped-indexed [tensor](https://docs.vespa.ai/en/tensor-user-guide.html),
which mixes a mapped sparse dimension (**p**) with an indexed
dimension (**x**). This tensor-type definition is similar to a
classic map data structure, where the key maps to a fixed-size array
of floats.

Using a mapped-indexed tensor allows variable-length articles to
be indexed without wasting resources using a matrix (indexed-indexed)
tensor representation.

In the above schema example, it’s up to the developer to produce
the paragraphs in array representation and the vectorized embeddings.


### JSON Feed

With the above schema, developers can index chunked data, along
with the embeddings per chunk, using the following [Vespa JSON feed
format](https://docs.vespa.ai/en/reference/document-json-format.html):
<pre>
{ 
  "put": "id:wikipedia:wiki::Metric_space", 
  "fields": {
    "title": "Metric space",
    "paragraphs" : [
      "In mathematics, a metric space...",
      "strings can be equipped with the Hamming distance, which measures the number.. " 
	],
	"paragraph_embeddings": {
          "0": [0.12,0.03,....,0.04],
          "1": [0.03, 0.02,...,0.02]
	}
   }
}
</pre>
Note that the developer controls the text chunking strategy. Suppose
the developer wants to map vectors to the text paragraphs that
produced them. In that case, the developer can use the index in the
paragraphs array as the tensor dimension key. This helps the developer
present the best matching paragraph(s) on the search result page,
as described in the ranking section below.

### Native embedding integration

Managing complex infrastructure for producing text embedding vectors
could be challenging, especially at query serving time, with low
latency, high availability, and high query throughput. Vespa allows
developers to [represent embedding
models](https://blog.vespa.ai/text-embedding-made-simple/) in Vespa.
In this case, the schema becomes:

<pre>
schema wiki {
  document wiki {
     field title type string {}    
     field paragraphs type array&lt;string&gt; {}  
  } 
  field paragraph_embeddings type tensor&lt;float&gt;(p{},x[384]) { 
    indexing: input paragraphs | embed | attribute | index | summary
   }
}
</pre>

In this case, Vespa will produce embeddings and use the array index
(0-based) of the paragraph as the mapped dimension label. Regardless
of using native embedders or producing embeddings outside of Vespa,
developers must also configure a [distance
metric](https://docs.vespa.ai/en/reference/schema-reference.html#distance-metric)
that matches the distance metric used during model training.

### Querying

The following demonstrates a Vespa [query
api](https://docs.vespa.ai/en/query-api.html) request with [native
embedder
functionality.](https://docs.vespa.ai/en/embedding.html#bertbase-embedder)
The native embedder encodes the input text ‘_metric spaces_’, and
uses the resulting 384-dimensional vector in the nearest neighbor
search. See [text embeddings made
simple](https://blog.vespa.ai/text-embedding-made-simple/) for
details.

<pre>
curl \
 --json "
  {
   'yql': 'select title,url from articles where {targetHits:10}nearestNeighbor(content_embeddings, q)',
   input.query(q)': 'embed(metric spaces)' 
  }" \
 https://vespaendpoint/search/
</pre>

### Semantic vector search

The `targetHits` variable is the target number of **articles** the
nearest neighbors the search should expose to Vespa
[ranking](https://docs.vespa.ai/en/ranking.html) phases. Selecting
articles overcomes the article diversity issue associated with a
paragraph index, avoiding that all closest retrieved nearest neighbors
are from the same article.

### Hybrid search 

This query example combines the exact search with semantic search,
a hybrid combination that has demonstrated [strong zero-shot
accuracy](https://blog.vespa.ai/improving-zero-shot-ranking-with-vespa-part-two/).

<pre>
curl \
 --json "
  {
   'yql': 'select title,url from articles where (userQuery())  or ({targetHits:10}nearestNeighbor(content_embeddings, q))',
   input.query(q)': 'embed(metric spaces)', 
   'query': 'metric spaces',
   'ranking': 'hybrid'
  }" \
 https://vespaendpoint/search/
</pre>

The _userQuery()_ matches against the full article across all
paragraphs and the title. Searching across all the fields improves
recall of the traditional text retrieval component. The semantic
_nearestNeighbor()_ component searches at the paragraph level,
finding the closest paragraphs in the paragraph embedding space.
Developers can also use multiple _nearestNeighbor_ query operators
in the query; see the [nearest neighbor search in the Vespa
guide](https://docs.vespa.ai/en/nearest-neighbor-search-guide.html#multiple-nearest-neighbor-search-operators-in-the-same-query).
Multiple _nearestNeighbor_ operators in the same query are convenient
for query rewrites and expansions —notice also that the query request
includes a [ranking](https://docs.vespa.ai/en/ranking.html) parameter.

### Ranking

Vespa allows [declarative rank
expressions](https://docs.vespa.ai/en/ranking-expressions-features.html) in
the schema. The existing _distance(dimension, name)_ rank feature
now also supports mapped-indexed tensor fields and return the
distance of the closest vector. With support for searching multi-vector
fields, two new rank features are introduced: _closest(name)_ and
_closest(name, label)_. The optional label is useful when querying
with multiple [labeled nearestNeighbor query
operators](https://docs.vespa.ai/en/nearest-neighbor-search-guide.html#multiple-nearest-neighbor-search-operators-in-the-same-query).
The output of the closest feature is a tensor with one mapped
dimension and one point (with a value of 1). For example:

<pre>
tensor&lt;float&gt;(p{}):{ {"p":1: 1.0} }
</pre>

In this example, the vector with label 1 is the closest paragraph
to the query, which retrieved the document into Vespa ranking phases.

The following rank-profile orders the articles by the maximum
paragraph cosine similarity using the mentioned distance feature.
The
[match-features](https://docs.vespa.ai/en/reference/schema-reference.html#match-features)
are used to return the closest mapped dimension label. This allows
the developer to present the best matching paragraph on the search
result page.

<pre>
rank-profile semantic inherits default {
   inputs {
      query(q) tensor&lt;float&gt;(x[384])
    }
   first-phase {
  	expression: cos(closeness(field, paragraph_embeddings))
   }
   match-features: closest(paragraph_embeddings)
}
</pre>

Using [Vespa tensors
expressions](https://docs.vespa.ai/en/tensor-user-guide.html),
developers can also compute distance aggregates, over all the vectors
in the document and also the distance to all the vectors in the
field.

### Result presentation and snippeting

How results are presented to the user is commonly overlooked when
introducing semantic search, and most vector search databases do
not support snippeting or highlighting. With Vespa, developers can
display the best matching paragraph when displaying articles on the
search result page using the closest feature combined with
match-features. Vespa also supports [dynamic
summaries](https://docs.vespa.ai/en/document-summaries.html#dynamic-summaries)
and bolding of query terms in single and multi-valued string fields.


## Implementation

This section lifts the curtain on the multi-vector HNSW indexing
implementation in Vespa.

Vespa uses a custom [HNSW index
implementation](https://docs.vespa.ai/en/approximate-nn-hnsw.html) to
support approximate nearest neighbor search. This is a modified
version of the Hierarchical Navigable Small World (HNSW) [graph
algorithm](https://arxiv.org/abs/1603.09320). To support multiple
vectors per document, some changes were made to the implementation.

The HNSW index consists of a navigable small world graph in a
hierarchy. A graph node corresponds to a single vector in the
document corpus, and is uniquely identified by a _nodeid_. A graph
node exists in 1 to N layers. On each layer, graph nodes are linked
to other nodes that are close in the vector space according to the
[distance
metric](https://docs.vespa.ai/en/reference/schema-reference.html#distance-metric).

The vectors are stored in a tensor field
[attribute](https://docs.vespa.ai/en/attributes.html), and the HNSW
index references these vectors when doing distance calculations.
Each document in the corpus is assigned a unique _docid_, and this
_docid_ is used when accessing the vector(s) from the tensor field
attribute. The HNSW index uses different internal structures based
on the tensor type of the tensor field.


![Graph](/assets/2023-03-29-semantic-search-with-multi-vector-indexing/image4.png "image_tooltip")
<font size="3"><i>Illustration showing how a set of graph nodes are linked together
on each layer in the graph hierarchy. Graph nodes are stored in a
vector data structure where the nodeid provides direct lookup. When
indexing multiple vectors per document, extra metadata is stored
per graph node to uniquely access the vector from the tensor field
attribute. In addition, a structure mapping from docid to nodeids
is maintained.</i></font><br/>

### Single vector per document

The tensor type has one indexed dimension, e.g., `tensor<float>(x[384])`.

The _nodeid_ that identifies a graph node is always equal to the
_docid_, which is used when accessing the vector from the tensor
field attribute. No extra metadata is stored per graph node.

### Multiple vectors per document

The tensor type is mixed with one mapped dimension and one indexed
dimension, e.g. `tensor<float>(p{}, x[384])`.

In this case the _nodeid_ is no longer equal to the _docid_, and
an additional mapping structure is maintained. When inserting the
vectors of a new document into the HNSW index, a set of graph nodes
with corresponding unique _nodeids_ are allocated. Each graph node
stores the tuple _{docid, vectorid}_ as metadata. This is used when
accessing the vector corresponding to that graph node from the
tensor attribute field. The _vectorid_ is a number in the range
_[0, num-vectors-for-that-document>_. When removing the vectors of
a document from the HNSW index, the mapping from _docid_ to set of
_nodeids_ is used to find the graph nodes to be removed.

The greedy search algorithm that finds the K closest neighbors to
a query vector is slightly altered compared to the single-vector
case. The greedy search continues until graph nodes with K unique
_docids_ are found. Among these the graph node (vector), each _docid_
closest to the query vector is chosen. The result is the K nearest
_docids_ of the query vector.

The following summarized the changes to the HNSW index implementation:

* Extend the graph node to store a _{docid, vectorid}_ tuple. This
is needed to uniquely access the vector represented by the graph
node.  
* Maintain a mapping from _docid_ to set of _nodeids_.  
* Change the greedy search algorithm to avoid returning duplicate
documents.


## Performance Considerations

To measure the performance implications of indexing multiple vectors
per document the [wikipedia-22-12-simple-embeddings](https://huggingface.co/datasets/Cohere/wikipedia-22-12-simple-embeddings)
dataset was used. This consists of 485851 paragraphs across 187340
Wikipedia articles. Each text paragraph was converted to a
384-dimensional vector embedding using the
[minilm-l6-v2](https://cloud.vespa.ai/en/model-hub#available-models)
transformer model using Vespa’s [embedder
](https://docs.vespa.ai/en/embedding.html#bertbase-embedder)functionality.
Two schemas were created and corresponding feed files. In both setups, the size of the dataset was 746 MB (485851 * 384 * 4).

* Paragraph: 485851 documents with one vector embedding (paragraph)
per document.  
* Article 187340 documents with multiple vector
embeddings (paragraphs) per document, 2.59 vectors on average per document.

The performance tests were executed on a [AWS EC2
c6id.metal](https://aws.amazon.com/ec2/instance-types/c6i/) instance
with 128 vCPUs, 256 GB Memory, and 4x1900 NVMe SSD. 64 vCPUs were
reserved for the test. The following was measured:

* Total feed time and throughput.  
* End-to-end average query latency when using the
[nearestNeighbor](https://docs.vespa.ai/en/reference/query-language-reference.html#nearestneighbor)
query operator, asking for _targetHits=100_.

<style>
  table, th, td {
    border: 1px solid black;
  }
  th, td {
    padding: 5px;
  }
</style>

<table>
  <tr>
   <td> </td> <td><strong>Total feed time (seconds)</strong>
   </td> <td><strong>Throughput</strong>
  <strong>(vectors / second)</strong>
   </td> <td><strong>Throughput (documents / second)</strong> </td>
   <td><strong>Throughput </strong>
  <strong>(MB / second)</strong>
   </td> <td><strong>Avg query latency (ms)</strong> </td>
  </tr> <tr>
   <td>Paragraph (single-vector) </td> <td>88 </td> <td>5521 </td>
   <td>5521 </td> <td>8.48 MB </td> <td>2.56 </td>
  </tr> <tr>
   <td>Wiki (multi-vector) </td> <td>97 </td> <td>5009 </td> <td>1931
   </td> <td>7.69 MB </td> <td>3.43 </td>
  </tr>
</table>
<br/>


As seen in the results above, the performance differences between
the two cases are small. Feeding to the HNSW index when having
multiple vectors per document takes 10% longer than in the single
vector case, and the average query latency is 34% higher. These
differences are explained by:

* The HNSW index stores more information per graph node, and the
greedy search algorithm must consider document-level uniqueness.

* Accessing a single vector in a mixed tensor field attribute (e.g.,
tensor&lt;float&gt;(p{},x[384]) using the tuple _{docid, vectorid}_
requires an extra memory access and calculations to locate the
vector in memory.

## Unlocking multi-vector tensor indexing use cases

As demonstrated in previous sections, multi-vector representation
and indexing support in Vespa makes it easier to implement vector
search over longer documents. In addition, it unlocks many use cases
involving searching in multi-vector representations.

### ColBERT end-to-end-retrieval

[ColBERT](https://blog.vespa.ai/pretrained-transformer-language-models-for-search-part-3/)
is a multi-vector representation model built over
[BERT](https://huggingface.co/blog/bert-101), where each wordpiece
in the text is represented by an n-dimensional vector. This contrasts
single vector representation models that perform pooling of the
output vectors into a single vector representation. Multi-vector
representations have demonstrated higher generalizability than
single-vector models in a zero-shot search ranking setting. With
multi-vector indexing support, it’s straightforward to implement
end-to-end retrieval using ColBERT with Vespa, while previously,
one could only use ColBERT as a re-ranking model.
<pre>
field colbert_tokens type tensor&lt;float&gt;(t{}, x[128]) 
</pre>

### Word2Vec

[Word2vec](https://en.wikipedia.org/wiki/Word2vec) is one of the
early ways to use neural networks for text search and classification.
Unlike the more recent Transformer-based variants where word vectors
are contextualized by self-attention, the word vector representation
of a word does not change depending on other words in the text.
With multi-vector indexing, it’s trivial to represent word vectors
in Vespa.
<pre>
field word2vec type tensor&lt;float&gt;(word{}, x[300]) 
</pre>

## Multi-modal product search

Multi-vector indexing is particularly useful for product and
[e-commerce applications
](https://docs.vespa.ai/en/use-case-shopping.html)where the product
has lots of metadata to[
filter](https://blog.vespa.ai/constrained-approximate-nearest-neighbor-search/)
and rank on and where the product metadata is [constantly
evolving](https://docs.vespa.ai/en/partial-updates.html#use-cases).

Using vector representations of product images, produced by
[text-to-image](https://blog.vespa.ai/text-image-search/) models
like [CLIP](https://openai.com/research/clip) has become a popular
method for improving product search. With Vespa multi-vector indexing,
e-commerce applications can easily search multiple product photos
without introducing fan-out complexity. Vespa also allows using
multi-vector indexing for multiple fields in the same schema.

<pre>
field image_clip_embeddings type tensor&lt;float&gt;(i{}, x[512])
field product_bullet_embeddings type tensor&lt;bfloat16&gt;(p{},x[384])
field product_embedding type tensor&lt;int8&gt;(x[256])
</pre>

Using multiple_ nearestNeighbor_ search query operators in the same
query request, coupled with a ranking function, e-commerce apps can
retrieving efficiently over multiple vector fields and expose the
retrieved products to [ML powered ranking
functions](https://blog.vespa.ai/improving-product-search-with-ltr-part-three/).


## Summary

This post introduced the challenges developers face while trying
to fit long text documents into the narrow context window of
Transformer-based vector embedding models and how Vespa’s multi-vector
HNSW indexing support greatly simplifies the process and unlocks
new use cases without complicated relationship modeling and serving
architectures. Multi-vector indexing is available from Vespa 8.144.19.

Get started with Vespa multi-vector indexing using the [multi-vector
indexing sample
application](https://github.com/vespa-engine/sample-apps/tree/master/multi-vector-indexing).
The sample application can be deployed locally using the Vespa
container image or using [Vespa Cloud](https://cloud.vespa.ai/).
Got questions? Join the community in [Vespa Slack](http://slack.vespa.ai/).



[^1]: Pre-training and fine-tuning the model using 256 wordpiece tokens instead of 128 (2x) would increase the computational training budget by 4x due to quadratic self-attention complexity.

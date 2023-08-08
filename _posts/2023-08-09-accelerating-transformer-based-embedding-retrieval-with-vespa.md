--- 
layout: post
title: "Accelerating Transformer-based Embedding Retrieval with Vespa" 
author: jobergum 
date: '2023-08-08' 
image: assets/2023-08-09-accelerating-transformer-based-embedding-retrieval-with-Vespa/appic-PvIB1FU4v7Y-unsplash.jpg
image_credit: 'Photo by <a href="https://unsplash.com/@appic_cc?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Appic</a> on <a href="https://unsplash.com/photos/PvIB1FU4v7Y?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>'
skipimage: true 
tags: [] 
excerpt: 'In this post, we’ll see how to accelerate embedding inference and retrieval with little impact on quality. 
We’ll take a holistic approach and deep-dive into both aspects of an embedding retrieval system: Embedding inference and retrieval with nearest neighbor search.'
---

![Decorative image](/{{ page.image }})
<p class="image-credit">{{ page.image_credit }}</p>

In this post, we’ll see how to accelerate embedding inference and retrieval with little impact on quality. 
We’ll take a holistic approach and deep-dive into both aspects of an embedding retrieval system: Embedding inference and retrieval with nearest neighbor search.

## Introduction

The fundamental concept behind text embedding models is transforming
textual data into a continuous vector space, wherein similar items
are brought closer together, and dissimilar ones are pushed farther
apart. Mapping multilingual texts into a unified vector embedding
space makes it possible to represent and compare queries and documents
from various languages within this shared space. By using contrastive
representation learning with retrieval data examples, we can make
embedding representations useful for retrieval with nearest neighbor
search.


![Overview](/assets/2023-08-09-accelerating-transformer-based-embedding-retrieval-with-Vespa/image1.png)

A search system using embedding retrieval consists of two primary
processes:

* Embedding inference, using an embedding model to map text to a
point in a vector space of D dimensions.  
* Retrieval in the D dimensional vector space using nearest neighbor search.

This blog post covers both aspects of an embedding retrieval system
and how to accelerate them, while also paying attention to the task
accuracy because what’s the point of having blazing fast but highly
inaccurate results?


## Transformer Model Inferencing

The most popular text embedding models are typically based on
_encoder-only_ Transformer models (such as BERT). We need a
high-level understanding of the complexity of encoder-only transformer
language models (without going deep into neural network architectures).

>Inference complexity from the transformer architecture attention
mechanism scales quadratically with input sequence length. 

![BERT embedder](/assets/2023-08-09-accelerating-transformer-based-embedding-retrieval-with-Vespa/image4.png)
<font size="2"><i>Illustration of obtaining a single vector representation of the
text 'a new day' through BERT.</i></font><br/>

The BERT model has a typical input
length limitation of 512 tokens, so the tokenization process truncates
the input to avoid exceeding the architecture’s maximum length.
Embedding models might also truncate the text at a lower limit than
the theoretical limit of the neural network to improve quality and
reduce training costs, as computational complexity is quadratic
with input sequence length for both training and inference.  The
last pooling operation compresses the token vectors into a single
vector representation. A common pooling technique is averaging the
token vectors.

It's worth noting that some models may not perform pooling and
instead represent the text with [multiple
vectors](https://blog.vespa.ai/pretrained-transformer-language-models-for-search-part-3/),
but that aspect is beyond the scope of this blog post.

![Inference cost versus sequence length](/assets/2023-08-09-accelerating-transformer-based-embedding-retrieval-with-Vespa/image2.png)
<font size="2"><i>Illustration of BERT inferenec cost versus sequence input length (sequence^2).</i></font><br/>

We use 'Inference cost' to refer to the computational resources
required for a single inference pass with a given input sequence
length. The graph depicts the relationship between the sequence
length and the squared compute complexity, demonstrating its quadratic
nature. Latency and throughput can be adjusted using different
techniques for parallelizing computations. See [model serving at
scale](https://blog.vespa.ai/ml-model-serving-at-scale/) for a
discussion on these techniques in Vespa.

**Why does all of this matter?** For retrieval systems, text queries
are usually much shorter than text documents, so invoking embedding
models for documents costs more than encoding shorter questions.

Sequence lengths and quadratic scaling are some of the reasons why
using [frozen document-size
embeddings](https://blog.vespa.ai/tailoring-frozen-embeddings-with-vespa/)
are practical at scale, as it avoids re-embedding documents when
the model weights are updated due to re-training the model. Similarly,
query embeddings can be cached for previously seen queries as long
as the model weights are unchanged. The asymmetric length properties
can also help us design a retrieval system architecture for scale.


* Asymmetric model size: Use different-sized models for encoding
queries and documents (with the same output embedding dimensionality).
See [this paper](https://arxiv.org/abs/2304.01016) for an example.
* Asymmetric batch size: Use batch on-demand computing for embedding
documents, using auto-scaling features, for example, with [Vespa
Cloud](https://cloud.vespa.ai/en/autoscaling).  
* Asymmetric compute architecture: Use GPU acceleration for document inference but CPU
for query inference.

The final point is that reporting embedding inference latency or
throughput without mentioning input sequence length provides little
insight.


## Choose your Fighter

When deciding on an embedding model, developers must strike a balance
between quality and serving costs.

![Triangle of tradeoffs](/assets/2023-08-09-accelerating-transformer-based-embedding-retrieval-with-Vespa/image3.png)

These serving-related costs are all roughly linear with model
parameters and embedding dimensionality (for a given sequence
length). For example, using an embedding model with 768 dimensions
instead of 384 increases embedding storage by 2x and nearest neighbor
search compute by 2x.

Accuracy, however, is not nearly linear, as demonstrated on the
[MTEB leaderboard](https://huggingface.co/spaces/mteb/leaderboard).

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
   <td><strong>Model</strong> </td> <td><strong>Dimensionality</strong>
   </td> <td><strong>Model params (M)</strong> </td> <td><strong>Accuracy
   Average (56 datasets)</strong> </td> <td><strong>Accuracy Retrieval
   (15 datasets)</strong> </td>
  </tr> <tr>
   <td>Small </td> <td>384 </td> <td>118 </td> <td>57.87 </td>
   <td>46.64 </td>
  </tr> <tr>
   <td>Base </td> <td>768 </td> <td>278 </td> <td>59.45 </td>
   <td>48.88 </td>
  </tr> <tr>
   <td>Large </td> <td>1024 </td> <td>560 </td> <td>61.5 </td>
   <td>51.43 </td>
  </tr>
</table>
<font size="2"><i>A comparison of the E5 <b>multilingual</b> models — accuracy numbers from the <a href="https://huggingface.co/spaces/mteb/leaderboard">MTEB
leaderboard</a>.</i></font>

In the following sections, we use the small E5 multilingual variant,
which gives us reasonable accuracy for a much lower cost than the
larger sister E5 variants. The small model inference complexity
also makes it servable on CPU architecture, allowing iterations and
development locally without [managing GPU-related infrastructure
complexity](https://vickiboykis.com/2023/07/18/what-we-dont-talk-about-when-we-talk-about-building-ai-apps/).


## Exporting E5 to ONNX format for accelerated model inference

To export the embedding model from the Huggingface model hub to
[ONNX](https://onnx.ai) format for inference in Vespa, we can use the [Transformer
Optimum](https://huggingface.co/docs/optimum/index) library:

```
$ optimum-cli export onnx --task sentence-similarity -m intfloat/multilingual-e5-small model-dir
```

The above exports the model without any optimizations. The optimum
client also allows specifying [optimization
levels](https://huggingface.co/docs/optimum/onnxruntime/usage_guides/optimization#optimizing-a-model-with-optimum-cli),
here using the highest optimization level usable for serving on the
CPU.

The above commands export the model to ONNX format that can be
imported and used with the [Vespa Huggingface
embedder](https://docs.vespa.ai/en/embedding.html#huggingface-embedder).
Using the Optimum generated ONNX and tokenizer configuration files,
we configure Vespa with the following in the Vespa [application
package](https://docs.vespa.ai/en/application-packages.html)
[services.xml](https://docs.vespa.ai/en/application-packages.html#services.xml)
file:

```xml
<component id="e5" type="hugging-face-embedder">
  <transformer-model path="model/model.onnx"/>
  <tokenizer-model path="model/tokenizer.json"/>
</component>
```

These two simple steps are all we need to start using the multilingual
E5 model to embed queries and documents with Vespa.
We can also quantize the optimized ONNX model, for example, using
the [optimum
library](https://huggingface.co/docs/optimum/onnxruntime/usage_guides/quantization)
or onnxruntime quantization like
[this](https://github.com/vespa-engine/sample-apps/blob/master/msmarco-ranking/src/main/python/model_quantizer.py).
Quantization (post-training) converts the float32 model weights (4
bytes per weight) to byte (int8), enabling faster inference on the
CPU.


## Performance Experiments

To demonstrate the many tradeoffs, we assess the mentioned small
E5 multilanguage model on the Swahili(SW) split from the
[MIRACL](https://project-miracl.github.io/) (_Multilingual Information
Retrieval Across a Continuum of Languages_) dataset.

<table>
  <tr>
   <td><strong>Dataset</strong> </td> <td><strong>Language</strong>
   </td> <td><strong>Documents</strong> </td> <td><strong>Avg
   document tokens</strong> </td> <td><strong>Queries</strong> </td>
   <td><strong>Avg query tokens</strong> </td> <td><strong>Relevance
   Judgments </strong> </td>
  </tr> <tr>
   <td>MIRACL sw </td> <td><a
   href="https://en.wikipedia.org/wiki/Swahili_language">Swahili
   </a> </td> <td>131,924 </td> <td>63 </td> <td>482 </td> <td>13
   </td> <td>5092 </td>
  </tr>
</table>
<font size="2"><i>Dataset characteristics; tokens are the number of language model
token identifiers. Since Swahili is a low-resource language, the
LM tokenization uses more tokens to represent similar byte-length
texts than for more popular languages such as English.</i></font><br/>
We experiment with post-training quantization of the model (not the
output vectors) to document the impact quantization has on retrieval
effectiveness (NDCG@10). We use [this
routine](https://github.com/vespa-engine/sample-apps/blob/master/msmarco-ranking/src/main/python/model_quantizer.py)
to quantize the model (We don’t use optimum for this due to [this
issue](https://github.com/huggingface/optimum/issues/1243) -[ fixed
in v 1.11](https://github.com/huggingface/optimum/releases)).

We then study the serving efficiency gains (latency/throughput) on
the same laptop-sized hardware using a quantized model versus a
full precision model.

All experiments are run on an M1 Pro (arm64) laptop with 8 v-CPUs
and 32GB of memory, using the open-source [Vespa container
image](https://hub.docker.com/r/vespaengine/vespa/). No GPU
acceleration and no need to manage CUDA driver compatibility, huge
container images due to CUDA dependencies, or forwarding host GPU
devices to the container.

* We use the [multilingual-search Vespa sample
application](https://github.com/vespa-engine/sample-apps/tree/master/multilingual-search)
as the starting point for these experiments. This sample app was
introduced in [Simplify search with multilingual embedding
models](https://blog.vespa.ai/simplify-search-with-multilingual-embeddings/).
* We use the
[NDCG@10](https://en.wikipedia.org/wiki/Discounted_cumulative_gain) metric
to evaluate ranking effectiveness. When performing model optimizations,
it’s important to pay attention to the impact on the task. This is
stating the obvious, but still, many talk about accelerations and
optimizations without mentioning task accuracy degradations.  
* We measure the throughput of indexing text documents in Vespa. This
includes embedding inference in Vespa using the [Vespa Huggingface
embedder](https://docs.vespa.ai/en/embedding.html#huggingface-embedder),
storing the embedding vector in Vespa, and regular inverted indexing
of the title and text field. We use the
[vespa-cli](https://docs.vespa.ai/en/vespa-cli.html) feed option
as the feeding client. 
* We use the [Vespa fbench
tool](https://docs.vespa.ai/en/reference/vespa-cmdline-tools.html#vespa-fbench)
to drive HTTP query load using HTTP POST against the [Vespa query
api.](https://docs.vespa.ai/en/query-api.html) 
* Batch size in Vespa embedders is one for document and query inference.  
* There is no caching of query embedding inference, so repeating the same query
text while benchmarking will trigger a new embedding inference.

Sample Vespa JSON formatted feed document (prettified) from the
[MIRACL](https://project-miracl.github.io/) dataset.

```json
{
    "put": "id:miracl-sw:doc::2-0",
    "fields": {
        "title": "Akiolojia",
        "text": "Akiolojia (kutoka Kiyunani \u03b1\u03c1\u03c7\u03b1\u03af\u03bf\u03c2 = \"zamani\" na \u03bb\u03cc\u03b3\u03bf\u03c2 = \"neno, usemi\") ni somo linalohusu mabaki ya tamaduni za watu wa nyakati zilizopita. Wanaakiolojia wanatafuta vitu vilivyobaki, kwa mfano kwa kuchimba ardhi na kutafuta mabaki ya majengo, makaburi, silaha, vifaa, vyombo na mifupa ya watu.",
        "doc_id": "2#0",
        "language": "sw"
    }
}
```
<table>
  <tr>
   <td><strong>Model</strong> </td> <td><strong>Model size (MB)</strong>
   </td> <td><strong>NDCG@10</strong> </td>
   <td><strong>Docs/second</strong> </td> <td><strong>Queries/second
   (*)</strong> </td>
  </tr> <tr>
   <td>float32 </td> <td>448 </td> <td>0.675 </td> <td>137 </td>
   <td>340 </td>
  </tr> <tr>
   <td>Int8 (Quantized) </td> <td>112 </td> <td>0.661 </td> <td>269
   </td> <td>640 </td>
  </tr>
</table>
<font size="2"><i>Comparison of embedding inference in Vespa using a full precision
model with float32 weights against a quantized model using int8
weights. This is primarily benchmarking embedding inference. See
the next section for a deep dive into the experimental setup.</i></font><br/>
There is a small drop in retrieval accuracy from an NDCG@10 score
of `0.675` to `0.661` (2%), but a huge gain in embedding inference
efficiency. Indexing throughput increases by 2x, and query throughput
increases close to 2x. The throughput measurements are end-to-end,
either using vespa-cli feed or vespa-fbench. The difference in query
versus document sequence length largely explains the query and
document throughput difference (the quadratic scaling properties).

### Query embed latency and throughput

Throughput is one way to look at it, but what about query serving
latency? We analyze query latency of the quantized model by gradually
increasing the load until the CPU is close to 100% utilization using
[vespa-fbench](https://docs.vespa.ai/en/performance/vespa-benchmarking.html#vespa-fbench)
input format for POST requests.

```
/search/
{"yql": "select doc_id from doc where rank(doc_id contains \"71#13\",{targetHits:1}nearestNeighbor(embedding,q))", "input.query(q)": "embed(query:Bandari kubwa nchini Kenya iko wapi?)", "ranking": "semantic", "hits": 0}
```

The above query template tests Vespa end-to-end but does NOT perform
a global nearest neighbor search as the query uses the [rank
operator](https://docs.vespa.ai/en/reference/query-language-reference.html#:~:text=contain%20ghi.-,rank,-The%20first%2C%20and)
to retrieve by doc_id, and the second operand computes the
nearestNeighbor. This means that the nearest neighbor “search” is
limited to a single document in the index. This experimental setup
allows us to test everything end to end except the cost of exhaustive
search through all documents.

This part of the experiment focuses on the embedding model inference
and not nearest neighbor search performance. We use all the queries
in the dev set (482 unique queries). Using vespa-fbench, we simulate
load by increasing the number of concurrent clients executing queries
with sleep time 0 (-c 0) while observing the end-to-end latency and
throughput.

```
$ vespa-fbench -P -q queries.txt -s 20 -n $clients -c 0 localhost 8080
```

<table>
  <tr>
   <td><strong>Clients </strong> </td> <td><strong>Average
   latency</strong> </td> <td><strong>95p latency</strong> </td>
   <td><strong>Queries/s</strong> </td>
  </tr> <tr>
   <td>1 </td> <td>8 </td> <td>10 </td> <td>125 </td>
  </tr> <tr>
   <td>2 </td> <td>9 </td> <td>11 </td> <td>222 </td>
  </tr> <tr>
   <td>4 </td> <td>10 </td> <td>13 </td> <td>400 </td>
  </tr> <tr>
   <td>8 </td> <td>12 </td> <td>19 </td> <td>640 </td>
  </tr>
</table>
<font size="2"><i>Vespa query embedder performance.</i></font><br/>
As concurrency increases, the latency increases slightly, but not
much, until saturation, where latency will climb rapidly with a
hockey-stick shape due to queuing for exhausted resources.

In this case, latency is the complete end-to-end HTTP latency,
including HTTP overhead, embedding inference, and dispatching the
embedding vector to the Vespa content node process. Again, it does
not include nearest neighbor search, as the query limits the retrieval
to a single document.


### Putting it all together - adding nearest neighbor search

In the previous section, we focused on the embedding inference
throughput and latency. In this section, we change the Vespa query
specification to perform an exact nearest neighbor search over all
documents. This setup measures the end-to-end deployment, including
HTTP overhead, embedding inference, and embedding retrieval using
Vespa [exact nearest neighbor
search](https://docs.vespa.ai/en/nearest-neighbor-search.html).
With exact search, no retrieval error is introduced by using
approximate search algorithms.

```
/search/
{"yql": "select doc_id from doc where {targetHits:10}nearestNeighbor(embedding,q)", "input.query(q)": "embed(query:Bandari kubwa nchini Kenya iko wapi?)", "ranking": "semantic", "hits": 10}
```

<table>
  <tr>
   <td><strong>Clients </strong> </td> <td><strong>Average
   latency</strong> </td> <td><strong>95p latency</strong> </td>
   <td><strong>Queries/s</strong> </td>
  </tr> <tr>
   <td>1 </td> <td>18 </td> <td>20.35 </td> <td>55.54 </td>
  </tr> <tr>
   <td>2 </td> <td>19.78 </td> <td>21.90 </td> <td>101.09 </td>
  </tr> <tr>
   <td>4 </td> <td>23.26 </td> <td>26.10 </td> <td>171.95 </td>
  </tr> <tr>
   <td>8 </td> <td>32.02 </td> <td>44.10 </td> <td>249.79 </td>
  </tr>
</table>
<font size="2"><i>Vespa query performance with embedding inference and exact nearest neighbor search.</i></font><br/>
With this setup, the system can support up to 250 queries/second
on a laptop with a 95 percentile below 50ms. If we don’t need to
support 250 queries/s but we want to lower serving latency, we can
configure Vespa to use [multiple
threads](https://docs.vespa.ai/en/performance/sizing-search.html#reduce-latency-with-multi-threaded-per-search-execution)
to evaluate the exact nearest neighbor search. More threads per
search allow parallelization of the exact nearest neighbor search
over several threads per query request. In this case, we allow Vespa
to distribute the search using four threads per query by adding
this tuning element to the
[services.xml](https://docs.vespa.ai/en/reference/services.html)
configuration file:

```xml
<engine>
  <proton>
    <tuning>
      <searchnode>
        <requestthreads>
          <persearch>4</persearch>
        </requestthreads>
      </searchnode>
    </tuning>
  </proton>
 </engine>
```

The number of distance calculations (compute) per query stays the
same, but by partitioning and parallelization of the workload, we
reduce the serving latency.

<table>
  <tr>
   <td><strong>Clients </strong> </td> <td><strong>Average
   latency</strong> </td> <td><strong>95p latency</strong> </td>
   <td><strong>Queries/s</strong> </td>
  </tr> <tr>
   <td>1 </td> <td>11.57 </td> <td>13.60 </td> <td>86.39 </td>
  </tr> <tr>
   <td>2 </td> <td>14.94 </td> <td>17.80 </td> <td>133.84 </td>
  </tr> <tr>
   <td>4 </td> <td>20.40 </td> <td>27.30 </td> <td>196.07 </td>
  </tr>
</table>
<font size="2"><i>Performance using four threads per search query.</i></font><br/>
With this change, end-to-end serving latency drops from average
18ms to 11.6ms. Note that the thread per search Vespa setting does
not impact the embedding inference. Reducing serving latency is more important than maximizing the
throughput for many low-traffic use cases. The threads per search
setting allow making that tradeoff. It can also be handy if your
organization reserved instances from a cloud provider and your CFO
asks why the instances are underutilized while users complain about
high serving latency.


### Putting it all together 2 - enabling approximate nearest neighbor search

Moving _much_ beyond a corpus of 100k of documents, exact nearest
neighbor search throughput is often limited by [memory
bandwidth](https://en.wikipedia.org/wiki/Memory_bandwidth) - moving
document corpus vector data to the CPU for similarity computations.
By building approximate nearest neighbor search data structures
during indexing, we can limit the number of vectors that need to
be compared with the query vector, which reduces memory reads per
query, lowers latency, and increases throughput by several orders
of magnitude. So what’s the downside? In short:

* Adding approximate nearest neighbor (ANN) index structures increases
resource usage during indexing and consumes memory in addition to
the vector data.  
* It impacts retrieval quality since the nearest
neighbor search is approximate. A query might not retrieve the
relevant documents due to the error introduced by the approximate
search.

Retrieval quality degradation is typically measured and quantified
using overlap@k, comparing the true nearest neighbors from an exact
search with the nearest neighbors returned by the approximate search.

**In our opinion, this is often overlooked when talking about embedding
models, accuracy, and vector search. Speeding up the search with
ANN techniques does impact retrieval quality**. For example, entries
on the [MTEB leaderboard](https://huggingface.co/spaces/mteb/leaderboard)
are certainly not using any approximation, so in practice, the
results will not be as accurate if deployed using approximate vector
search techniques.

In the following, we experiment with Vespa's three [HNSW indexing
parameters](https://docs.vespa.ai/en/approximate-nn-hnsw.htm)  and
observe how they impact NDCG@10. This setup is a slightly unusual
experimental setup since instead of calculating the overlap@10
between exact and approximate, we are using the NDCG@10 retrieval
metric directly. In the context of dense text embedding models for
search, we believe this experimental setup is the best as it allows
us to quantify the exact impact of introducing approximate search
techniques.

There are two [HNSW index time](https://docs.vespa.ai/en/reference/schema-reference.html#index-hnsw)
parameters in Vespa. Changing any of those requires rebuilding the
HNSW graph, so we only test with two permutations of these
two parameters. For each of them, we run an evaluation with a query
time setting, which explores more nodes in the graph, making the
search more accurate (at the cost of more distance calculations).

The query time
[hnsw.exploreAdditionalHits](https://docs.vespa.ai/en/reference/query-language-reference.html#hnsw-exploreadditionalhits)
is an optional parameter of the Vespa nearestNeighbor query operator,
and the hnsw index time settings are configured in [the
schema](https://docs.vespa.ai/en/reference/schema-reference.html#index-hnsw).

```json
{"yql": "select doc_id from doc where {targetHits:10, hnsw.exploreAdditionalHits:300}nearestNeighbor(embedding,q)", "input.query(q)": "embed(query:Je, bara Asia lina visiwa vingapi?)", "ranking": "semantic", "hits": 10}
```
<font size="2"><i>Vespa query request using hnsw.exploreAdditionalHits</i></font><br/>

<table>
  <tr>
   <td><strong>max-links-per-node</strong> </td>
   <td><strong>neighbors-to-explore-at-insert</strong> </td>
   <td><strong>hnsw.exploreAdditionalHits </strong> </td>
   <td><strong>NDCG@10</strong> </td>
  </tr> <tr>
   <td>16 </td> <td>100 </td> <td>0 </td> <td>0.5115 </td>
  </tr> <tr>
   <td>16 </td> <td>100 </td> <td>100 </td> <td>0.6415 </td>
  </tr> <tr>
   <td>16 </td> <td>100 </td> <td>300 </td> <td>0.6588 </td>
  </tr> <tr>
   <td>32 </td> <td>500 </td> <td>0 </td> <td>0.6038 </td>
  </tr> <tr>
   <td>32 </td> <td>500 </td> <td>100 </td> <td>0.6555 </td>
  </tr> <tr>
   <td>32 </td> <td>500 </td> <td>300 </td> <td>0.6609 </td>
  </tr>
</table>
<font size="2"><i>Summarization of the HNSW parameters and the impact on NDCG@10.</i></font><br/>
As the table above demonstrates, we can reach the same NDCG@10 as
the exact search by using `max-links-per-node` 32,
`neighbors-to-explore-at-insert` 500, and `hnsw.exploreAdditionalHits` 300. 
The high `hnsw.exploreAdditionalHits` setting indicates that we could
alter the index time settings upward, but we did not experiment
further. Note the initial HNSW setting in row 1 and the significant
negative impact on retrieval quality.

As a rule of thumb, if increasing `hnsw.exploreAdditionalHits` hits
a plateau in either overlap@k or the end metric we are optimizing
for; it’s time to look at increasing the quality of the HNSW graph
by increasing the index time settings (`max-links-per-node` and
`neighbors-to-exlore-at-insert`).

With retrieval accuracy retained, we can use those HNSW settings
to re-evaluate the serving performance of both indexing and queries
and compare it with exact search (where we did not have to evaluate
the accuracy impact).

Without HNSW structures, we could index at 269 documents/s. With
HNSW (32,500), indexing throughput drops to 230 documents/s. Still,
most of the cost is in the embedding inference part, but there is
a noticeable difference. The relative change would be larger if we
just evaluated indexing without embedding inference.

<table>
  <tr>
   <td>Clients </td> <td>Average latency </td> <td>95p latency </td>
   <td>Queries/s </td>
  </tr> <tr>
   <td>1 </td> <td>12.78 </td> <td>15.80 </td> <td>78.20 </td>
  </tr> <tr>
   <td>2 </td> <td>13.08 </td> <td>15.70 </td> <td>152.83 </td>
  </tr> <tr>
   <td>4 </td> <td>15.10 </td> <td>18.10 </td> <td>264.89 </td>
  </tr> <tr>
   <td>8 </td> <td>19.66 </td> <td>28.90 </td> <td>406.76 </td>
  </tr>
</table>


After introducing HNSW indexing for approximate search, our
laptop-sized deployment can support 400 QPS (compared to 250 with
exact search) with a 95 percentile latency below 30 ms.


## Summary

Using the open-source Vespa container image, we've delved into
exploring and experimenting with both embedding inference and
retrieval right on our laptops. The local experimentation, avoiding
specialized hardware acceleration, holds immense value, as it
eliminates prolonged feedback loops.

Moreover, the same Vespa configuration files suffice for many
deployment scenarios, be it in on-premise setups, on Vespa Cloud,
or locally on a laptop. The beauty lies in the fact that specific
infrastructure for managing embedding inference and nearest neighbor
search as separate infra systems becomes obsolete with [Vespa’s
native embedding
support](https://blog.vespa.ai/enhancing-vespas-embedding-management-capabilities/).

Within this blog post, we've shown how applying post-training
quantization to embedding models yields a substantial improvement
in serving performance without significantly compromising retrieval
quality. Subsequently, our focus shifted towards embedding retrieval
with nearest neighbor search. This allowed us to explore the tradeoffs
between exact and approximate nearest neighbor search methodologies.

A noteworthy advantage of executing embedding inference within Vespa
locally lies in the proximity of vector creation to the vector
storage. To put this into perspective, consider the latency numbers
in this post versus procuring an embedding vector in JSON format
from an embedding API provider situated on a separate continent.
Transmitting vector data across continents commonly incurs delays
of hundreds of milliseconds.

If you are interested to learn more about Vespa; See [Vespa Cloud - getting started](https://cloud.vespa.ai/en/getting-started),
or self-serve [Vespa - getting started](https://docs.vespa.ai/en/getting-started.html). 
Got questions? Join the Vespa community in [Vespa Slack](http://slack.vespa.ai/).

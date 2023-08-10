--- 
layout: post
title: "Representing BGE embedding models in Vespa using bfloat16 " 
author: jobergum 
date: '2023-08-10' 
image: assets/2023-08-10-bge-embedding-models-in-vespa-using-bfloat16/rafael-druck-jq3FQ1hmRa8-unsplash.jpg
image_credit: 'Photo by <a href="https://unsplash.com/@eyesinthesky?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Rafael Drück</a> on <a href="https://unsplash.com/photos/jq3FQ1hmRa8?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>'
skipimage: true 
tags: [] 
excerpt: 'This post demonstrates how to use recently announced BGE embedding models in Vespa. 
We evaluate the effectiveness of two BGE variants on the BEIR trec-covid dataset. Finally, we demonstrate how Vespa’s support for storing and indexing vectors using bfloat16 precision saves 50% of memory and storage footprint with close to zero loss in retrieval quality.'
---

![Decorative image](/{{ page.image }})
<p class="image-credit">{{ page.image_credit }}</p>

This post demonstrates how to use recently announced BGE embedding
models in Vespa. The open-sourced (MIT licensed) BGE models
from the Beijing Academy of Artificial Intelligence (BAAI) perform
strongly on the Massive Text Embedding Benchmark ([MTEB
leaderboard](https://huggingface.co/spaces/mteb/leaderboard)). We
evaluate the effectiveness of two BGE variants on the
[BEIR](https://github.com/beir-cellar/beir) trec-covid dataset.
Finally, we demonstrate how Vespa’s support for storing and indexing
vectors using bfloat16 precision saves 50% of memory and storage
fooprint with close to zero loss in retrieval quality.


## Choose your BGE Fighter

When deciding on an embedding model, developers must strike a balance
between quality and serving costs.


![Triangle of tradeoffs](/assets/2023-08-09-accelerating-transformer-based-embedding-retrieval-with-Vespa/image3.png)

These serving-related costs are all roughly linear with model
parameters and embedding dimensionality (for a given sequence
length). For example, using an embedding model with 768 dimensions
instead of 384 increases embedding storage by 2x and nearest neighbor
search compute by 2x.

Quality, however, is not nearly linear, as demonstrated on the [MTEB
leaderboard](https://huggingface.co/spaces/mteb/leaderboard).

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
   <td><a href="https://huggingface.co/BAAI/bge-small-en">bge-small-en</a>
   </td> <td>384 </td> <td>33 </td> <td>62.11 </td> <td>51.82 </td>
  </tr> <tr>
   <td><a href="https://huggingface.co/BAAI/bge-base-en">bge-base-en</a>
   </td> <td>768 </td> <td>110 </td> <td>63.36 </td> <td>53 </td>
  </tr> <tr>
   <td><a
   href="https://huggingface.co/BAAI/bge-large-en">bge-base-large</a> </td>
   <td>1024 </td> <td>335 </td> <td>63.98 </td> <td>53.9 </td>
  </tr>
</table>
<font size="2"><i>A comparison of the English BGE embedding models — accuracy numbers <a href="https://huggingface.co/spaces/mteb/leaderboard">MTEB
leaderboard</a>. All
three BGE models outperforms OpenAI ada embeddings with 1536
dimensions and unknown model parameters on MTEB</i></font>

In the following sections, we experiment with the small and base
BGE variant, which gives us reasonable accuracy for a much lower
cost than the large variant. The small model inference complexity
also makes it servable on CPU architecture, allowing iterations and
development locally without [managing GPU-related infrastructure
complexity](https://vickiboykis.com/2023/07/18/what-we-dont-talk-about-when-we-talk-about-building-ai-apps/).

## Exporting BGE to ONNX format for accelerated model inference

To use the embedding model from the Huggingface model hub in Vespa
we need to export it to [ONNX](https://onnx.ai/) format. We can use
the [Transformers Optimum](https://huggingface.co/docs/optimum/index)
library for this:

```
$ optimum-cli export onnx --task sentence-similarity -m BAAI/bge-small-en --optimize O3 bge-small-en
```
This exports the small model with the highest [optimization
level](https://huggingface.co/docs/optimum/onnxruntime/usage_guides/optimization#optimizing-a-model-with-optimum-cli)
usable for serving on CPU. We also quantize the optimized ONNX model
using onnxruntime quantization like
[this](https://github.com/vespa-engine/sample-apps/blob/master/msmarco-ranking/src/main/python/model_quantizer.py).
Quantization (post-training) converts the float model weights (4
bytes per weight) to byte (int8), enabling faster inference on the
CPU. As demonstrated in [this blog
post](https://blog.vespa.ai/accelerating-transformer-based-embedding-retrieval-with-vespa/),
quantization accelerates embedding model inference by 2x on CPU with negligible
impact on retrieval quality.

## Using BGE in Vespa

Using the Optimum generated [ONNX](https://onnx.ai/) model and
tokenizer files, we configure the [Vespa Huggingface
embedder](https://docs.vespa.ai/en/embedding.html#huggingface-embedder)
with the following in the Vespa [application
package](https://docs.vespa.ai/en/application-packages.html)
[services.xml](https://docs.vespa.ai/en/application-packages.html#services.xml)
file.

```xml
<component id="bge" type="hugging-face-embedder">
  <transformer-model path="model/model.onnx"/>
  <tokenizer-model path="model/tokenizer.json"/>
  <pooling-strategy>cls</pooling-strategy>
  <normalize>true</normalize>
</component>
```

BGE uses the CLS special token as the text representation vector
(instead of average pooling). We also specify normalization so that
we can use the `prenormalized-angular` [distance
metric](https://docs.vespa.ai/en/reference/schema-reference.html#distance-metric)
for nearest neighbor search. See [configuration
reference](https://docs.vespa.ai/en/reference/embedding-reference.html#huggingface-embedder-reference-config)
for details.

With this, we are ready to use the BGE model to embed queries and
documents with Vespa.

### Using BGE in Vespa schema

The BGE model family does not use instructions for documents like
the [E5
family](https://blog.vespa.ai/simplify-search-with-multilingual-embeddings/),
so we don’t need to prepend the input to the document model with
“passage: “ like with the E5 models. Since we configure the [Vespa
Huggingface
embedder](https://docs.vespa.ai/en/embedding.html#huggingface-embedder) to
normalize the vectors, we use the optimized `prenormalized-angular`
distance-metric for the nearest neighbor search
[distance-metric](https://docs.vespa.ai/en/reference/schema-reference.html#distance-metric).

```
field embedding type tensor<float>(x[384]) {
    indexing: input title . " " . input text | embed | attribute
    attribute {
      distance-metric: prenormalized-angular
    }
}
```

Note that the above does not enable [HNSW
indexing](https://docs.vespa.ai/en/approximate-nn-hnsw.html), see
[this
blog](https://blog.vespa.ai/accelerating-transformer-based-embedding-retrieval-with-vespa/)
post on the tradeoffs related to introducing approximative nearest
neighbor search. The small model embedding is configured with 384
dimensions, while the base model uses 768 dimensions.

```
field embedding type tensor<float>(x[768]) {
    indexing: input title . " " . input text | embed | attribute
    attribute {
      distance-metric: prenormalized-angular
    }
}
```

### Using BGE in queries

The BGE model uses query instructions like the [E5
family](https://blog.vespa.ai/simplify-search-with-multilingual-embeddings/)
that are prepended to the input query text. We prepend the instruction
text to the user query as demonstrated in the snippet below:

```python
query = 'is remdesivir an effective treatment for COVID-19'
body = {
        'yql': 'select doc_id from doc where ({targetHits:10}nearestNeighbor(embedding, q))',
        'input.query(q)': 'embed(Represent this sentence for searching relevant passages: ' + query +  ')', 
        'ranking': 'semantic,
        'hits' : '10' 
 }
response = session.post('http://localhost:8080/search/', json=body)
```
The BGE query instruction is _Represent this sentence for searching
relevant passages:_. We are unsure why they choose a longer query instruction as 
it does hurt efficiency as compute [complexity is
quadratic](https://blog.vespa.ai/accelerating-transformer-based-embedding-retrieval-with-vespa/)
with sequence length.


## Experiments

We evaluate the small and base model on the trec-covid test split
from the [BEIR benchmark](https://github.com/beir-cellar/beir). We
concat the title and the abstract as input to the BEG embedding
models as demonstrated in the Vespa schema snippets in the previous
section.


<table>
  <tr>
   <td><strong>Dataset</strong> </td> <td><strong>Documents</strong>
   </td> <td><strong>Avg document tokens</strong> </td>
   <td><strong>Queries</strong> </td> <td><strong>Avg query
   tokens</strong> </td> <td><strong>Relevance Judgments </strong>
   </td>
  </tr> <tr>
   <td>BEIR trec_covid </td> <td>171,332 </td> <td>245 </td> <td>50
   </td> <td>18 </td> <td>66,336 </td>
  </tr>
</table>
<font size="2"><i>Dataset characteristics; tokens are the number of language model
token identifiers (wordpieces)</i></font>

All experiments are run on an M1 Pro (arm64) laptop with 8 v-CPUs
and 32GB of memory, using the open-source [Vespa container
image](https://hub.docker.com/r/vespaengine/vespa/). No GPU
acceleration and no need to manage CUDA driver compatibility, huge
container images due to CUDA dependencies, or forwarding host GPU
devices to the container.


* We use the [multilingual-search Vespa sample
application](https://github.com/vespa-engine/sample-apps/tree/master/multilingual-search)
as the starting point for these experiments. This sample app was
introduced in [Simply search with multilingual embedding
models](https://blog.vespa.ai/simplify-search-with-multilingual-embeddings/).
* The retrieval quality evaluation uses [NDCG@10](https://en.wikipedia.org/wiki/Discounted_cumulative_gain)
* Both small and base are quantized to improve efficiency on CPU.

Sample [Vespa JSON
formatted](https://docs.vespa.ai/en/reference/document-json-format.html)
feed document (prettified) from the
[BEIR](https://github.com/beir-cellar/beir) trec-covid dataset:

```json
{
  "put": "id:miracl-trec:doc::wnnsmx60",
  "fields": {
    "title": "Managing emerging infectious diseases: Is a federal system an impediment to effective laws?",
    "text": "In the 1980's and 1990's HIV/AIDS was the emerging infectious disease. In 2003\u20132004 we saw the emergence of SARS, Avian influenza and Anthrax in a man made form used for bioterrorism. Emergency powers legislation in Australia is a patchwork of Commonwealth quarantine laws and State and Territory based emergency powers in public health legislation. It is time for a review of such legislation and time for consideration of the efficacy of such legislation from a country wide perspective in an age when we have to consider the possibility of mass outbreaks of communicable diseases which ignore jurisdictional boundaries.",
    "doc_id": "wnnsmx60",
    "language": "en"
  }
}
```

## Evalution results 

<table>
  <tr>
   <td><strong>Model</strong> </td> <td><strong>Model size (MB)</strong>
   </td> <td><strong>NDCG@10 BGE</strong> </td> <td><strong>NDCG@10
   BM25</strong> </td>
  </tr> <tr>
   <td>bge-small-en </td> <td>33 </td> <td>0.7395 </td> <td>0.6823
   </td>
  </tr> <tr>
   <td>bge-base-en </td> <td>104 </td> <td>0.7662 </td> <td>0.6823
   </td>
  </tr>
</table>
<font size="2"><i>Evaluation results for quantized BGE models.</i></font>


We contrast both BGE models with the unsupervised
[BM25](https://docs.vespa.ai/en/reference/bm25.html) baseline from
[this blog
post](https://blog.vespa.ai/simplify-search-with-multilingual-embeddings/).
Both models perform better than the BM25 baseline
on this dataset. We also note that our  NDCG@10 numbers represented
in Vespa is slightly better than reported on the MTEB leaderboard
for the same dataset. We can also observe that the base model
performs better on this dataset, but is also 2x more costly due to
size of embedding model and the embedding dimensionality. The
bge-base model inference could benefit from [GPU
acceleration](https://blog.vespa.ai/enhancing-vespas-embedding-management-capabilities/)
(without quantization).


## Using bfloat16 precision

We evaluate using
[bfloat16](https://en.wikipedia.org/wiki/Bfloat16_floating-point_format)
instead of float for the tensor representation in Vespa. Using
`bfloat16` instead of `float` reduces memory and storage requirements
by 2x since `bfloat16` uses 2 bytes per embedding dimension instead
of 4 bytes for `float`. See Vespa[ tensor values
types](https://docs.vespa.ai/en/reference/tensor.html#tensor-type-spec).

We do not change the type of the query tensor. Vespa will take care
of casting the `bfloat16` field representation to float at search
time, allowing CPU acceleration of floating point operations. The
cast operation does come with a small cost (20-30%) compared with
using float, but the saving in memory and storage resource footprint
is well worth it for most use cases. 

```
field embedding type tensor<bfloat16>(x[384]) {
    indexing: input title . " " . input text | embed | attribute
    attribute {
      distance-metric: prenormalized-angular
    }
}
```
<font size="2"><i>Using bfloat16 instead of float for the embedding tensor.</i></font>
<table>
  <tr>
   <td><strong>Model</strong> </td> <td><strong>NDCG@10 bfloat16</strong>
   </td> <td><strong>NDCG@10 float</strong> </td>
  </tr> <tr>
   <td>bge-small-en </td> <td>0.7346 </td> <td>0.7395 </td>
  </tr> <tr>
   <td>bge-base-en </td> <td>0.7656 </td> <td>0.7662 </td>
  </tr>
</table>
<font size="2"><i>Evaluation results for BGE models - float versus bfloat16 document representation.</i></font>

**By using `bfloat16` instead of `float` to store the vectors, we save
50% of memory cost and we can store 2x more embeddings per instance
type with almost zero impact on retrieval quality:**



## Summary

Using the open-source Vespa container image, we've explored the
recently announced strong BGE text embedding models with embedding
inference and retrieval on our laptops. The local experimentation
eliminates prolonged feedback loops.

Moreover, the same Vespa configuration files suffice for many
deployment scenarios, whether in on-premise setups, on Vespa Cloud,
or locally on a laptop. **The beauty lies in that specific
infrastructure for managing embedding inference and nearest neighbor
search as separate infra systems become obsolete with [Vespa’s
native embedding
support.](https://blog.vespa.ai/enhancing-vespas-embedding-management-capabilities/)**

If you are interested to learn more about Vespa; See [Vespa Cloud - getting started](https://cloud.vespa.ai/en/getting-started),
or self-serve [Vespa - getting started](https://docs.vespa.ai/en/getting-started.html). 
Got questions? Join the Vespa community in [Vespa Slack](http://slack.vespa.ai/).
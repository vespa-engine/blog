--- 
layout: post
title: "Simplify Search with Multilingual Embedding Models" 
author: jobergum 
date: '2023-07-24' 
image: assets/2023-07-25-simplify-search-with-multilingual-embeddings/bruno-martins-4cwf-iW6I1Q-unsplash.jpg
image_credit: 'Photo by <a href="https://unsplash.com/@brunus?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Bruno Martins</a> on <a href="https://unsplash.com/photos/4cwf-iW6I1Q?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>'
skipimage: true 
tags: [embeddings] 
excerpt: This blog post presents and shows how to represent a robust multilingual embedding model of the E5 family in Vespa. 
---

![Decorative image](/{{ page.image }})
<p class="image-credit">{{ page.image_credit }}</p>

This blog post presents and shows how to represent a robust
multilingual embedding model of the E5 family in Vespa. We also
demonstrate how to evaluate the model's effectiveness on multilingual
information retrieval (IR) datasets.


## Introduction

The fundamental concept behind embedding models is transforming
textual data into a continuous vector space, wherein similar items
are brought close together and dissimilar ones are pushed
farther apart. Mapping multilingual texts into a unified vector
embedding space makes it possible to represent and compare queries
and documents from various languages within this shared space.

![multilingual embedding model](/assets/2023-06-13-enhancing-vespas-embedding-management-capabilities/multilingual-embedding-model.png)

## Meet the E5 family.

Researchers from Microsoft introduced the E5 family of text embedding
models in the paper [Text Embeddings by Weakly-Supervised Contrastive
Pre-training](https://arxiv.org/abs/2212.03533). E5 is short for
_EmbEddings from bidirEctional Encoder rEpresentations_. Using a
permissive MIT license, the same researchers have also published
the model weights on the Huggingface model hub. There are three
multilingual E5 embedding model variants with different model sizes
and embedding dimensionality. All three models are initialized from
pre-trained transformer models with trained text vocabularies that
handle up to 100 languages. 

>This model is initialized from
[xlm-roberta-base](https://huggingface.co/xlm-roberta-base) and
continually trained on a mixture of multilingual datasets. It
supports 100 languages from xlm-roberta, but low-resource languages
may see performance degradation._

Similarly, the E5 embedding model family includes three variants
trained only on English datasets.


## Choose your E5 Fighter

The embedding model variants allow developers to trade effectiveness
versus serving related costs. Embedding model size and embedding dimensionality 
impact task accuracy, model inference, nearest
neighbor search, and storage cost.

These serving-related costs are all roughly linear with model size
and embedding dimensionality. In other words, using an embedding
model with 768 dimensions instead of 384 increases embedding storage
by 2x and nearest neighbor search compute with 2x. Accuracy, however,
is not nearly linear, as demonstrated on the [MTEB
leaderboard](https://huggingface.co/spaces/mteb/leaderboard).

The nearest neighbor search for embedding-based retrieval could be
accelerated by introducing approximate algorithms like
[HNSW](https://docs.vespa.ai/en/approximate-nn-hnsw.html). HNSW
significantly reduces distance calculations at query time but also
introduces degraded retrieval accuracy because the search is
approximate. Still, the same linear relationship between embedding
dimensionality and distance compute complexity holds.

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

_Comparision of the E5 **multilingual** models. Accuracy numbers from [MTEB
leaderboard](https://huggingface.co/spaces/mteb/leaderboard)._

Do note that the datasets included in MTEB are biased towards English
datasets, which means that the reported retrieval performance might
not match up with observed accuracy on private datasets, especially
for low-resource languages.


## Representing E5 embedding models in Vespa

Vespa’s vector search and embedding inference support allows
developers to build multilingual semantic search applications without
managing separate systems for embedding inference and vector search
over the multilingual embedding representations.

In the following sections, we use the small E5 multilingual variant,
which gives us reasonable accuracy for a much lower cost than the
larger sister E5 variants. The small model inference complexity
also makes it servable on CPU architecture, allowing iterations and
development locally without [managing GPU-related infrastructure
complexity](https://vickiboykis.com/2023/07/18/what-we-dont-talk-about-when-we-talk-about-building-ai-apps/).


### Exporting E5 to ONNX format for accelerated model inference

To export the embedding model from the Huggingface model hub to
[ONNX](https://onnx.ai) format for inference in Vespa, we can use the 
[Optimum](https://huggingface.co/docs/optimum/index) library:

```
$ optimum-cli export onnx --task sentence-similarity -m intfloat/multilingual-e5-small multilingual-e5-small-onnx
```

The above `optimum-cli` command exports the HF model to ONNX format that can be imported
and used with the [Vespa Huggingface
embedder](https://docs.vespa.ai/en/embedding.html#huggingface-embedder).
Using the Optimum generated ONNX file and tokenizer configuration
file, we configure Vespa with the following in the Vespa [application
package](https://docs.vespa.ai/en/application-packages.html)
[services.xml](https://docs.vespa.ai/en/application-packages.html#services.xml)
file.

```xml
<component id="e5" type="hugging-face-embedder">
  <transformer-model path="model/multilingual-e5-small.onnx"/>
  <tokenizer-model path="model/tokenizer.json"/>
</component>
```

That's it! These two simple steps are all we need to start using the multilingual
E5 model to embed queries and documents with Vespa.

## Using E5 with queries and documents in Vespa

The E5 family uses text instructions mixed with the input data to
separate queries and documents. Instead of having two different
models for queries and documents, the E5 family separates queries
and documents by prepending the input with "_query:_"  or "_passage:_".

```
schema doc {
  document doc  {
    field title type string { .. }
    field text type string { .. }
  }
  field embedding type tensor<float>(x[384]) {
    indexing {
      "passage: " . input title . " " . input text | embed | attribute
    }
  }
```

The above [Vespa schema language](https://docs.vespa.ai/en/schemas.html)
uses the `embed` [indexing
language](https://docs.vespa.ai/en/reference/advanced-indexing-language.html)
functionality to invoke the configured E5 embedding model, using a
concatenation of the "passage: " instruction, the title, and
the text. Notice that the `embedding` [tensor](https://docs.vespa.ai/en/tensor-user-guide.html)
field defines the embedding dimensionality (384). 

The above schema uses a single vector
representation per document. With [Vespa multi-vector
indexing](https://blog.vespa.ai/semantic-search-with-multi-vector-indexing/),
it’s also possible to represent and index multiple vector representations
for the same tensor field.

Similarly, on the [query](https://docs.vespa.ai/en/query-api.html), we can embed the input query text with the
E5 model, now prepending the input user query with “query: “

```json
{
  "yql": "select ..",
  "input.query(q)": "embed(query: the query to encode)", 
}
```

## Evaluation
To demonstrate how to evaluate multilingual embedding models, we
evaluate the small E5 multilingual variant on three information
retrieval (IR) datasets. We use the classic trec-covid dataset, a
part of the [BEIR benchmark](https://github.com/beir-cellar/beir),
that we have written about [in blog
posts](https://blog.vespa.ai/improving-zero-shot-ranking-with-vespa-part-two/)
before. We also include two languages from the
[MIRACL](https://project-miracl.github.io/) (_Multilingual Information
Retrieval Across a Continuum of Languages_) datasets.

All three datasets use
[NDCG@10](https://en.wikipedia.org/wiki/Discounted_cumulative_gain) to
evaluate ranking effectiveness. NDCG is a ranking metric that is
precision-oriented and handles graded relevance judgments.


<table>
  <tr>
   <td><strong>Dataset</strong> </td> <td><strong>Included in E5
   fine-tuning</strong> </td> <td><strong>Language</strong> </td>
   <td><strong>Documents</strong> </td> <td><strong>Queries</strong>
   </td> <td><strong>Relevance Judgments </strong> </td>
  </tr> <tr>
   <td>BEIR:trec-covid </td> <td>No </td> <td>English </td> <td>171,332
   </td> <td>50 </td> <td>66,336 </td>
  </tr> <tr>
   <td>MIRACL:sw </td> <td>Yes (The train split was used) </td>
   <td><a href="https://en.wikipedia.org/wiki/Swahili_language">Swahili
   </a> </td> <td>131,924 </td> <td>482 </td> <td>5092 </td>
  </tr> <tr>
   <td>MIRACL:yo </td> <td>No </td> <td><a
   href="https://en.wikipedia.org/wiki/Yoruba_language">Yoruba</a> </td>
   <td>49,043 </td> <td>119 </td> <td>1188 </td>
  </tr>
</table>
_IR dataset characteristics_


We consider both BEIR:trec-covid and MIRACL:yo as out-of-domain datasets
as E5 has not been trained or fine tuned on them since they don’t
contain any training split. Applying E5 on out-of-domain datasets
is called zero-shot, as no training examples (shots) are available.

The Swahili dataset could be categorized as an in-domain dataset
as E5 has been trained on the train split of the dataset. All three
datasets have documents with titles and text
fields. We use the concatenation strategy described in previous sections, inputting both title
and text to the embedding model.

We evaluate the E5 model using [exact nearest neighbor
search](https://docs.vespa.ai/en/nearest-neighbor-search.html)
without [HNSW indexing](https://docs.vespa.ai/en/approximate-nn-hnsw.html),
and all experiments are run on an M1 Pro (arm64) laptop using the
open-source [Vespa container
image](https://hub.docker.com/r/vespaengine/vespa/). We contrast
the E5 model results with [Vespa BM25](https://docs.vespa.ai/en/reference/bm25.html).


<table>
  <tr>
   <td><strong>Dataset</strong> </td> <td><strong>BM25</strong>
   </td> <td><strong>Multilingual E5 (small)</strong> </td>
  </tr> <tr>
   <td>MIRACL:sw </td> <td>0.4243 </td> <td>0.6755 </td>
  </tr> <tr>
   <td>MIRACL:yo </td> <td>0.6831 </td> <td>0.4187 </td>
  </tr> <tr>
   <td>BEIR:trec-covid </td> <td>0.6823 </td> <td>0.7139 </td>
  </tr>
</table>
_Retrieval effectiveness for BM25 and E5 small (NDCG@10)_


For BEIR:trec-covid, we also evaluated a hybrid combination of E5
and BM25, using a linear combination of the two scores, which lifted
NDCG@10 to 0.7670. This aligns with previous findings, where [hybrid
combinations
outperform](https://blog.vespa.ai/improving-zero-shot-ranking-with-vespa-part-two/)
each model used independently.


## Summary

As demonstrated in the evaluation, multilingual embedding models
*can* enhance and simplify building multilingual search applications
and provide a solid baseline. Still, as we can see from the evaluation
results, the simple and cheap Vespa BM25 ranking model outperformed
the dense embedding model on the MIRACL Yoruba queries. 

This result can largely be explained by the fact that the model had not
been pre-trained on the language (low resource) or tuned for retrieval
with Yoruba queries or documents. This is another reminder of what
we wrote about in a blog post about [improving zero-shot
ranking](https://blog.vespa.ai/improving-zero-shot-ranking-with-vespa/),
where we summarize with a quote from the BEIR paper, which evaluates
multiple models in a zero-shot setting:

>In-domain performance is not a good indicator for out-of-domain
generalization. We observe that BM25 heavily underperforms neural
approaches by 7-18 points on in-domain MS MARCO. However, BEIR
reveals it to be a strong baseline for generalization and generally
outperforming many other, more complex approaches. This stresses
the point that retrieval methods must be evaluated on a broad range
of datasets.

In the next blog post, we will look at ways to make embedding
inference cheaper without sacrificing much retrieval effectiveness
by optimizing the embedding model. Furthermore, we will show how
to save 50% of embedding storage using Vespa’s support for bfloat16
precision instead of float, with close to zero impact on retrieval
effectiveness.

If you want to reproduce the retrieval results, or get started
with multilingual embedding search, check out
the new multilingual search [sample application](https://github.com/vespa-engine/sample-apps/tree/master/multilingual-search). 

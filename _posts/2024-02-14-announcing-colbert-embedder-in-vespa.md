---  
layout: post
title: "Announcing the Vespa ColBERT embedder"
author: jobergum
date: '2024-02-14'
image: assets/2024-02-14-announcing-colbert-embedder-in-vespa/victoire-joncheray-wVQFrEZCThs-unsplash.jpg
skipimage: false
image_credit: 'Photo by <a href="https://unsplash.com/@victoire_jonch?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Victoire Joncheray</a> on <a href="https://unsplash.com/photos/aerial-view-of-snow-covered-mountains-wVQFrEZCThs?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Unsplash</a>'
tags: []
excerpt: "We are excited to announce the general availability of a native Vespa ColBERT embedder implementation in Vespa, 
enabling explainable semantic search using token-level vector representations"

---
We are excited to announce the general availability of a native Vespa [ColBERT
embedder](https://docs.vespa.ai/en/embedding.html#colbert-embedder)
implementation in Vespa, enabling explainable semantic search using
deep-learned token-level vector representations. 

This blog post covers:

* An overview of ColBERT, highlighting its distinctions from
conventional text embedding models.
* The new native Vespa ColBERT embedder implementation,
featuring an innovative asymmetric compression technique enabling
a remarkable 32x compression of ColBERT's token-level vector
embeddings without significant impact on ranking accuracy.  
* A comprehensive FAQ section covering various topics, including strategies for extending
ColBERT's capabilities to handle long contexts.


## What is ColBERT?

The ColBERT retrieval and ranking model was introduced in
[ColBERT: Efficient and Effective Passage Search via Contextualized
Late Interaction over BERT](https://arxiv.org/abs/2004.12832) by
Omar Khattab and Matei Zaharia. It is one of the most cited recent
information retrieval papers with over [800
citations](https://scholar.google.com/scholar?cites=7402681609121002009&as_sdt=2005&sciodt=0,5&hl=en).
Later improvements (distillation, compression) were incorporated
in [ColBERT v2](https://arxiv.org/abs/2112.01488).

We have earlier described and [represented ColBERT in
Vespa](https://blog.vespa.ai/pretrained-transformer-language-models-for-search-part-3/).
However, with the new native ColBERT embedder and enhanced support for
compression, we have improved the developer experience and reduced
the vector storage footprint by up to 32x.


## Why should I care? 

Typical text embedding models use a pooling method, like averaging,
on the output token vectors from the final layer of transformer-based
encoder models. The pooling generates a lone vector that stands for all
the tokens in the input context window of the encoder model.

The similarity is solely based on this lone
vector representation. **In simpler terms, as the text gets longer,
the representation becomes less precise—think of it like trying to
sum up a whole passage with just one word**.

![overview traditional text embedding models](/assets/2024-02-14-announcing-colbert-embedder-in-vespa/image5.png)

_Illustration of regular text embedding models that encode all the
words in the context window of the language model into a single
vector representation. The query document similarity expression is only considering the lone
vector representation from the pooling operation. For a great
practical introduction and behind-the-scenes of text embedding
models, we can recommend [this blog
post](https://osanseviero.github.io/hackerllama/blog/posts/sentence_embeddings/)._

ColBERT represents the query and document by the contextualized
token vectors without the pooling operation of regular embedding
models. This **per-token vector** representation enables a more detailed
similarity comparison between the query and the passage representation, **allowing
each query token to interact with all document tokens**.

Each query token vector representation is contextualized by the
other query token vectors, the same for the passage vector representations.
The contextualization comes from the all-to-all attention mechanism
of the [transformer-based](https://en.wikipedia.org/wiki/Transformer_(deep_learning_architecture)) 
encoder model. The contextualization also includes
the position in the text, so the same word repeating in the text is encoded
differently and not like a bag of unique words (SPLADE). 

Unlike [cross-encoders](https://docs.vespa.ai/en/cross-encoders.html) that concatenate
the two inputs into a single forward pass of the transformer model, with direct attention between them, 
the ColBERT architecture enables separation that enables pre-computation of
the passage representation for the corpus. 

The final missing piece is the ColBERT similarity function used to score passages for a query; meet **MaxSim**:

![overview colbert](/assets/2024-02-14-announcing-colbert-embedder-in-vespa/image1.png)

_Illustration of the ColBERT model representation and the
late-interaction similarity expression (MaxSim). For each query
token representation (Qi), compute the dot product for all passage
token representations (Dj) and keep track of the max score for query
token vector i. The final similarity score is the sum of all max
dot product scores for all query token vectors._

The ColBERT token-level vector representation and the MaxSim function
have many advantages compared to regular text embedding models with
pooling operations for search-oriented tasks.

* Superior [ranking quality in zero-shot
settings](https://arxiv.org/abs/2112.01488), approaching higher
compute FLOPs cross-encoder models that input the query and passage.
* Better training efficiency. Fine-tuning a ColBERT model
for ranking requires fewer labeled examples than regular text embedding
models that must learn a single vector representation. More on that in [Annotating Data for Fine-Tuning a Neural
Ranker?](https://arxiv.org/abs/2309.06131).
* Explainability, unlike typical text embedding models, the MaxSim expression is
[explainable](https://arxiv.org/abs/2203.13088), similar to traditional
text scoring functions like BM25.

Since the rise of semantic search, lack of explainability has been
a pain point for practitioners. **With regular text embedding models,
one can only wave in the direction of the training data to explain
why a given document has a high score for a query**.

ColBERT’s similarity function with the token level interaction
creates transparency in the scoring, as it allows for inspection
of the score contribution of each token. To illustrate the
interpretability capabilities of the similarity function, we built
a simple demo that allows you to input queries and passages and
explain the MaxSim scoring, highlighting terms that contributed
to the overall score.

![colbert snippet](/assets/2024-02-14-announcing-colbert-embedder-in-vespa/image3.png)

_Screenshot of the demo that runs a small quantized ColBERT model
in the browser, allowing you to explore the interpretability feature
of the ColBERT model. The demo highlights the words that contributed
most to the overall MaxSim score. The [demo runs entirely in the
browser](https://colbert.aiserv.cloud/)without any server-side
processing._


## Vespa ColBERT embedder

The new native Vespa `colbert-embedder` is enabled and configured in the
[Vespa application package](https://docs.vespa.ai/en/application-packages.html)’s `services.xml` 
like other native [Vespa embedders](https://docs.vespa.ai/en/embedding.html):

```xml
<container version="1.0">
    <component id="colbert" type="colbert-embedder">
      <transformer-model url="https://huggingface.co/colbert-ir/colbertv2.0/resolve/main/model.onnx"/>
      <tokenizer-model url="https://huggingface.co/colbert-ir/colbertv2.0/raw/main/tokenizer.json"/>
   </component>
</container>
```

With this simple configuration, you can start using the embedder
in queries and during document processing like any other Vespa
native embedder. See the Vespa [colbert sample
application](https://github.com/vespa-engine/sample-apps/tree/master/colbert)
for detailed usage examples.


## Contextual token vector compression using binarization

The per-token vector embeddings take up more storage space than models that pool token vectors into a single vector. 
ColBERT reduces the Transformer model's last layer dimensionality
(e.g., 768 to 128), but it is still larger than single-vector models.

To address the storage overhead, we introduce an asymmetric binarization compression
scheme, significantly reducing storage with minimal ranking accuracy
impact as demonstrated in a later section. Query token vectors
maintain full precision, while document-side token vectors are compressed.
In Vespa, the token embeddings are represented as a [mixed tensor](https://docs.vespa.ai/en/tensor-user-guide.html):
`tensor<tensor-cell-type>(dt{},x[dim])` where dim is the vector dimensionality of the contextualized
token embeddings and [tensor-cell-type](https://docs.vespa.ai/en/reference/tensor.html#tensor-type-spec) the precision (e.g `float` versus `bfloat16`).

The mapped tensor dimension (`dt{}` in this example) allows
for representing variable-length passages without
the storage overhead of using a fixed-length dense (indexed) representation.
The mixed tensor representation allows us also to extend the context
window of ColBERT to arbitrary-length documents by text chunking, where
one can add one more mapped dimension to represent the chunk.

Using `int8` as the target [tensor cell precision
type](https://docs.vespa.ai/en/reference/tensor.html#tensor-type-spec),
will cause Vespa embedder implementation to binarize the token
vectors and pack the compressed vector into dim/8 dimensions. If
the original token embedding dimensionality is 128 floats, we can
use 16 bytes (`int8`) to represent the compressed token embedding.

This compression technique reduces the storage footprint of the
token vectors by 32x. **Compared to a regular text embedding
representation such as text-embedding-ada-002, which utilizes 1536
float dimensions (6144 bytes), the space footprint of ColBERT is
lower for up to 384 tokens**.

![colbert token](/assets/2024-02-14-announcing-colbert-embedder-in-vespa/image2.png)

_The binarization and compacting performed by the colbert embedder
for `int8` target tensors is shown in the illustration above. This
asymmetric compression scheme is inspired by previous work with
[billion-scale vector datasets](https://blog.vespa.ai/billion-scale-knn/)._

**colbert embedder schema usage with float representation:**
```
schema doc {
  document doc {
    field text type string {}
  }
  field colbert type tensor<float>(dt{}, x[128]) {
    indexing: input text | embed colbert | attribute  
  } 
}
```

**colbert embedder schema usage with `int8` representation**. 
```
schema doc {
  document doc {
    field text type string {}
  }
  field colbert type tensor<int8>(dt{}, x[16]) {
    indexing: input text | embed colbert | attribute  
  } 
}
```
This configuration triggers compression.

**colbert embedder schema usage with `int8` representation and paragraph inputs**. 
```
schema doc {
  document doc {
    field chunks type array<string> {}
  }
  field colbert type tensor<int8>(paragraph{}, dt{}, x[16]) {
    indexing: input chunks | embed colbert paragraph | attribute  
  } 
}
```

The compressed version can be unpacked in ranking expressions using the
[unpack_bits](https://docs.vespa.ai/en/reference/ranking-expressions.html#unpack-bits) function
to restore (lossy) the 128-dimensional `float` representation. 
This representation is what is used in the MaxSim tensor compute expression against the full precision query tensor representation.

Refer to usage examples in the [documentation](https://docs.vespa.ai/en/embedding.html#colbert-embedder)
and the [sample application](https://github.com/vespa-engine/sample-apps/tree/master/colbert)
for more details.

For applications with lower query throughput or smaller ranking
windows - the mixed colbert tensor representation can also be offloaded to disk
storage using the [Vespa paged attribute](https://docs.vespa.ai/en/attributes.html#paged-attributes) option.


## Ranking quality versus compression
We evaluate the impact of compression on three search-oriented datasets
that are part of the [BEIR benchmark](https://github.com/beir-cellar/beir).

We use CoLBERT as a `second-phase` ranking model in a [phased ranking](https://docs.vespa.ai/en/phased-ranking.html) funnel, 
where we re-rank results from a regular text embedding model ([e5-small-v2](https://huggingface.co/intfloat/e5-small-v2)). 
For both experiments we use the [colbert sample application](https://github.com/vespa-engine/sample-apps/tree/master/colbert)
as the starting app. 

We use a re-rank count of 50 using a second-phase expression, re-ranking the top hits from the E5 retriever. For
datasets with both title and text, we concatenate them to form the input to the embedder. Note 
that we use the pre-computed document vector representations during the re-ranking stage, encoding
the documents at query time would make it unusable for production use cases. Also, **the re-ranking step is performed
on the Vespa content nodes, avoiding shifting vector data around**.

This type of retrieval and ranking pipeline is quite common. While
the single-vector representation model with pooling excels in recall
(retrieving all relevant information), it falls short in precision
(capturing what is relevant) compared to more expressive MaxSim similarity.

The following reports `nDCG@10` for both
E5 as a single stage retriever, and with ColBERT as a second-phase
ranking expression, with and without compression.

<style>
  table, th, td {
    border: 2px solid black;
  }
  th, td {
    padding: 8px;
  }
</style>

<table>
  <tr>
   <td>Dataset </td> <td>E5 </td> <td>E5->ColBERT </td> <td>E5->ColBERT
   compressed </td>
  </tr> <tr>
   <td>beir/trec-covid </td> <td>0.7449 </td> <td>0.7939 </td>
   <td><strong>0.8003</strong> </td>
  </tr> <tr>
   <td>beir/nfcorpus </td> <td>0.3246 </td> <td><strong>0.3434</strong>
   </td> <td>0.3323 </td>
  </tr> <tr>
   <td>beir/fiqa </td> <td>0.3747 </td> <td><strong>0.3919</strong>
   </td> <td>0.3885 </td>
  </tr>
</table>

<br/>

As can be observed above, there is not a significant difference between
the compressed and non-compressed representations regarding
effectiveness. However, **the compressed version reduces the storage
footprint by 32x!**

We also note that the E5 models have been trained on millions of text pairs, while 
the ColBERT checkpoint used here has been trained on less than 100K examples. 

### Why does it work?

The query token vector representations remain unchanged, preserving
their original semantic information. The
compression method simplifies the document token vectors by
representing positive dimensions as one and negative dimensions as zero. 
This binary representation effectively indicates the presence
or absence of important semantic features within the document token
vectors. 

Positive dimensions contribute to increasing the dot
product, indicating relevant semantic similarities, while negative
dimensions are ignored.

## Serving Performance

We do not touch on the model inference part of ColBERT as it scales the
same way as a regular text embedding model; see [this blog
post](https://blog.vespa.ai/accelerating-transformer-based-embedding-retrieval-with-vespa/)
on scaling the inference part. As we expose ColBERT MaxSim as a
ranking expression, the ranking serving performance depends on the
following factors:

* The number of hits exposed to the MaxSim tensor similarity expression
* The token-level vector dimensionality 
* The number of token vectors per document and query

We can _estimate_ the [FLOPS](https://en.wikipedia.org/wiki/FLOPS)
for the MaxSim expression using the following formula:

```
FLOPs=2×M×N×K
```

where `M` is the number of query vectors, `N` is the number of document
vectors, and `K` is the ColBERT dimensionality. For example, for `beir/nfcorpus`, we have on average, 356 document and 32 query tokens. 

This calculation yields 229,376 FLOPs for a single matrix multiplication. 
When re-ranking 1000 documents, this equates to 230
megaFLOPS (230 × 10^6). Empirically, this results in an operational
time of around 230 milliseconds when utilizing a single CPU thread.

If we decrease the re-ranking window to 100 documents, the operation
time reduces to 23 milliseconds. Similarly, if we had fewer document
token vectors (shorter documents), we would get a linear reduction in
latency; for example, reducing to 118 tokens would cut latency down
to 8ms.

Depending on the specific application, employing Vespa's support for using [multiple threads
per search](https://search.vespa.ai/search?query=how%20to%20use%20multiple%20threads%20per%20search%3F)
can further reduce latency, leveraging the capabilities of multi-core
CPU architectures more effectively. While increasing the number of
threads per search does not alter the FLOP compute requirements, it
reduces latency by parallelizing the workload.


## Summary
We are enthusiastic about ColBERT, believing that genuine explainability
in semantic search relies on contextual token-level embeddings, allowing
each query token to interact with all document tokens.

This (late) interaction also unlocks explainability. Explaining why a passage scores as it does for a query has been a
significant challenge in neural search with traditional text embedding models. 

Another important observation is that the ColBERT architecture requires much fewer labeled examples for 
fine-tuning. Learning token-level vectors is more manageable than learning a single lone
vector representation. With larger, generative models, we can efficiently generate 
[in-domain labeled data](https://blog.vespa.ai/improving-text-ranking-with-few-shot-prompting/) 
to fine-tune ColBERT to our task and domain. As the ColBERT is based on 
a straightforward encoder model, you can fine-tune ColBERT on a single commodity GPU.  

As ColBERT is a new concept for many practitioners, we have included
a comprehensive FAQ section that address common questions we have
received about ColBERT over the past few years.

## ColBERT in Vespa FAQ

**I have many structured text fields like product title and brand
description, can I use ColBERT in Vespa?**

Yes, you can either embed the concatenation of the fields, or have
several colbert tensors, one per structured field. The latter allows
you to control weighting in your Vespa ranking expressions with
multiple Max Sim calculations (per field) for the same query input tensor.

**Can I combine ColBERT with query filters in Vespa?**

Yes, ColBERT is exposed as a ranking model in Vespa and can be used
to rank documents matching the
[query](https://docs.vespa.ai/en/reference/query-api-reference.html)
formulation, including filters, and also result
[grouping](https://docs.vespa.ai/en/grouping.html).

**Our ranking uses many signals other than textual semantic
similarity, can I use ColBERT?**

Yes, Vespa’s ranking framework allows many different signals of
[rank features](https://docs.vespa.ai/en/reference/rank-features.html)
as we call them in Vespa. Features can be combined in ranking
expressions in ranking phases.

The MaxSim expression can be used as any other feature, and in combination 
with other custom features, even as a feature in a GBDT-based ranker using Vespa’s [xgboost](https://docs.vespa.ai/en/xgboost.html)
or [lightgbm](https://docs.vespa.ai/en/lightgbm.html) support.

**How does ColBERT relate to Vespa’s support for nearestNeighbor search?**

It does not directly relate to Vespa’s
[nearestNeighbor](https://docs.vespa.ai/en/nearest-neighbor-search.html)
support. The nearestNeighbor search operator could be used to
retrieve hits in the first stage of a ranking pipeline and where
ColBERT is used in a
[second-phase](https://docs.vespa.ai/en/phased-ranking.html)
expression. Vespa’s native embedders map text to a tensor representation,
which can be used in ranking; independent of the query retrieval
formulation.

**How does ColBERT relate to Vespa HNSW indexing for mixed tensors?**

It does not. Since the MaxSim expression is only used during ranking
phases, enabling [HNSW indexing
](https://docs.vespa.ai/en/approximate-nn-hnsw.html)on the mixed
tensor representing the colbert token embeddings will be a fruitless
waste of resources. Make sure that you do not specify an `index` on
the mixed tensor field used to represent the document token embeddings.

**Are there any multilingual ColBERT checkpoints?**

The [official checkpoint
](https://huggingface.co/colbert-ir/colbertv2.0)has only been trained
on a single dataset of English texts and uses English vocabulary.
Recently, we have seen more interest in multilingual checkpoints
(See
[M3](https://github.com/vespa-engine/pyvespa/blob/master/docs/sphinx/source/examples/mother-of-all-embedding-models-cloud.ipynb)).

**Do I need to use the new colbert-embedder if I want to use ColBERT for ranking in Vespa?**

No, we added [colbert-embedder
](https://docs.vespa.ai/en/embedding.html#colbert-embedder)as a
convenience feature. Embedding (pun intended) the embedder into
Vespa allows for inference acceleration (GPU) and shifting considerably
fewer bytes over the network than doing the inference outside of
Vespa.

You can still produce ColBERT-like token level embeddings outside
of Vespa and pass the document tensor at indexing time, and the
query tensor using the Vespa query API. 
See [this notebook](https://github.com/vespa-engine/pyvespa/blob/master/docs/sphinx/source/examples/mother-of-all-embedding-models-cloud.ipynb)
for using M3 with Vespa for inspiration.

**Can ColBERT handle long contexts?**

It is possible to perform chunking like with traditional context
length limited single-vector embedding models. Since **Vespa 8.303.17**,
the colbert-embedder also supports array inputs, so one can
store one ColBERT representation per paragraph-sized text chunk.

Using an array of strings as input to the embedder requires a 3d
mixed tensor with two mapped dimensions. In the example below,
the mapped `paragraph` dimension represents the chunk id (array index).

```
schema doc {
  document doc {
    field chunks type array<string> {}
  }
  field colbert type tensor<int8>(paragraph{}, dt{}, x[16]) {
    indexing: input chunks | embed colbert paragraph | attribute  
  } 
}
```

We can then, wrap the MaxSim tensor expression used for a single input with another tensor
reduce operation, for example to find the best matching paragraph,
we can reduce the `paragraph` dimension using `max` aggregation. 
See this
[Vespa tensor playground
example](https://docs.vespa.ai/playground/#N4KABGBEBmkFxgNrgmUrWQPYAd5QGNIAaFDSPBdDTAF30gGJGwA1AUwGccBDMAYSwAbAEIBRAEoAVMAFkeADwDKASwC2YKewB2nLACcwYhTn1dOKrNrAAFITwCeAc31YArtoAmAHW2+pABYqnGA49s6uHp5g7Ao8amHsYE5uKp5cYFHs+py0PF4q2k5gWNBgtAFJHNx8tDp6hrGm5pa65QE8tGDqiWo6XRVJ8srqYBZqKvb6KrQOmZzs0YUCwuLSAHRgAOpJ6WpWufqdSYPd2nX6fZ4qx2N1OJy+hQBuws+LZ+1JBDxCBG72WitTibXy+JTsJK-PRfJAEYQAI2ytAAtOw1EjPOl9ABdAAUAVotAecAA9KTPFgCCD3jV1jwVKSdEyMYtrkV1oS1EJGPChEj9Kj0ZjsQBKMD5aKIPkCrqceKJCU4MIqH5Aqz4wnEzhk0lOGYBNwI9bwtSk2m8NFFQrsUnyhJCdgonjKzik2hmW1qHi5bKkmXI0WgvzaACE0sRyLA3oU401RJJ5KOAHd1vqKka3At9PDzv0TVgzbl8tADJ4UdA3LQ3GZPJ0eKTBKJJFJSd7ChSqW71DwnFx-ZHBaVoKqbkJ1jgiqKwdodmAOu9ysmsNGVAoPnVdAYQhVOmAzM0FudYU21jJ3gRaAZ9+xD-1OsCSmUAI5ubJzC9XnJgPEAKl-r7vniz60KK-7ipKYCUv8fTHp+24-v+nQeioCJVuweIBoKYG-tOIaBOwcwIlgFTzjwi6nPaSSFOk67RHi6S6Ow4rXLBFhWGA2jxEk-4KP+xASl4YDJkkWYnMuUHqPUj6loYCJmM8MwOMGvgomAAAGm4NMBtDAAAvgJCiIAATDiorqbCWFdIB+hzFp16zDg7CqRp9n6AxukGWARmmeZlmDl00FuLBAz1A5DhOWAM7GGE+QPhxsmwlxVzlGFhisdJBxRdoakAbQv4Sgi8nsIp8XWIlNl2dkGgub+nj5YVxWleq5UOZUUFUsF-SpZc2W5XxsI0bEHwMfUzGSWxrTCQaS4rhlujAjOABi175GcHpYJ4biXlNV5sFwvCpVuOQzi5iBaMd62uFtO0cSkaTsPG2q6tBNIHTw9KMsybkomJ+govd6ScrQ3J4Wp51paE0wTECi6Vtot26E9iadtS6wWh9DJMtopJmNA2Q6AQtpHNoADWhROGiJhmJw7G6MD3KMKY6gzCo7wVh4iOcGDSAXQ0nFWCizMw2zSTw1zyM6uSr3o+9n3Y7j7D42YCPE-k5NFFTh50yCXI8togvC6z7Piy13NnSIQhYE4CCCAkVYU9NpFuSEyzVLwku6giVtOLLdJY6aOAO5ryYGiiLuknh-jtaWQhW6HRRQUrNo7u1VlgJVgnREFIVHQ0IKQGQqB6UXBlF9Q5C4Aw7AkEXEAUPgFc0JA2gMJVOmirXNCYDXCCQG5AA80BW50AB8On6YZJlmXAwBgAADAgiDz8QACMOICavcCIKvxCmQJADM28ACzEAArDiemF93JcYGXGBN-XVd9zXpDdw3VB15grd98h0xoXUTCAVO5v27lAXuUBB7DywGPDyk9vLT1FLPReiAD7EGPhvMAW9EBn2IAANkwcZbeAB2YgAAOS+18aC32LqAiAj8oDP0IF3ZulA0Bf3rvQPuzAWA2GyLJCYidKTEmuttWgIQsDvEMJRDotYJqZWsAoZaKgchdBEknfYugPS3CaDTCwidTjCKhptMRIQkS0BEjoCUcdYSZwuBoeC35IK-CELCHO3V7FgEcSCbK0ckhG1hkkA8NN7wtSfLCWO8dHa6JaBxYIGl1LqVrNtDC7cQLigKn-VC6EgH8kDAJTgwVDLmUSTOQI8SYm0ymjTAE4jPh8G0OwZMedrylFhI5JImk0pwIMiBfSflQ7O3akY0wJjLxjHhDTMA5jLHWBcbYt8tkvHsEvAhZxNj3FwRWV+AuX8aEQHvqgBh2A2GQFfl-D+7CwFQB-lAYRoybriJYe-CBkBClqDxBnRZDgO5gEyUSf+OSrKimKVQu+pc6FXObkwyARBIX1zYQwzhDAeFgCWjRR2pwYwTIMGLVaNi7HVRCB3GcWwZrzMMSRB5piwA-D+ACY4ngBLqOTPkAYK4RxCSxYoHF0whGdVzo4gpK51HJKJiUKRsJ-z1X-PIhaVhfBZkdupGMFkfSwl7C4dgThOjXlNq0dYYLi4QvLhcmF5z36Io4TchgYr2AAH0YzPObq8u1DEqWiMvJwASMYBL1U7nsk1D8zWnLhRcq11z+4ouYGAJQwVwnYs4JMjIiV5mEsuI8bQBEwCct+HcW8mw5wLjxVEWEibJmO02aFXqSbcWhGyF898PU1CbGzbm1xvocDdB3Cud5XwFjlBXFgBEeRlinFPC2OQihVAaFrWYQ1ga76QuOea51CLG7Wpbgwd59rSj2pAmunu27gp4jtY6xQAab5BqOSGhgYbLUbsjVwqAMabA8COC4F0AQwCOneK44YM7fATukN26ZPoPgcT4ITTaDapAk04AIht+x0iuMGd+vgQgWZ1GiLmOoCg5TsEAqrH9OgnCkTxGfVexkQVjBXHtYJXBupWyKA23DsRxECSsEkRpiwe31v0AI2lhoyYU3WGUlcDGjxdF4B+o4OAAjeuEtRc4nqoScSadGF0Tls5SXldYX8OACocUpTBbqknQmtDgDORJXTjp4hwPA+q8CfJmRs6SmaFiVzemVBuNKin1E-GsAbLozG+yGDErCTgAQDChUugIvcYkljWFODwYii5YgKkdD4ttwgokGMhukTlrMOIdFTkkKiXjfhvhCIlGTvY5PfvnhKMrMQ4gOihGl9gAlBjWHUTwLEgkSKVEMHVz98mF1XqXaa9+q74VQAjWArdv8AXZMAVZe1o2Gvc0PfXV5UCR60HHg5ryTmvIuaQWgXwwAcBwBXlBWgt3DK3b0nANBV2bt3fqo97ycBV4vdPu977X3d4-fni93BgPPsPZBwoX7L28HEEh36h7xkntg7gKQpH924Co5+39uAZDEchmu795H33Yfo5XoDkHX27uw-x7vanZOYfPbgAATiJyTmn0OnsM8Z9oLnZPccU5e6jpn2Phdw4J74K+i7aHTehaGw9lykWQOjSweQ2g5gjM9XUspMdctYATsUJyAmDBqBazrsZXQ6X-EBFNRKMj30fHmnTP5v4+K-hUlmoIIQalCDqcsPgB8USu9aHm7z2mWmGDaacDprlunHeR8AGjfS9IDPJTYyl0nde8pTfi1xm2v2KbTd85tIR1muKreXib1Dr30NvS-ZXC3363MgPsMw9r7m684Dt8Bx6PmNtsr8-5KEAEYXW0X+T3NiAKEvXXqbwaZtK7myrzdz6mAxokIsFJJRTdlX11Y0VO-xUIjsu1ctBhK0Co8dVfjQ+qq9Ugqb0I776tfqNQc+vULK6nItawx9RbNvM9eqPvM5W1E-DCDvB1bva3RTX1e7efcFRfG9ZfO9ZvQA9+DfVFONDQPaTlaICldqADUYOdDIF-KfAIaOeJW3BlOoFrPtWPdqdNC3VtX3UDHrWEEg2dZNHNa8EqJtSg2vZA+XJfRXauDAz+SNYAyA-degObXbCAm6DCEA2gApIpDOUCT-MAfZHQ5dRvZhVfFvZuDfAiXrb4NaczY8EzLqY8X9dgDtXg9VblBQdQeNJg-xN-Mbb9Mg3ZSbUQ1A8QpvIwzA5uNvGMGwMA11SA09WQkCH1RQASHAJA41EQnEEAPSIAA) 
that demonstrates both MaxSim for a single input text and 
multiple chunked inputs. Note that having another mapped level increases the number of dot products. 

**Can I combine ColBERT with reranking with cross-encoder models in Vespa?**

Yes, an example phased ranking pipeline could use hybrid retrieval,
re-rank with ColBERT, and perform a final global phase re-ranking
with a [cross-encoder](https://docs.vespa.ai/en/cross-encoders.html#).

Using ColBERT as an intermediate step can help reduce the ranking
depth of the cross-encoder. The Vespa [msmarco ranking sample
application](https://github.com/vespa-engine/sample-apps/tree/master/msmarco-ranking)
demonstrates such an effective ranking pipeline, including the
colbert-embedder.

**How does ColBERT compare to hybrid search?**

ColBERT can be used in a [hybrid search
pipeline](https://blog.vespa.ai/redefining-hybrid-search-possibilities-with-vespa/)
as just another neural scoring feature, used in any of the Vespa
ranking phases (preferably in `second-phase` for optimal performance
to avoid moving vector data up the stateless container for
`global-phase` evaluation).

Vespa allows combining the MaxSim score with other scores using, for
example, [reciprocal rank
fusion](https://docs.vespa.ai/en/phased-ranking.html#cross-hit-normalization-including-reciprocal-rank-fusion)
or other normalization rank features. The [sample
application](https://github.com/vespa-engine/sample-apps/tree/master/colbert)
features examples of using ColBERT MaxSim in a hybrid ranking
pipeline.

**Can I run ColBERT if I’m GPU-poor?**

Yes, you can. The model inference (mapping the text to vectors) is
compute intensive (comparable with regular text embedding models)
and benefits from GPU inference. It’s possible to use a quantized
model for CPU inference and this works well with low latency for
shorter input sequences, e.g queries. You might want to consider
[this checkpoint](https://huggingface.co/vespa-engine/col-minilm)
for CPU-inference as it is based on a small Transformer mode.  It
also uses 32-dimensional vectors, with the mentioned compression
schema reduces the footprint of the token vectors down to 4 bytes
per token vector.

**Why is ColBERT interpretable while regular text embeddings are not?**

By inspecting the query &lt;-&gt; document token-level similarities,
we can deduce which tokens in the document contributed the most
to the score.

**What are the tradeoffs? If it stores a vector per token, it must be expensive!**

We can look at performance and deployment cost along three axes:
Effectiveness (ranking quality), storage, and computations. In this
context, we can recommend [Moving Beyond Downstream Task Accuracy
for Information Retrieval
Benchmarking](https://aclanthology.org/2023.findings-acl.738.pdf),
which provides a framework to compare different methods.

As the ColBERT document representation in Vespa can be offloaded
to disk, it becomes drastically cheaper than data structures used for retrieval (shortlisting). 

**Why didn’t you expose the ColBERT 2 [PLAID](https://arxiv.org/abs/2205.09707) retrieval optimization
in Vespa?**

Primarily because Vespa is designed for low-latency real-time indexing, and the
[PLAID optimization](https://arxiv.org/abs/2205.09707) requires batch processing the document token vectors to find
centroids. This centroid selection would not work well in a real-time setting where
our users expect outstanding performance from document number one to billions of
documents. With Vespa, users can use different retrieval mechanisms
and still enjoy the power of ColBERT in ranking phases.

**What other vector databases support ColBERT out-of-the box?**

No other vector database or search engine supports ColBERT
out-of-the-box as far as we know.


**That is a lot of dot products - do you use any acceleration to speed it up?**

Yes, MaxSim is a more expressive interaction between the query and the document than regular text embedding models,  but still
two orders fewer FLOPs than cross-encoders.

Vespa's core backend is written in C++, and the dot products are accelerated
using `SIMD` instructions. 

**Why is ColBERT not listed on the MTEB?**

The [MTEB](https://huggingface.co/blog/mteb) benchmark only
lists single vector embedding models and the benchmark covers many
different tasks other than retrieval/re-ranking. Similarly,
cross-encoders or other Information Retrieval (IR) oriented models
are also not listed on MTEB.

**How does ColBERT compare with listwise prompt rank models like RankGPT?**

The core difference is the FLOPs versus the effectiveness, both can
be used in a ranking pipeline and where ColBERT can reduce the
number of documents that are re-ranked using the more powerful (but
also several orders higher FLOPs) listwise [prompt
ranker](https://arxiv.org/abs/2309.15088).

**How can I produce a ColBERT-powered contextualized snippet like in the demo?**

We are working on integrating this feature in Vespa, the essence
is to use the MaxSim interaction to find which of the terms in the
document contributed most to the overall score. This, can in practise
be done by returning the similarity calculations as a tensor using
[match-features](https://docs.vespa.ai/en/reference/schema-reference.html#match-features),
then a [custom searcher](https://docs.vespa.ai/en/searcher-development.html) can
use this information to highlight the source text. This [Vespa
tensor
playground](https://docs.vespa.ai/playground/#N4KABGBEBmkFxgNrgmUrWQPYAd5QGNIAaFDSPBdDTAF30gGJGwA1AUwGccBDMAYSwAbAEIBRAEoAVMAFkeADwDKASwC2YKewB2nLACcwYhTn1dOKrNrAAFITwCeAc31YArtoAmAHW2+pABYqnGA49s6uHp5g7Ao8amHsYE5uKp5cYFHs+py0PF4q2k5gWNBgtAFJHNx8tDp6hrGm5pa65QE8tGDqiWo6XRVJ8srqYBZqKvb6KrQOmZzs0YUCwuLSAHRgAOpJ6WpWufqdSYPd2nX6fZ4qx2N1OJy+hQBuws+LZ+1JBDxCBG72WitTibXy+JTsJK-PRfJAEYQAI2ytAAtOw1EjPOl9ABdAAUAVotAecAA9KTPFgCCD3jV1jwVKSdEyMYtrkV1oS1EJGPChEj9Kj0ZjsQBKMD5aKIPkCrqceKJCU4MIqH5Aqz4wnEzhk0lOGYBNwI9bwtSk2m8NFFQrsUnyhJCdgonjKzik2hmW1qHi5bKkmXI0WgvzaACE0sRyLA3oU401RJJ5KOAHd1vqKka3At9PDzv0TVgzbl8tADJ4UdA3LQ3GZPJ0eKTBKJJFJSd7ChSqW71DwnFx-ZHBaVoKqbkJ1jgiqKwdodmAOu9ysmsNGVAoPnVdAYQhVOmAzM0FudYU21jJ3gRaAZ9+xD-1OsCSmUAI5ubJzC9XnJgPEAKl-r7vniz60KK-7ipKYCUv8fTHp+24-v+nQeioCJVuweIBoKYG-tOIaBOwcwIlgFTzjwi6nPaSSFOk67RHi6S6Ow4rXLBFhWGA2jxEk-4KP+xASl4YDJkkWYnMuUHqPUj6loYCJmM8MwOMGvgomAAAGm4NMBtDAAAvgJCiIAATDiorqbCWFdIB+hzFp16zDg7CqRp9n6AxukGWARmmeZlmDl00FuLBAz1A5DhOWAM7GGE+QPhxsmwlxVzlGFhisdJBxRdoakAbQv4Sgi8nsIp8XWIlNl2dkGgub+nj5YVxWleq5UOZUUFUsF-SpZc2W5XxsI0bEHwMfUzGSWxrTCQaS4rhlujAjOABi175GcHpYJ4biXlNV5sFwvCpVuOQzi5iBaMd62uFtO0cSkaTsPG2q6tBNIHTw9KMsybkomJ+govd6ScrQ3J4Wp51paE0wTECi6Vtot26E9iadtS6wWh9DJMtopJmNA2Q6AQtpHNoADWhROGiJhmJw7G6MD3KMKY6gzCo7wVh4iOcGDSAXQ0nFWCizMw2zSTw1zyM6uSr3o+9n3Y7j7D42YCPE-k5NFFTh50yCXI8togvC6z7Piy13NnSIQhYE4CCCAkVYU9NpFuSEyzVLwku6giVtOLLdJY6aOAO5ryYGiiLuknh-jtaWQhW6HRRQUrNo7u1VlgJVgnREFIVHQ0IKQGQqB6UXBlF9Q5C4Aw7AkEXEAUPgFc0JA2gMJVOmirXNCYDXCCQG5AA80BW50AB8On6YZJlmXAwBgAADAgiDz8QACMOICavcCIKvxCmQJADM28ACzEAArDiemF93JcYGXGBN-XVd9zXpDdw3VB15grd98h0xoXUTCAVO5v27lAXuUBB7DywGPDyk9vLT1FLPReiAD7EGPhvMAW9EBn2IAANkwcZbeAB2YgAAOS+18aC32LqAiAj8oDP0IF3ZulA0Bf3rvQPuzAWA2GyLJCYidKTEmuttWgIQsDvEMJRDotYJqZWsAoZaKgchdBEknfYugPS3CaDTCwidTjCKhptMRIQkS0BEjoCUcdYSZwuBoeC35IK-CELCHO3V7FgEcSCbK0ckhG1hkkA8NN7wtSfLCWO8dHa6JaBxYIGl1LqVrNtDC7cQLigKn-VC6EgH8kDAJTgwVDLmUSTOQI8SYm0ymjTAE4jPh8G0OwZMedrylFhI5JImk0pwIMiBfSflQ7O3akY0wJjLxjHhDTMA5jLHWBcbYt8tkvHsEvAhZxNj3FwRWV+AuX8aEQHvqgBh2A2GQFfl-D+7CwFQB-lAYRoybriJYe-CBkBClqDxBnRZDgO5gEyUSf+OSrKimKVQu+pc6FXObkwyARBIX1zYQwzhDAeFgCWjRR2pwYwTIMGLVaNi7HVRCB3GcWwZrzMMSRB5piwA-D+ACY4ngBLqOTPkAYK4RxCSxYoHF0whGdVzo4gpK51HJKJiUKRsJ-z1X-PIhaVhfBZkdupGMFkfSwl7C4dgThOjXlNq0dYYLi4QvLhcmF5z36Io4TchgYr2AAH0YzPObq8u1DEqWiMvJwASMYBL1U7nsk1D8zWnLhRcq11z+4ouYGAJQwVwnYs4JMjIiV5mEsuI8bQBEwCct+HcW8mw5wLjxVEWEibJmO02aFXqSbcWhGyF898PU1CbGzbm1xvocDdB3Cud5XwFjlBXFgBEeRlinFPC2OQihVAaFrWYQ1ga76QuOea51CLG7Wpbgwd59rSj2pAmunu27gp4jtY6xQAab5BqOSGhgYbLUbsjVwqAMabA8COC4F0AQwCOneK44YM7fATukN26ZPoPgcT4ITTaDapAk04AIht+x0iuMGd+vgQgWZ1GiLmOoCg5TsEAqrH9OgnCkTxGfVexkQVjBXHtYJXBupWyKA23DsRxECSsEkRpiwe31v0AI2lhoyYU3WGUlcDGjxdF4B+o4OAAjeuEtRc4nqoScSadGF0Tls5SXldYX8OACocUpTBbqknQmtDgDORJXTjp4hwPA+q8CfJmRs6SmaFiVzemVBuNKin1E-GsAbLozG+yGDErCTgAQDChUugIvcYkljWFODwYii5YgKkdD4ttwgokGMhukTlrMOIdFTkkKiXjfhvhCIlGTvY5PfvnhKMrMQ4gOihGl9gAlBjWHUTwLEgkSKVEMHVz98mF1XqXaa9+q74VQAjWArdv8AXZMAVZe1o2Gvc0PfXV5UCR60HHg5ryTmvIuaQWgXwwAcBwBXlBWgt3DK3b0nANBV2bt3fqo97ycBV4vdPu977X3d4-fni93BgPPsPZBwoX7L28HEEh36h7xkntg7gKQpH924Co5+39uAZDEchmu795H33Yfo5XoDkHX27uw-x7vanZOYfPbgAATiJyTmn0OnsM8Z9oLnZPccU5e6jpn2Phdw4J74K+i7aHTehaGw9lykWQOjSweQ2g5gjM9XUspMdctYATsUJyAmDBqBazrsZXQ6X-EBFNRKMj30fHmnTP5v4+K-hUlmoIIQalCDqcsPgB8USu9aHm7z2mWmGDaacDprlunHeR8AGjfS9IDPJTYyl0nde8pTfi1xm2v2KbTd85tIR1muKreXib1Dr30NvS-ZXC3363MgPsMw9r7m684Dt8Bx6PmNtsr8-5KEAEYXW0X+T3NiAKEvXXqbwaZtK7myrzdz6mAxokIsFJJRTdlX11Y0VO-xUIjsu1ctBhK0Co8dVfjQ+qq9Ugqb0I776tfqNQc+vULK6nItawx9RbNvM9eqPvM5W1E-DCDvB1bva3RTX1e7efcFRfG9ZfO9ZvQA9+DfVFONDQPaTlaICldqADUYOdDIF-KfAIaOeJW3BlOoFrPtWPdqdNC3VtX3UDHrWEEg2dZNHNa8EqJtSg2vZA+XJfRXauDAz+SNYAyA-degObXbCAm6DCEA2gApIpDOUCT-MAfZHQ5dRvZhVfFvZuDfAiXrb4NaczY8EzLqY8X9dgDtXg9VblBQdQeNJg-xN-Mbb9Mg3ZSbUQ1A8QpvIwzA5uNvGMGwMA11SA09WQkCH1RQASHAJA41EQnEEAPSIAA)
example might be helpful.

**Can I fine-tune my own ColBERT model, maybe in a different language than English?**

Yes you can,
[https://github.com/bclavie/RAGatouille](https://github.com/bclavie/RAGatouille) is a great way to get started with training ColBERT models and the base-model can also be a multilingual model. We can also recommend
[UDAPDR: Unsupervised Domain Adaptation via LLM Prompting and
Distillation of Rerankers](https://arxiv.org/abs/2303.00807) that
fine-tunes a ColBERT model using synthetic data. See also related
[work for in-domain
adaption](https://blog.vespa.ai/improving-text-ranking-with-few-shot-prompting/)
of ranking models.

**What do you mean by zero-shot in the context of retrieval and ranking?**

See [Improving Zero-Shot Ranking with Vespa Hybrid
Search](https://blog.vespa.ai/improving-zero-shot-ranking-with-vespa/) for
more context on the difference between applying a ranking model
in-domain and out-of-domain (zero-shot) setting.

**How could you empirically observe the ranking contribution to latency?**

Vespa allows per query [tracing and profiling
](https://docs.vespa.ai/en/reference/query-api-reference.html#tracing)of
queries which is extremely useful for understanding which parts of
a retrieval and ranking pipeline consumes time and resources. With
this feature, we could experiment with a varying number of hits
exposed to ranking with a [query time parameter
](https://docs.vespa.ai/en/reference/query-api-reference.html#ranking.rerankcount)overriding
the schema configuration. 

**Do any of the embedding model providers support ColBERT-like models?**

We see increased interest in training ColBERT type of models. For example, [Jina.ai](https://huggingface.co/jinaai/jina-colbert-v1-en) just
announced a ColBERT checkpoint with extended context length. 

We believe that a promising future direction for embedding models is to provide multiple optional representations, see [M3](https://arxiv.org/abs/2402.03216).

**I have more questions; I want to learn more!**

For those interested in learning more about Vespa or ColBERT, 
join the [Vespa community on Slack](https://vespatalk.slack.com/) or [Discord](http://discord.vespa.ai/) to exchange ideas,
seek assistance from the community, or stay in the loop on the latest Vespa developments.
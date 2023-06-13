---
layout: post
title: Enhancing Vespa’s Embedding Management Capabilities
date: '2023-06-13'
image: assets/2023-06-13-enhancing-vespas-embedding-management-capabilities/multilingual-embedding-model.png
tags: []
author: jobergum bjorncs
skipimage: true
excerpt: >
    We are thrilled to announce significant updates to Vespa’s support for inference with text embedding models
    that maps texts into vector representations.
---

We are thrilled to announce significant updates to Vespa’s support for inference with text embedding models
that maps texts into vector representations.
These improvements aim to provide developers with a seamless experience
and empower them with permissive open-source text embedding models.
Vespa’s best-in-class vector and [multi-vector](https://blog.vespa.ai/semantic-search-with-multi-vector-indexing/)
search support and inferences with embedding models
allow developers to build feature-rich semantic search applications
without managing separate systems for model inference and vector search over embedding representations.


## About text embedding models
Text embedding models have revolutionized natural language processing (NLP) and information retrieval tasks
by capturing the semantic meaning of unstructured text data.
Unlike traditional representations that treat words as discrete symbols,
embedding models map words or phrases into continuous vector spaces.

![multilingual embedding model](/assets/2023-06-13-enhancing-vespas-embedding-management-capabilities/multilingual-embedding-model.png)

One of the significant advantages of embedding is their ability to handle cross-lingual and multilingual applications.
These models can represent concepts across different languages through pre-training on massive multilingual datasets.
This opens up exciting possibilities for developers to create applications that seamlessly bridge language barriers,
enabling information retrieval across diverse linguistic contexts.


## Generic Support for Embedder Models from Huggingface
One of the key enhancements is the introduction of generic support for embedding models hosted on Huggingface.
Huggingface is a widely respected platform that offers a vast array of pre-trained models
for natural language processing tasks.
With the new HuggingfaceEmbedder functionality,
developers can export embedding models from Huggingface
and import them in ONNX format in Vespa for accelerated inference:

```
<container id="default" version="1.0">
    <component id="e5" type="hugging-face-embedder">
        <transformer-model model-id="cloud-model-id"
                           path="my-models/model.onnx"/>
        <tokenizer-model   model-id="cloud-model-id"
                           path="my-models/tokenizer.json"/>
    </component>
    ...
</container>
```

The HuggingfaceEmbedder also supports multilingual embedding models that handle 100s of languages.
Multilingual embedding representations open new possibilities for cross-lingual applications
using [Vespa linguistic processing](https://docs.vespa.ai/en/linguistics.html)
and multilingual vector representations to implement
[hybrid search](https://blog.vespa.ai/improving-zero-shot-ranking-with-vespa/).
The new HuggingfaceEmbedder also supports
[multi-vector representations](https://blog.vespa.ai/semantic-search-with-multi-vector-indexing/),
simplifying deploying semantic search applications at scale
without maintaining complex fan-out relationships due to embedding model input length constraints.
Read more about the Huggingface embedding model integration in the
[documentation](https://docs.vespa.ai/en/embedding.html#huggingface-embedder).


## GPU Acceleration of inferencing with embedding models
Vespa now supports GPU acceleration of embedding model inferences.
By harnessing the power of GPUs, Vespa embedders can efficiently process large amounts of text data,
resulting in [faster response times, improved scalability, and lower cost](https://blog.vespa.ai/gpu-accelerated-ml-inference-in-vespa-cloud/).
GPU support in Vespa also unlocks using larger and more powerful embedding models
while maintaining low serving latency and cost-effectiveness.

GPU acceleration is automatically enabled in Vespa Cloud for node instances where a GPU is available.
Just configure the container cluster with a [GPU resource in services.xml](https://cloud.vespa.ai/en/reference/services#gpu).
For open-source Vespa, specify the GPU device id through the
[embedder ONNX configuration](https://docs.vespa.ai/en/reference/embedding-reference.html#embedder-onnx-reference-config).  


## New and Improved Embedding Models on Vespa Model Hub
To further enrich the Vespa Cloud ecosystem,
we introduce new and state-of-the-art embedding models on the Vespa Model Hub for Vespa Cloud users.
The Vespa Model Hub is a centralized repository of selected models,
making it easier for developers to discover and use powerful open-source embedding models.

This expansion of the model hub provides developers with a broader range of embedding options.
It empowers them to make tradeoffs related to embedding quality, inference latency,
and embedding dimensionality-related resource footprint.

We expand the hub with the following best-in-class open-source embedding models: 

<style>
.styled-table {
    font-size: 0.9rem;
}
</style>

{:.styled-table}

| Embedding Model                                                                                      | Dim  | [Metric](https://docs.vespa.ai/en/reference/schema-reference.html#distance-metric)  | Language     | Model Id             |
|------------------------------------------------------------------------------------------------------|------|---------|--------------|----------------------|
| [huggingface.co/intfloat/e5-small-v2](https://huggingface.co/intfloat/e5-small-v2)                   | 384  | angular | English      | e5-small-v2          |
| [huggingface.co/intfloat/e5-base-v2](https://huggingface.co/intfloat/e5-base-v2)                     | 768  | angular | English      | e5-base-v2           |
| [huggingface.co/intfloat/e5-large-v2](https://huggingface.co/intfloat/e5-large-v2)                   | 1024 | angular | English      | e5-large-v2          |
| [huggingface.co/intfloat/multilingual-e5-base](https://huggingface.co/intfloat/multilingual-e5-base) | 768  | angular | Multilingual | multilingual-e5-base |

<p> </p>
These embedding models perform strongly on various tasks,
as demonstrated on the [MTEB: Massive Text Embedding Benchmark leaderboard](https://huggingface.co/blog/mteb).
The MTEB  leaderboard provides a holistic view of the best text embedding models for various tasks.
MTEB includes 56 datasets across 8 tasks, such as semantic search, clustering, classification, and re-ranking.
The e5 embedding series from Microsoft comes in 3 sizes small 384, base 768, and large 1024 dimensions.

![MTEB](/assets/2023-06-13-enhancing-vespas-embedding-management-capabilities/mteb.png)
<small><em>MTEB Leaderboard, notice the strong performance of the E5-v2 models</em></small>

Developers can point their configuration to a Vespa Cloud Model hub identifier
and do not need to provide anything else:

```
<component id="e5" type="hugging-face-embedder">
    <transformer-model model-id="e5-small-v2"/>
</component>
```

Producing the embeddings closer to the Vespa storage and indexes avoids network transfer-related latency and egress costs,
which can be substantial for high-dimensional vector representations.
In addition, with Vespa Cloud’s [auto-scaling feature](https://cloud.vespa.ai/en/autoscaling),
developers do not need to worry about scaling with changes in traffic or compute demanding batch jobs.
Vespa Cloud also allows bringing your models using the generic HuggingFaceEmbedder.
Embedding models are automatically accelerated with GPU if the application uses
[Vespa Cloud GPU instances](https://blog.vespa.ai/gpu-accelerated-ml-inference-in-vespa-cloud/).
Read more on the [Vespa Cloud model hub](https://cloud.vespa.ai/en/model-hub).


## Summary
The improved Vespa embedding management options offer a significant leap forward in Vespa’s embedding capabilities,
enabling developers to leverage state-of-the-art models, accelerate inference with GPUs,
and access a broader range of embedding options through the Vespa Model Hub.
All this functionality is available in Vespa 8.176.* and above.  

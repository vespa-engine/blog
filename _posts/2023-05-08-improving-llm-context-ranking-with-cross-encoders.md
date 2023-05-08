---  
layout: post 
title: "Minimizing LLM Distraction with Cross-Encoder Re-Ranking"
author: bjorncs arnej jobergum 
date: '2023-05-08' 
image: assets/2023-05-08-improving-llm-context-ranking-with-cross-encoders/will-van-wingerden-dsvJgiBJTOs-unsplash.jpg
skipimage: true 
tags: [] 
excerpt: Announcing multi-vector indexing support in Vespa, which allows you to index multiple vectors per document and retrieve documents by the closest vector in each document.
---

![Decorative
image](/assets/2023-05-08-improving-llm-context-ranking-with-cross-encoders/will-van-wingerden-dsvJgiBJTOs-unsplash.jpg)
<p class="image-credit">Photo by <a href="https://unsplash.com/@willvanw?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Will van Wingerden</a> on <a href="https://unsplash.com/photos/dsvJgiBJTOs?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
</p>


This blog post announces Vespa support for the declarative expression
of global re-ranking, further streamlining the process of deploying
multi-phase ranking pipelines at [massive
scale](https://engineering.atspotify.com/2022/03/introducing-natural-language-search-for-podcast-episodes/)
without writing code or managing complex inference infrastructure.


## Introduction

Connecting Large Language Models (LLMs) with text retrieved using
a search engine or a vector database is becoming popular. However,
retrieving irrelevant text can cause LLMs to generate incorrect
responses, as demonstrated in [Large Language Models Can Be Easily
Distracted by Irrelevant Context](https://arxiv.org/abs/2302.00093).
In other words, the quality of the retrieval and ranking stages
sets an upper bound on the effectiveness of the overall retrieval-augmented
LLM pipeline.

Transformer models such as BERT have shown an impressive enhancement
over previous text ranking methods, with
[multi-vector](https://blog.vespa.ai/semantic-search-with-multi-vector-indexing/)
and
[cross-encoder](https://blog.vespa.ai/pretrained-transformer-language-models-for-search-part-4/)
models **outperforming** single-vector representation models.
Multi-vector and cross-encoder models are more complex but shine
in a [zero-shot
setting](https://blog.vespa.ai/improving-zero-shot-ranking-with-vespa/)
without in-domain fine-tuning. Cross-encoder models encode the query
and document as input, allowing for deep token cross-interactions
and a better ranking, as demonstrated on the [BEIR
benchmark](https://github.com/beir-cellar/beir). The downside of
cross-encoders for text ranking is their computational complexity,
which is quadratic with the query and document lengths. The
computational complexity makes them only suitable for re-ranking
phases, where more efficient retrieval and ranking models have
significantly pruned the number of documents in advance.


## Phased ranking

Vespa has best-in-class support for expressing [multi-phased retrieval
and ranking](https://docs.vespa.ai/en/phased-ranking.html). Using
multi-stage retrieval and ranking pipelines is an industry best
practice for _efficiently _matching and ranking content. The basic
concept behind this approach is to use a ranking model at each stage
of the pipeline to filter out less relevant candidates, thereby
reducing the number of documents ranked at each subsequent stage.
By following this method, the number of documents gradually decreases
until only the top-ranking results remain, which can be returned
or used as input for an LLM prompt. Vespa supports distributed
search, where Vespa [distributes data
elastically](https://docs.vespa.ai/en/elasticity.html) across
multiple stateful content nodes. Each stateful Vespa content node
performs local-optimal retrieval and ranking over a subset of all
the data.

With the new declarative global re-ranking support, Vespa can run
inference and re-rank results _after_ finding the top-ranking
documents from all nodes after executing the local per-node ranking
phases.

## Introducing global ranking phase

Vespa configures rank expressions in
[rank-profiles](https://docs.vespa.ai/en/ranking.html) in the
document schema(s), allowing the user to express how retrieved
documents are ranked.

<pre>
rank-profile phased {
  first-phase {
    expression: log(bm25(title)) + cos(distance(field,embedding))    
  }
  second-phase {
    expression { firstPhase + lightgbm("f834_v2.json")}
    rerank-count: 1000
  }
}
</pre>

In the above declarative rank-profile example, the developer has
specified a [hybrid
combination](https://blog.vespa.ai/improving-zero-shot-ranking-with-vespa-part-two/)
of [dense vector
similarity](https://docs.vespa.ai/en/approximate-nn-hnsw.html) and
exact keyword scoring
([bm25](https://docs.vespa.ai/en/reference/bm25.html)) as the
first-phase function. The per node top 1K ranking documents from
the first phase are re-ranked using a machine-learned model, which
uses Vespa’s support for scoring with
[LightGBM](https://docs.vespa.ai/en/lightgbm.html) models.

Each node running the query would execute the first and second
ranking phases. Finally, the per-node ranking result is merged based
on the second-phase score into globally ordered top-ranking hits.
With the declarative global-phase introduced, users can add a new
ranking phase:

<pre>
rank-profile global-phased {
  first-phase {
    expression: log(bm25(title)) + cos(distance(field,embedding))    
  }
  second-phase {
    expression { firstPhase + lightgbm("f834_v2.json")}
    rerank-count: 1000
  }
   global-phase {
    expression { sum(onnx(transformer).score) } 
    rerank-count: 100
  }
}
</pre>

With *global-phase* support, developers can express a new phase on
top of the merged and globally ordered results from the previous
distributed ranking phases. The stateless containers evaluate the
global-phase expression. The stateless containers also scatter and
gather hits from the stateful content nodes, and the global ranking
stage happens after merging the results.

The above global phase expression re-ranks the top-100 results using
a [Transformer based cross-encoder
](https://blog.vespa.ai/pretrained-transformer-language-models-for-search-part-4/)mode.
Vespa supports
[inference](https://blog.vespa.ai/stateless-model-evaluation/) with
[ONNX models](https://docs.vespa.ai/en/onnx.html), both close to
the data on [content
nodes](https://blog.vespa.ai/stateful-model-serving-how-we-accelerate-inference-using-onnx-runtime/)
and in the [Vespa stateless
containers](https://blog.vespa.ai/stateless-model-evaluation/).
Vespa does deploy-time verification of the global-phase expression
and derives the required inputs to the model. The document-side
feature inputs are sent from the stateful content nodes to the
stateless container nodes, along with the hit data. The Vespa
internal RPC protocol between the stateless and stateful clusters
uses a binary format and avoids [network serialization
](https://blog.vespa.ai/scaling-tensorflow-model-evaluation-with-vespa/)overheads.

![Vespa phased ranking](/assets/2023-05-08-improving-llm-context-ranking-with-cross-encoders/image1.png)
<font size="2"><i>Illustration of phased ranking in Vespa. Distributed matching and ranking and stateless re-ranking after merging (global-phase).</i></font>

## Accelerated global phase re-ranking using GPU

We just announced [GPU-accelerated ML inference in Vespa
Cloud](https://blog.vespa.ai/gpu-accelerated-ml-inference-in-vespa-cloud/),
and global-phase ranking expressions can use GPU acceleration for
inference with ONNX models if the instance runs on a [CUDA-compatible
GPU](https://docs.vespa.ai/en/vespa-gpu-container.html). Since the
global phase is performed in the stateless container service, scaling
the number of instances is much faster than scaling content nodes,
which requires data movement.

With the Vespa Cloud’s [autoscaling](https://cloud.vespa.ai/en/autoscaling)
of GPU-powered stateless container instances, Vespa users can benefit
from reduced serving-related costs and increased performance. Enable
GPU acceleration by specifying the GPU device number to run the
model on.
<pre>
rank-profile global-phased {
   onnx-model transformer {
      ...
      gpu-device: 0
   }
}
</pre>

## Summary

With the new declarative stateless
[ranking](https://docs.vespa.ai/en/ranking.html) phase support in
Vespa, search developers can quickly deploy and use state-of-the-art
cross-encoders for re-ranking. As demonstrated on the BEIR benchmark,
cross-encoders are generally more robust and achieve far better
zero-shot ranking than single vector models using cosine similarity.

Global phase re-ranking is available from Vespa 8.153. See the [transformer
ranking](https://github.com/vespa-engine/sample-apps/tree/master/transformers)
sample application and [documentation
](https://docs.vespa.ai/en/phased-ranking.html#global-phase)to get
started with global-phase ranking and reduce LLM distraction. Got
questions about this feature or Vespa in general? Join our community
[Slack channel](https://slack.vespa.ai/) to learn more.

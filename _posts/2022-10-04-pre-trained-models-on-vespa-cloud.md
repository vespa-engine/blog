---
layout: post
title: "Pre-trained models on Vespa Cloud"
author: bratseth
date: '2022-10-04'
image: assets/2022-10-04-pre-trained-models-on-vespa-cloud/pre-trained.png
tags: [vector search, semantic search, embeddings, ML, models, vespa cloud]
skipimage: true
excerpt: Vespa Cloud now provides pre-trained ML models for your applications
---

![Decorative image](/assets/2022-10-04-pre-trained-models-on-vespa-cloud/pre-trained.png)
<p class="image-credit">
"searching data using pre-trained models, unreal engine high quality render, 4k, glossy, vivid_colors, intricate_detail" by Stable Diffusion
</p>

# Pre-trained models on Vespa Cloud

Vespa can now [https://blog.vespa.ai/text-embedding-made-simple/](convert text to embeddings for you automatically), 
if you don’t want to bring your own vectors - but you still need to provide the ML models to use.

On Vespa Cloud we’re now making this even simpler, by also providing pre-trained models you can use for such tasks. 
To take advantage of this, just pick the models you want from 
[https://cloud.vespa.ai/en/model-hub](https://cloud.vespa.ai/en/model-hub) and refer 
to them in your application by supplying a model-id where you would otherwise use path or url. For example:

```
<component id="myEmbedderId"
           class="ai.vespa.embedding.BertBaseEmbedder"
           bundle="model-integration">
    <config name="embedding.bert-base-embedder">
        <transformerModel model-id="minilm-l6-v2"/>
        <tokenizerVocab model-id="bert-base-uncased"/>
    </config>
</component>
```

You can deploy this to Vespa Cloud to have these models do their job in your application - 
no need to include a model in your application and wait for it to be uploaded.

You can use these models both in configurations provided by Vespa, as above, and in your own components, 
with your own configurations - see the [documentation](https://cloud.vespa.ai/en/model-hub) for details.

We’ll grow the set of models available over time, but the models we provide on Vespa Cloud will always be an 
exclusive selection of models that we think it is beneficial to use in real applications, 
both in terms of performance and model quality.

We hope this will empower many more teams to leverage modern AI in their production use cases.

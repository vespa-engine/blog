---
layout: post
title: "Text embedding made simple"
author: bratseth
date: '2022-09-20'
image: assets/2022-09-20-text-embedding-made-simple/embeddings.png
tags: [vector search, semantic search, embeddings, ANN, HNSW]
skipimage: true
excerpt: Vespa now lets you create a production quality semantic search application from scratch in minutes
---

![Decorative image](/assets/2022-09-20-text-embedding-made-simple/embeddings.png)
<p class="image-credit">
"searching data using vector embeddings, unreal engine, high quality render, 4k, glossy, vivid colors, intricate detail" by Stable Diffusion
 </p>

# Text embedding made simple

[Embeddings](https://docs.vespa.ai/en/embedding.html) are the basis for modern semantic search and neural ranking, 
so the first step in developing such features is to convert your document 
and query text to embeddings.

Once you have the embeddings, Vespa.ai makes it easy to use them efficiently 
to [find neighbors](https://docs.vespa.ai/en/approximate-nn-hnsw.html) 
or [evaluate machine-learned models](https://docs.vespa.ai/en/onnx.html), 
but you’ve had to create 
them either on the client side or by writing your own Java component. 
Now, we’re providing this building block out of the platform as well.

On Vespa 8.54.61 or higher, simply add this to your services.xml file under &lt;container&gt;:

```
<component id="bert" class="ai.vespa.embedding.BertBaseEmbedder" bundle="model-integration">
    <config name="embedding.bert-base-embedder">
        <transformerModel path="models/bert-embedder.onnx"/>
        <tokenizerVocab path="models/vocab.txt"/>
    </config>
</component>
```

The model files here can be any [BERT style model](https://www.sbert.net) and vocabulary, we recommend this one: https://huggingface.co/sentence-transformers/msmarco-MiniLM-L-6-v3.

With this deployed, you can automatically 
[convert query text](https://docs.vespa.ai/en/embedding.html#embedding-a-query-text) 
to an embedding by writing embed(bert, “my text”) where you would otherwise supply an embedding tensor. For example:

    input.query(myEmbedding)=embed(bert, "Hello world")

And to 
[create an embedding from a document field](https://docs.vespa.ai/en/embedding.html#embedding-a-document-field) 
you can add

    field myEmbedding type tensor(x[384]) {
        indexing: input myTextField | embed bert
    }

to your schema outside the document block.

## Semantic search sample application

To get you started we have created a complete and minimal sample application using this:
[simple-semantic-search](https://github.com/vespa-engine/sample-apps/tree/master/simple-semantic-search).

## Furthe reading

This should make it easy to get started with embeddings. If you want to dig deeper into the topic, 
be sure to check out this blog post series on 
[using pretrained transformer models for search](https://blog.vespa.ai/pretrained-transformer-language-models-for-search-part-1/), 
and this on efficiency in 
[combining vector search with filters](https://blog.vespa.ai/constrained-approximate-nearest-neighbor-search/).

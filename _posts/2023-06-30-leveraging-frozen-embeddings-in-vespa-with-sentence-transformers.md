---
layout: post
title: Leveraging frozen embeddings in Vespa with SentenceTransformers
date: '2023-06-30'
image: assets/2023-06-30-leveraging-frozen-embeddings-in-vespa-with-sentence-transformers/abstract.png
categories: []
tags: []
author: dnmca
skipimage: true
excerpt: >
    How to implement frozen embeddings approach in Vespa using SentenceTransformers library and optimize your search application at the same time.
---

![Decorative
image](/assets/2023-06-30-leveraging-frozen-embeddings-in-vespa-with-sentence-transformers/abstract.png)

## Introduction

Hybrid search is an information retrieval approach that combines traditional lexical search with semantic search based on vector representation of search subjects. 

Despite being pretty easy to setup with Vespa, hybrid search could be very tedious in support, especially in a setting with millions of documents and regular changes in user search patterns, which result in regular text embedding model re-training.

One example of such a setting could be e-commerce.

Updating tens of millions document embeddings every time similarity model is retrained is not fun. As mentioned in the [Vespa's article](https://blog.vespa.ai/tailoring-frozen-embeddings-with-vespa/) on the topic, getting new embedding model into production requires roughly 3 steps:

* Re-calculating embeddings for all existing documents using new embedding model
* Index new vectors with Vespa
* Evaluate new model and get rid of the old embeddings

As number of possible objects having vector representation inside Vespa increases, the burden of maintaining them becomes tedious.

In aforementioned article, Vespa Team proposes an elegant solution to this problem, called "frozen embeddings".

Basically, it is an idea that we could freeze vector representations of the documents stored inside Vespa and update only query representations as embedding model is being retrained due to user search patterns change.

In this article, we want to explore the implementation details of the Vespa search application that leverages frozen embeddings obtained from the model built with `sentence-transformers` library.

## Model training

The most effective approach to training a semantic similarity model that would produce quality embeddings of textual data is based on two-tower transformer architecture called *bi-encoder*. 

Bi-encoder is trained using dataset consisting of text pairs annotated with similarity labels. In e-commerce setting, for example, text pair would be (search query, product title) with associated similarity score or class.

By passing each element of the text pair through encoder, we obtain 2 vector representations. Then, using specified loss function, encoder weights are updated depending on how close predicted similarity between these vectors was to ground true similarity.

Despite it's name, this "two-tower" transformer often uses shared transformer weights. As a result, the same model is used to encode both queries and documents. 

Depending on the language of your documents and queries, you would use some pre-trained weights to train your bi-encoder. One good choice for common European languages is to use [xlm-roberta-base](https://huggingface.co/xlm-roberta-base). It supports 100 languages and is one of the most powerful small multi-language open-source language models out there.

The simplest way to train bi-encoder is to use [sentence-transformers](https://www.sbert.net/) package. It is a framework for state-of-the-art sentence, text and image embeddings built on the top of the famous [transformers](https://huggingface.co/docs/transformers/) library.

By default, bi-encoder model built with `sentence-transformers` library would share weights for query and document. The reason behind this design decision is the fact that shared weights lead to better representational ability of the underlying encoder.

But in order to train model suitable for generation of frozen embeddings, we would need to make non-trivial changes to the default bi-encoder training procedure provided by `sentence-transformers` library.

First, we would need to decide how to achieve asymmetry in the representation of query and document.

In the context of `sentence-transformenrs`, there are 2 possible ways to reach this asymmetry:

1. Share transformer weights and use 2 dense layers on the top of transformer to generate asymmetric representations of query and document.
    ```
    from sentence_transformers import SentenceTransformer
    from sentence_transformers import models
    
    EMBEDDING_DIM = 384

    word_embedding_model = models.Transformer('xlm-roberta-base')
    
    pooling_model = models.Pooling(
        word_embedding_model.get_word_embedding_dimension(),
        pooling_mode_mean_tokens=True,
        pooling_mode_cls_token=False,
        pooling_mode_max_tokens=False
    )
    
    in_features = word_embedding_model.get_word_embedding_dimension()
    out_features = EMBEDDING_DIM
    
    q_dense = models.Dense(
        in_features=in_features,
        out_features=out_features,
        bias=False,
        init_weight=torch.eye(out_features, in_features),
        activation_function=nn.Identity()
    )
    
    d_dense = models.Dense(
        in_features=in_features,
        out_features=out_features,
        bias=False,
        init_weight=torch.eye(out_features, in_features),
        activation_function=nn.Identity()
    )
    
    asym_model = models.Asym({'query': [q_dense], 'doc': [d_dense]})
    
    model = SentenceTransformer(
        modules=[word_embedding_model, pooling_model, asym_model]
    )
    ```

2. Use 2 different transformers for query and document:
    ```
    q_word_embedding_model = models.Transformer('xlm-roberta-base')
    
    q_pooling_model = models.Pooling(
        q_word_embedding_model.get_word_embedding_dimension(),
        pooling_mode_mean_tokens=True,
        pooling_mode_cls_token=False,
        pooling_mode_max_tokens=False
    )
    
    d_word_embedding_model = models.Transformer('xlm-roberta-base')
    
    d_pooling_model = models.Pooling(
        d_word_embedding_model.get_word_embedding_dimension(),
        pooling_mode_mean_tokens=True,
        pooling_mode_cls_token=False,
        pooling_mode_max_tokens=False
    )
    
    q_model = SentenceTransformer(modules=[q_word_embedding_model, q_pooling_model])
    d_model = SentenceTransformer(modules=[d_word_embedding_model, d_pooling_model])
    
    asym_model = models.Asym({'query': [q_model], 'doc': [d_model]})
    model = SentenceTrasformer(modules=[asym_model])
    ```

Additional dense layers could be added here as well to decrease dimensionality. We skip it here for simplicity.

According to the experiments conducted with our proprietary data, these 2 approaches provide similar information retrieval performance. But first one is much more efficient with regard to disc memory usage. 

It is especially important if we take into account current limitation of 2GB on the content of `models/` folder in Vespa's application package.

So, we end up using 2 dense layers to achieve asymmetry in our bi-encoder. 

But how do we train this model correctly to generate frozen embeddings?

There are also 2 possible approaches.

1. We could first train bi-encoder with shared transformer and dense parts using the data that consists of (document, document) text pairs. This would result in good document embedder that could be used to generate document embeddings for Vespa and further training of bi-encoder with asymmetric dense layers. It should be noted that in subsequent model re-trainings transformer and document dense layer weights need to be frozen.

2. We could make an "initial" training with asymmetric bi-encoder using query-document text pairs and freeze transformer and document dense layer weights in all subsequent training of the bi-encoder. As a result, document embeddings generated by such model would be automatically "frozen".

We wouldn't discuss other training details since they depend a lot on dataset format, loss function choice and training environment.

One additional detail that should be explained is the usage of activation function in asymmetrical layers. By default, `sentence-transformers` uses `tanh` activation function in `models.Dense` layer. But since it's not currently implemented in Vespa's Tensor API, we decided to use `identity` activation without bias term. This simplifies the usage of this additional layer to straightforward matrix multiplication, which could be easily done with `matmul` method of `Tensor` class.

## Model preparation
The format in which model is stored by `sentence-transformers` is not directly applicable for Vespa. 

In order to integrate our asymmetric bi-encoder model in Vespa, we need to make few preparations.

First, let's first take a look into structure of files produced by `sentence-transformers` as a result of training:

```
model/
├── 1_Pooling
│   └── config.json
├── 2_Asym
│   ├── 139761904414624_Dense
│   │   ├── config.json
│   │   └── pytorch_model.bin
│   ├── 139761906488608_Dense
│   │   ├── config.json
│   │   └── pytorch_model.bin
│   └── config.json
├── config.json
├── config_sentence_transformers.json
├── eval
│   └── accuracy_evaluation_dev_results.csv
├── modules.json
├── pytorch_model.bin
├── README.md
├── sentence_bert_config.json
├── special_tokens_map.json
├── tokenizer_config.json
└── tokenizer.json
```

Out of all these files, we would need to use only 4:
```
model/tokenizer.json     # shared tokenizer
model/pytorch_model.bin  # shared transformer
model/2_Asym/139761904414624_Dense/pytorch_model.bin # query dense layer
model/2_Asym/139761906488608_Dense/pytorch_model.bin # document dense layer
```

### Transformer onnx export

In order to integrate our transformer into Vespa, we need to export it to ONNX format. This is done using [optimum-cli](https://huggingface.co/docs/optimum/exporters/onnx/usage_guides/export_a_model):

```
optimum-cli export onnx --framework pt --task feature-extraction --model ./model/ ./model/onnx/
```

Resulting file `./model/onnx/model.onnx` needs to be added to Vespa application package.

### Tokenizer export

Tokenizer file is not changed and could be directly copied to Vespa application package.

### Dense layers export
Dense layer weights matrix needs to be exported to plain text file in a specific format:

```
layer_name_2_type = {
	"139761904414624_Dense": "query",
	"139761906488608_Dense": "doc"
}

for k, v in layer_name_2_type.items():
	dense_layer = torch.load(f'model/2_Asym/{k}/pytorch_model.bin')
	with open(f'{v}_dense_layer.txt', 'w') as file:
	    tensor_str = f"tensor<float>(x[384],y[768]):{dense_layer['linear.weight'].cpu().numpy().tolist()}"
	    file.write(tensor_str)
```

Resulting files `doc_dense_layer.txt` and `query_dense_layer.txt` need to be added to Vespa application package.

As a result of these actions 	you'll have a following structure of your application package's `models` folder:

```
src/main/application/models/
├── doc_dense_layer.txt
├── query_dense_layer.txt
├── tokenizer.json
└── model.onnx
```

## Model integration

With their latest [update](https://blog.vespa.ai/enhancing-vespas-embedding-management-capabilities/) Vespa has made it very easy to integrate HuggingFace feature-generation models as embedders. 

But despite having almost all necessary functionality, it does not allow us to integrate a model with additional dense layer stacked over transformer with mean pooling. 

To achieve this, we need to implement our own `DenseAsymmetricHfEmbedder`. It would slightly differ from current Vespa's `HuggingFaceEmbedder`.

1. First, define an appropriate package name:
    ```
    package com.experimental.search.embedding;
    ```
2. Then we need to add an attribute to store dense layer weights:
    ```
    private final Tensor linearLayer;
    ```
3. `linearLayer` needs to be initialized in constructor from weights stored in plain text file
    ```
    try {
        String strTensor = Files.readString(Paths.get(config.linearLayer().toString()));
        this.linearLayer = Tensor.from(strTensor);
    } catch (IOException e) {
        throw new RuntimeException(e);
    }
    ```
4. Then we need to update `embed` method to include matrix multiplication:
    ```
    TensorType intermediate = TensorType.fromSpec("tensor<float>(x[768])");
    var result = poolingStrategy.toSentenceEmbedding(intermediate, tokenEmbeddings, attentionMask);
    var finalResult = linearLayer.matmul(result.rename("x", "y"), "y");
    return normalize ? normalize(finalResult, tensorType) : finalResult;
    ```

Also, we would need to create our own config definition file inside `src/resources/configdefinitions` called `dense-asymmetric-hf-embedder.def`, 

which would differ from [hugging-face-embedder.def](https://github.com/vespa-engine/vespa/blob/master/configdefinitions/src/vespa/hugging-face-embedder.def) by 2 lines:

```
-namespace=embedding.huggingface
+package=com.experimental.search.embedding;

+linearLayer model
```

Finally, we would need to setup document and query model configurations in `services.xml`

```
<component id="doc-embedder"
           class="com.experimental.search.embedding.DenseAsymmetricHfEmbedder"
           bundle="search-mvp">
    <config name="com.experimental.search.embedding.dense-asymmetric-hf-embedder">
        <tokenizerPath path="models/tokenizer.json"/>
        <transformerModel path="models/model.onnx"/>
        <linearLayer path="models/doc_dense_layer.txt"/>
        <normalize>true</normalize>
        <transformerTokenTypeIds/>
    </config>
</component>
<component id="query-embedder"
           class="com.experimental.search.embedding.DenseAsymmetricHfEmbedder"
           bundle="search-mvp">
    <config name="com.experimental.search.embedding.dense-asymmetric-hf-embedder">
        <tokenizerPath path="models/tokenizer.json"/>
        <transformerModel path="models/model.onnx"/>
        <linearLayer path="models/query_dense_layer.txt"/>
        <normalize>true</normalize>
        <transformerTokenTypeIds/>
    </config>
</component>
```

Now, we could easily use `doc-embedder` in our schema:
```
field title_embedding type tensor<float>(x[384]) {
    indexing: input title | embed doc-embedder | attribute | index
    attribute {
        distance-metric: innerproduct
    }
}
```

Or `query-embedder` in search requests:

```
import requests

text = "our search query"

r = requests.post(
    url=VESPA_DOC_API_URL,
    json={
        "yql": 'select * from product ' \
               'where ({targetHits:1000, approximate:false}nearestNeighbor(title_embedding, input_embedding))',
        "input.query(input_embedding)": f'embed(query-embedder, "{text}")',
        "hits": hits,
        "ranking": {"profile": "semantic"},
    },
    headers={
        'Content-Type': 'application/json'
    }
)
```

## Conclusions

The usage of frozen embeddings in your Vespa search application could substantially decrease efforts to support it in production with constant changes in search behavior patterns. It makes it much easier to maintain your application and update embedding models.

This specific implementation gives you additional benefits, such as:

* Plug-and-play training procedure with `sentence-transformers` library
* Shared transformer weights between document and query models, which decrease memory usage during deployment
* Possibility to easily decrease embedding size for objects that do not require high-dimensional representations
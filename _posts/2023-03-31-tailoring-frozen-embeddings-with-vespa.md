---  
layout: post 
title: "Tailoring Frozen Embeddings with Vespa"
author: jobergum 
date: '2023-03-30' 
image: assets/2023-03-31-tailoring-frozen-embeddings-with-vespa/fabio-oyXis2kALVg-unsplash.jpg
skipimage: true 
tags: [] 
excerpt: Deep learned embeddings are becoming popular for search and recommendation use cases and the need for efficient ways to manage and operate embeddings in production is becoming critical.
---

![Decorative
image](/assets/2023-03-31-tailoring-frozen-embeddings-with-vespa/fabio-oyXis2kALVg-unsplash.jpg)
<p class="image-credit">Photo by <a href="https://unsplash.com/@fabioha?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">fabio</a> on <a href="https://unsplash.com/photos/oyXis2kALVg?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
</p>

Deep learned embeddings are becoming popular for search and recommendation use cases and the need for efficient ways to manage and operate embeddings in production is becoming critical. One emerging approach is to use 
frozen models which outputs frozen embeddings that are re-used and tailored for different tasks. 

This post introduces three techniques for using and tailoring frozen embeddings with Vespa. 

## Background

![Deep Learning for Embeddings Overview](/assets/2023-03-31-tailoring-frozen-embeddings-with-vespa/image1.png)


Encoding data objects using deep learning models allow for representing
objects in a high-dimensional vector space. In this latent **embedding
vector** space, one can compare the objects using vector distance
functions, which can be used for search, recommendation, classification,
and clustering. There are three primary ways developers can introduce
embedding representations of data in their applications:

* Using commercial embedding providers 
* Using off-the-shelf open-source embedding models 
* Training custom embedding models

All three incur training and inference (computational) costs, which
are proportional to the size of the model, the number of objects
and the input sizes. In addition, the output vector embedding must
be stored and potentially [indexed](https://docs.vespa.ai/en/approximate-nn-hnsw.html) 
for efficient retrieval.

## Deploy and Maintain ML Embeddings in Production (EmbeddingOps)

Suppose we want to modify an embedding model by fine-tuning it or
replacing it entirely. Then, all our data objects must be reprocessed
and embedded again. This might be easy to manage for small-scale
applications with a few million data points, but it quickly
gets out of hand with larger-scale evolving datasets in production.

Consider a case where we have an evolving dataset of 10M news
articles that we have implemented [semantic
search](https://blog.vespa.ai/semantic-search-with-multi-vector-indexing/)
for, using a model that embeds query and document texts into vector
representations. Our search service has been serving production
traffic for some time, but now the ML team wants to change the
embedding model, a model which has demonstrated strong performance
during offline evaluation.  Now, to get this new model into production
for online evaluation we need to follow [these steps](https://docs.vespa.ai/en/tutorials/models-hot-swap.html):

* Run inference with the new model over all documents to obtain the new vector embedding. 
This stage requires infrastructure to run inferences with the model or pay an embedding inference provider per inference.
 We still need to serve the current embedding model which is in production, used to embed new documents and the current real-time stream of queries. 
 
* Index the new vector embedding representation to the
serving infrastructure that we use for efficient vector search. If
we are fortunate enough to be using [Vespa](https://vespa.ai/), which supports 
[nearest neighbor search with filtering](https://blog.vespa.ai/constrained-approximate-nearest-neighbor-search/),
we can index the new embedding in a new field, without duplicating
other schema fields. Adding the new vector field still adds to the serving cost,
as we double the resource usage footprint related to indexing and storage. 

* After all this, we are finally ready to evaluate the new embedding
model online. Depending on the outcome of the online evaluation, we can
garbage collect either the new or old embedding data. 

That's a lot of complexity and cost to evaluate a model online, but now we can relax? 
Wait, our PM now wants to introduce [news article recommendations](https://docs.vespa.ai/en/tutorials/news-4-embeddings.html)
for the home page, and the ML team is planning on using embeddins for this project. We also hear they are 
discussing a related articles feature, where for each article, one can suggest related articles. 
At the end of the year, we will face the challenge of maintaining and operating three different
embedding-based use cases. There must be a better way? What if we could somehow re-use the embeddings for multiple
tasks? 

## Frozen Embeddings to the Rescue
![Frozen embeddings](/assets/2023-03-31-tailoring-frozen-embeddings-with-vespa/image6.png)
<br/>

An emerging industry trend that addresses operationalizing related
complexity is to use [frozen foundational
embeddings](https://ai.facebook.com/blog/multiray-large-scale-AI-models/)
that can be [reused
](https://medium.com/pinterest-engineering/searchsage-learning-search-query-representations-at-pinterest-654f2bb887fc) for
different tasks without incurring the usual costs related to embedding
versioning, storage, or inference infrastructure.


![Vector Space Illustration](/assets/2023-03-31-tailoring-frozen-embeddings-with-vespa/image2.png)

_A frozen model embeds data Q and D into vector space. By transforming
the Q representation to Q’, the vector distance is reduced
`(d(D,Q') < d(D,Q)`. This illustrates fine-tuning of metric
distances over embeddings from frozen models. Note that the D representation
does not change, which is a practical property for search and
recommendation use cases with potentially billions of embedding
representations of items._

With frozen embeddings from frozen models, the data is embedded once using a foundational
embedding model. Developers can then tailor the representation to
specific tasks by adding transformation layers. The frozen model, will for the same
input, always produce the same frozen embedding representation. So as long as the input data
does not change, we will not need to invoke the model again. 

The following sections describe different methods
for tailoring frozen embeddings for search or recommendation use
cases. 

* Tuning the query tower in two-tower embedding models 
* Simple query embedding transformations 
* Advanced transformations using Deep Neural Networks

## Two-tower models

The industry standard for semantic vector search is using a two-tower
architecture based on a [Transformer](https://en.wikipedia.org/wiki/Transformer_(machine_learning_model)) based model. 

This architecture is also called a _bi-encoder_ model, as there is a query and document
encoder.  Most of the two-tower architecture models use the same
weights for both the query and document encoder. This is not ideal
as if we tune the model, we would need to re-embed all our items
again. By de-coupling the model weights of the query and document
tower, developers can treat the document tower as frozen. 
Then, when fine-tuning the model for the
specific task, developers tune the query tower and
leave the frozen document tower alone.

![Frozen Query Tower](/assets/2023-03-31-tailoring-frozen-embeddings-with-vespa/image3.png)

The frozen document tower and embeddings significantly reduce the
complexity and cost of serving and training. For example, during training, 
there is no need to encode the document as the document’s embedding representation can be fetched
directly from Vespa. This saves at least 2x of
computational complexity during training. In practice,
since documents are generally longer than queries and Transformer models
scales quadratic with input lengths, the computational saving is
higher than that. 

On the serving side in Vespa, there is no need to re-process the
documents, as the same input will produce the exact same frozen document embedding representation. 
This saves the compute of performing the
inference and avoids introducing embedding versioning. And,
because Vespa allows deploying multiple query tower models, 
applications may test the accuracy of new models, without re-processing documents, 
which allows for frequent model deployment and evaluations.

Managing complex infrastructure for producing text embedding vectors
could be challenging, especially at query serving time, with low
latency, high availability, and high query throughput. Vespa allows
developers to [represent embedding
models](https://blog.vespa.ai/text-embedding-made-simple/) in Vespa.
Consider the following schema, expressed using [Vespa’s schema
definition language](https://docs.vespa.ai/en/schemas.html):

<pre>
schema doc {
  document doc {
    field text type string {}  
  } 
  field embedding type tensor&lt;float&gt;(x[384]) { 
    indexing: input text | embed frozen | attribute | index
  }
}
</pre>

In this case, Vespa will produce embeddings using a `frozen` embedding
model, and at query time, we can either use the frozen model to
encode the query or a new fine-tuned model. Deplying multipe query tower models allows
for query time A/B testing which increases model deployment velocity and shortens
the ML feedback loop. 

<pre>
curl \
 --json "
  {
   'yql': 'select text from doc where {targetHits:10}nearestNeighbor(embedding, q)',
   'input.query(q)': 'embed(tuned, dancing with wolves)' 
  }" \
 https://vespaendpoint/search/
</pre>

Notice the first argument to the query request `embed` command. 
For each new query tower model, developers will add the model to a directory in
the [Vespa application
package](https://docs.vespa.ai/en/application-packages.html), and
give it a name, which is referenced at query inference time.
Re-deployment of new models is a live change, where Vespa automates
the model distribution to all the nodes in the cluster, without
service interruption or downtime.

<pre>
&lt;component id=&quot;frozen&quot; class=&quot;ai.vespa.embedding.BertBaseEmbedder&quot; bundle=&quot;model-integration&quot;&gt;
    &lt;config name=&quot;embedding.bert-base-embedder&quot;&gt;
        &lt;transformerModel path=&quot;models/frozen.onnx&quot;/&gt;
        &lt;tokenizerVocab path=&quot;models/vocab.txt&quot;/&gt;
    &lt;/config&gt;
&lt;/component&gt;

&lt;component id=&quot;tuned&quot; class=&quot;ai.vespa.embedding.BertBaseEmbedder&quot; bundle=&quot;model-integration&quot;&gt;
    &lt;config name=&quot;embedding.bert-base-embedder&quot;&gt;
        &lt;transformerModel path=&quot;models/tuned.onnx&quot;/&gt;
        &lt;tokenizerVocab path=&quot;models/vocab.txt&quot;/&gt;
    &lt;/config&gt;
&lt;/component&gt;
</pre>

Snippet from the Vespa application `services.xml` file, which defines the models and
names, see [represent embedding
models](https://blog.vespa.ai/text-embedding-made-simple/) for
details. 
Finally, how documents are [ranked](https://docs.vespa.ai/en/ranking.html) is expressed using
Vespa [ranking
expressions](https://docs.vespa.ai/en/ranking-expressions-features.html).

<pre>
rank-profile default inherits default {
  inputs {
    query(q) tensor&lt;float&gt;(x[384])
  }
  first-phase {
    expression: cos(distance(field,embedding))
  }
}
</pre>

## Simple embedding transformation

Simple linear embedding transformation is great for the cases where
developers use an embedding provider and don’t have access to the
underlying model weights. In this case tuning the model weights is
impossible, so the developers cannot adjust the embedding model
towers. However, the simple approach for adapting the model is to
add a linear layer on top of the embeddings obtained from the
provider.

The simplest form is to adjust the query vector representation by
multiplying it with a learned weights matrix. Similarly to the query
tower approach, the document side representation is frozen. This
example implements the transformation using [tensor compute
expressions](https://blog.vespa.ai/computing-with-tensors/) configured
with the [Vespa ranking](https://docs.vespa.ai/en/ranking.html)
framework.

<pre>
rank-profile simple-similarity inherits default {
  constants {
    W tensor&lt;float&gt;(w[128],x[384]): file: constants/weights.json
  }
 
  function transform_query() {
     expression: sum(query(q) * constant(W), w)   
  }

  first-phase {
    expression: attribute(embedding) * transform_query()
  }
}
</pre>

The learned weights are exported from any ML framework (e.g.,
[PyTorch](https://pytorch.org/),
[scikit-learn](https://scikit-learn.org/stable/)) used to train the
matrix weights. And the weights are exported to a [constant
tensor](https://docs.vespa.ai/en/tensor-user-guide.html#constant-tensors)
file. Meanwhile, the `transform_query` function [performs a vector
matrix
product](https://docs.vespa.ai/playground/#N4KABGBEBmkFxgNrgmUrWQPYAd5QGNIAaFDSPBdDTAF30gDUBTA2rAJwFoBbAQ1ocAlgA8wODlgAmAVzYA6MADEhHAM60wAd2ZgpzaEIB2uvmABurdhzAADRrbB8jUp2H6DRdgOq24kMlQAX0Cg0gxqclwGZhJAiAp8SJpIIwZGOJpMWIRIWmYjNU4AChFEAGYAXQBKOEQABnkAVmIwRpa25sqArJCMMMDkhOjc2PCUyjR4zDTc70ysqByofMKSrUQAFkriMqraxEQARnl61pOj8-kAJh2ka9PWh8uwB9viY8ewC6v3z7PvvIXidbt1pn1guMIEMoCNCAtyJMYQl6LkAIIWKycXgCYRiCTSOSaIRqMC0AAWuh4MgANrQhDgaUICAIhFgjGAsNAyZTMWxOE4XO5cV5nK41DIeDxjABzTmWGwU3QELBS9l6IQ8ApqNlGfzg0JQqZZbCTSBjaaJKjTBKzKAIlLLSASnjFRhgABUYG8rS01R6NAhEAhlRAQSAA),
returning a modified vector of the same dimensionality.

This representation is used to score the documents in the first-phase
ranking expression. Note that this is effectively represented as
[a re-ranking phase](https://docs.vespa.ai/en/phased-ranking.html)
as the query tensor used for the [nearestNeighbor](https://docs.vespa.ai/en/reference/query-language-reference.html#nearestneighbor) search is untouched. It's possible to transform the query tensor, before 
the `nearestNeighbor` search as well, using a custom [stateless searcher](https://github.com/vespa-engine/sample-apps/blob/master/msmarco-ranking/src/main/java/ai/vespa/examples/searcher/RetrievalModelSearcher.java). 

The weight tensor does not necessarily need to be a constant across
all users. For example, one can have a weight tensor per user, as
shown in the [recommendation use
case](https://docs.vespa.ai/en/tutorials/news-4-embeddings.html),
to unlock true personalization.


## Advanced transformation using Deep Neural Networks

Another approach for customization is to use the query and document
embeddings as input to another Deep Neural Network (DNN) model.
This approach can be combined with the previously mentioned
approaches because it's applied as a re-scoring model in a [phased
ranking](https://docs.vespa.ai/en/phased-ranking.html)pipeline.

<pre>
import torch.nn as nn
import torch
class CustomEmbeddingSimilarity(nn.Module):
	def __init__(self, dimensionality=384):
		super(CustomEmbeddingSimilarity, self).__init__()
		self.fc1 = nn.Linear(2*dimensionality, 256)
		self.fc2 = nn.Linear(256, 128)
		self.fc3 = nn.Linear(128, 64)
		self.fc4 = nn.Linear(64, 1)
	def forward(self, query , document):
		x = torch.cat((query, document), dim=1)
		x = nn.functional.relu(self.fc1(x))
		x = nn.functional.relu(self.fc2(x))
		x = nn.functional.relu(self.fc3(x))
		return torch.sigmoid(self.fc4(x))
dim = 384
ranker = CustomEmbeddingSimilarity(dimensionality=dim)
# Train the ranker model ..
# Export to ONNX for inference with Vespa 
input_names = ["query","document"]
output_names = ["similarity"]
document = torch.ones(1,dim,dtype=torch.float)
query = torch.ones(1,dim,dtype=torch.float)
args = (query,document)
torch.onnx.export(ranker,
                  args=args,
                  f="custom_similarity.onnx",
                  input_names = input_names,
                  output_names = output_names,
                  opset_version=15)

</pre>
The above [PyTorch](https://pytorch.org/) [model.py](https://github.com/vespa-engine/sample-apps/blob/master/custom-embeddings/model.py) snippet defines a custom
DNN-based similarity model which takes the query and document
embedding as input. This model is exported to [ONNX](https://onnx.ai/)
format for [accelerated
inference](https://blog.vespa.ai/stateful-model-serving-how-we-accelerate-inference-using-onnx-runtime/)
using Vespa’s support for [ranking with
ONNX](https://docs.vespa.ai/en/onnx.html) models.

<pre>
rank-profile custom-similarity inherits simple-similarity {
  function query() {
    # Match expected tensor input shape
    expression: query(q) * tensor&lt;float&gt;(batch[1]):[1]
  }
  function document() {
    # Match expected tensor input shape
    expression: attribute(embedding) * tensor&lt;float&gt;(batch[1]):[1]
  }
  onnx-model dnn {
    file: models/custom_similarity.onnx
    input "query": query
    input "document": document
    output "similarity": score
  }
  second-phase {
    expression: sum(onnx(dnn).score)
  }
}
</pre>
This model might be complex, so one typically use it as a second-phase expression, only scoring
the the highest ranking documents from the `first-phase` expression.

![Architecture](/assets/2023-03-31-tailoring-frozen-embeddings-with-vespa/image5.png)

_The [Vespa serving architecture
](https://docs.vespa.ai/en/overview.html)operates in the following
manner: The stateless containers performs inference using the embedding
model(s). The containers are stateless, which allows
for fast auto-scaling with changes in query and inference volume. 
Meanwhile, the stateful content nodes store (and index) the frozen
vector embeddings. Stateful content clusters are scaled
[elastically](https://docs.vespa.ai/en/elasticity.html) in
proportion to the embedding volume. Additionally, Vespa handles the
deployment of ranking and embedding models._

## Summary
In this post, we covered three different ways to use frozen models and frozen embeddings
with Vespa while still allowing for task-specific customization of
the embeddings. 

Simplify your ML-embedding use cases by getting started with the [custom
embeddings sample
application](https://github.com/vespa-engine/sample-apps/tree/master/custom-embeddings).
Deploy the sample application locally using the Vespa container
image or to [Vespa Cloud](https://cloud.vespa.ai/). Got questions?
Join the community in [Vespa Slack](http://slack.vespa.ai/).

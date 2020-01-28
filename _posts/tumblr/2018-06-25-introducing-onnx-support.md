---
layout: post
title: Introducing ONNX support
date: '2018-06-25T10:41:04-07:00'
tags: []
tumblr_url: https://blog.vespa.ai/post/175233055656/introducing-onnx-support
---
**ONNX (Open Neural Network eXchange) is an open format for the sharing of neural network and other machine learned models between various machine learning and deep learning frameworks. As the open big data serving engine, Vespa aims to make it simple to evaluate machine learned models at serving time at scale. By adding ONNX support in Vespa in addition to our existing TensorFlow support, we’ve made it possible&nbsp;to evaluate models from all the commonly used ML frameworks with low latency&nbsp;over large amounts of data.**

With the rise of deep learning in the last few years, we’ve naturally enough seen an increase of deep learning frameworks as well: TensorFlow, PyTorch/Caffe2, MxNet etc. One reason for these different frameworks to exist is that they have been developed and optimized around some characteristic, such as fast training on distributed systems or GPUs, or efficient evaluation on mobile devices. Previously, complex projects with non-trivial data pipelines have been unable to pick the best framework for any given subtask due to lacking interoperability between these frameworks. ONNX is a solution to this problem.

[ONNX](https://onnx.ai/) is an open format for AI models, and represents an effort to push open standards in AI forward. The goal is to help increase the speed of innovation in the AI community by enabling interoperability between different frameworks and thus streamlining the process of getting models from research to production.

There is one commonality between the frameworks mentioned above that enables an open format such as ONNX, and that is that they all make use of dataflow graphs in one way or another. While there are differences between each framework, they all provide APIs enabling developers to construct computational graphs and runtimes to process these graphs. Even though these graphs are conceptually similar, each framework has been a siloed stack of API, graph and runtime. The goal of ONNX is to empower developers to select the framework that works best for their project, by providing an extensible computational graph model that works as a common intermediate representation at any stage of development or deployment.

Vespa is an open source project which fits well within such an ecosystem, and we aim to make the process of deploying and serving models to production that have been trained on any framework as smooth as possible. Vespa is optimized toward serving and evaluating over potentially very large datasets while still responding in real time. In contrast to other ML model serving options, Vespa [can more efficiently evaluate models over many data points](http://blog.vespa.ai/2018-05-07-scaling-tensorflow-model-evaluation-with-vespa/). As such, Vespa is an excellent choice when combining model evaluation with serving of various types of content.

Our ONNX support is quite similar to our [TensorFlow support](http://blog.vespa.ai/2018-03-14-introducing-tensorflow-support/). Importing ONNX models is as simple as adding the model to the Vespa application package (under “models/”) and referencing the model using the new ONNX ranking feature:

    expression: sum(onnx("my\_model.onnx"))

The above expression runs the model and sums it to a single scalar value to use in ranking. You will have to provide the inputs to the graph. Vespa expects you to provide a macro with the same name as the input tensor. In the macro you can specify where the input should come from, be it a document field, constant or a parameter sent along with the query. More information can be had [in the documentation about ONNX import](http://docs.vespa.ai/documentation/onnx.html).

Internally, Vespa converts the ONNX operations to Vespa’s tensor API. We do the same for TensorFlow import. So the cost of evaluating ONNX and TensorFlow models are the same. We have put a lot of effort in optimizing the evaluation of tensors, and [evaluating neural network models can be quite efficient](http://docs.vespa.ai/documentation/onnx.html).

ONNX support is also quite new to Vespa, so we do not support all [current ONNX operations](https://github.com/onnx/onnx/blob/master/docs/Operators.md). Part of the reason we don’t support all operations yet is that some are potentially too expensive to evaluate per document, such as convolutional neural networks and recurrent networks (LSTMs etc). ONNX also contains an extension, [ONNX-ML](https://github.com/onnx/onnx/blob/master/docs/Operators-ml.md), which contains additional operations for non-neural network cases. Support for this extension will come later at some point. We are continually working to add functionality, so please reach out to us if there is something you would like to have added.

Going forward we are continually working on improving performance as well as supporting more of the ONNX (and ONNX-ML) standard. You can read more about ranking with [ONNX models in the Vespa documentation](http://docs.vespa.ai/documentation/onnx.html). We are excited to announce ONNX support. Let us know what you are building with it!


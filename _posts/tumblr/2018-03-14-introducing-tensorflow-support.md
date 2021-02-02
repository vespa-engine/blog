---
layout: post
title: Introducing TensorFlow support
date: '2018-03-14T12:37:26-07:00'
tags: []
tumblr_url: https://blog.vespa.ai/post/171861434281/introducing-tensorflow-support
---
In previous blog posts we have talked about [Vespa’s tensor API](http://docs.vespa.ai/en/tensor-user-guide.html) which enables some advanced ranking capabilities. The primary use case is for machine learned ranking, where you train your models using some machine learning framework, convert the models to Vespa’s tensor format, and deploy them to Vespa. This works well, but converting trained models to Vespa form is cumbersome.

We are now happy to announce a new feature that makes this process a lot easier: TensorFlow import. With this feature you can directly deploy models you’ve trained in TensorFlow to Vespa, and use these models during ranking. This means that the models are executed in parallel over multiple threads and machines for a single query, which makes it possible to evaluate the model over any number of data items and still bound the total response time. In addition the data items to evaluate with the TensorFlow model can be selected dynamically with a query, and with a cheaper first-phase rank function if needed. Since the TensorFlow models are evaluated on the nodes storing the data, we avoid sending any data over the wire for evaluation.

In this post we’d like to introduce this new feature by discussing how it works, some assumptions behind working with TensorFlow and Vespa, and how to use the feature.

Vespa is optimized to evaluate models repeatedly over many data items (documents). &nbsp;To do this efficiently, we do not evaluate the model using the TensorFlow inference engine. TensorFlow adds a non-trivial amount of overhead and instrumentation which it uses to manage potentially large scale computations. This is significant in our case, since we need to evaluate models on a micro-second scale. Hence our approach is to extract the parameters (weights) into Vespa tensors, and use the model specification in the TensorFlow graph to generate efficient Vespa tensor expressions.

Importing TensorFlow models is as simple as saving the TensorFlow model using the [SavedModel API](https://www.tensorflow.org/programmers_guide/saved_model#overview_of_saving_and_restoring_models), adding those files to the Vespa application package, and referencing the model using the new TensorFlow ranking feature. For instance, if your files are in _models/my\_model_ in the application package:

> _first-phase {  
> &nbsp; &nbsp; expression: sum(tensorflow(“my\_model/saved”))  
> }_

The above expressions runs the model, and sums it to a single scalar value to use in ranking. &nbsp;One thing you will have to provide is the input(s), or feed, to the graph. Vespa expects you to provide a macro with the same name as the input placeholder. In the macro you can specify where the input should come from, be it a parameter sent along with the query, a document field (possibly in a parent document) or a constant.

As mentioned, Vespa evaluates the imported models once per document. Depending on the requirements of the application, this can impose some natural limitations on the size and complexity of the models that can be evaluated. However, Vespa has a number of other search and rank features that can be used to reduce the search space before running the machine learned models. Typically, one would use the search and first ranking phases to select a relatively small number of candidate documents, which are then given their final rank score in the more computationally expensive second phase model evaluation.

Also note that TensorFlow import is new to Vespa, and we currently only support a subset of the [TensorFlow operations](https://www.tensorflow.org/api_docs/cc/). While the supported operations should suffice for many relevant use cases, there are some that are not supported yet due to potentially being too expensive to evaluate per document. For instance, convolutional networks and recurrent networks (LSTMs etc) are not supported. We are continually working to add functionality, if you find that we have some glaring omissions, please let us know.

Going forward we are focusing on further improving performance of our tensor framework for important use cases. We’ll follow up this post with one showing how the performance of evaluation in Vespa compares with TensorFlow serving. We will also add more supported frameworks and our next target is ONNX.

You can read more about this feature in the [ranking with TensorFlow model in Vespa documentation](http://docs.vespa.ai/en/tensorflow.html). We are excited to announce the TensorFlow support, and we’re eager to hear what you are building with it.


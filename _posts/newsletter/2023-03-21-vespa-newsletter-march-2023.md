---
layout: post
title: Vespa Newsletter, March 2023
author: kkraune
date: '2023-03-21'
categories: [newsletter]
image: assets/images/ilya-pavlov-OqtafYT5kTw-unsplash.jpg
image_credit: 'Photo by <a href="https://unsplash.com/pt-br/@ilyapavlov?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Ilya Pavlov</a> on <a href="https://unsplash.com/photos/OqtafYT5kTw?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>'
skipimage: true
tags: [big data serving, big data, search engines, search, database]
index: false
excerpt: >
    Advances in Vespa features and performance include GPU support, advanced BCP autoscaling,
    GCP Private Service Connect, and a great update to the e-commerce sample app.
---

In the [previous update]({% post_url /newsletter/2023-01-31-vespa-newsletter-january-2023 %}),
we mentioned Better Tensor formats, AWS PrivateLink, Autoscaling, Data Plane Access Control
as well as Container and Content Node Performance.

We also want to thank you for your PRs! In particular (see below),
most of the new pyvespa features were submitted from non-Vespa Team members - thank you!
We are grateful for the contributions, please do keep those PRs coming!

We’re excited to share the following updates:


### GPU-accelerated ML inference
In machine learning, computing model inference is a good candidate for being accelerated by special-purpose hardware, such as GPUs.
Vespa supports [evaluating multiple types of machine-learned models in stateless containers](https://docs.vespa.ai/en/stateless-model-evaluation.html),
e.g., [TensorFlow](https://docs.vespa.ai/en/tensorflow.html),
[ONNX](https://docs.vespa.ai/en/onnx.html),
[XGBoost](https://docs.vespa.ai/en/xgboost.html),
and [LightGBM](https://docs.vespa.ai/en/lightgbm.html) models.
For some use cases, using a GPU makes it possible to perform model inference with higher performance,
and at a lower price point, when compared to using a general-purpose CPU.

The Vespa Team is announcing support for GPU-accelerated ONNX model inference in Vespa,
including support for GPU instances in Vespa Cloud -
[read more](https://blog.vespa.ai/gpu-accelerated-ml-inference-in-vespa-cloud/).


### Vespa Cloud: BCP-aware autoscaling
As part of a business continuity plan (BCP),
applications are often deployed to multiple zones so the system has ready, on-hand capacity
to absorb traffic should a zone fail.
Using autoscaling in Vespa Cloud sets aside resources in each zone to handle an equal share of the traffic from the other zones
in case one of them goes down - e.g., it assumes a *flat BCP structure*.

This is not always how applications wish to structure their BCP traffic shifting though -
so applications can now define their BCP structure explicitly
using the [BCP](https://cloud.vespa.ai/en/reference/deployment#bcp) tag in
[deployment.xml](https://cloud.vespa.ai/en/reference/deployment.html).
Also, during a BCP event, when it is acceptable to have some delay until capacity is ready,
you can set a deadline until another zone must have sufficient capacity to accept the overload;
permitting delays like this allows autoscaling to save resources.


### Vespa for e-commerce
![Screenshot ](/assets/images/e-commerce.png)

Vespa is often used in e-commerce applications.
We have added exciting features to the [shopping](https://github.com/vespa-engine/sample-apps/tree/master/use-case-shopping) sample application:

* Use NLP techniques to generate query suggestions from the index content
  based on spaCy and [en_core_web_sm](https://spacy.io/models/en/).
* Use the [fuzzy query operator](https://docs.vespa.ai/en/reference/query-language-reference.html#fuzzy)
  and [prefix search](https://docs.vespa.ai/en/text-matching-ranking.html#prefix-match) for great query suggestions -
  this handles misspelled words and creates much better suggestions than prefix search alone.
* For query-contextualized navigation,
  the order in which the groups are rendered is determined by both counting and the relevance of the hits.
* Native embedders are used to map the textual query and document representations into dense high-dimensional vectors,
  which are used for semantic search - see [embeddings](https://docs.vespa.ai/en/embedding.html).
  The application uses an open-source embedding model,
  and inference is performed using [stateless model evaluation](https://docs.vespa.ai/en/stateless-model-evaluation.html),
  during document and query processing.
* [Hybrid ranking](https://blog.vespa.ai/improving-zero-shot-ranking-with-vespa/) /
  [Vector search](https://docs.vespa.ai/en/nearest-neighbor-search.html):
  The default retrieval uses approximate nearest neighbor search in combination with traditional lexical matching.
  The keyword and vector matching is constrained by the filters such as brand, price, or category.

Read more about these and other Vespa features used in
[use-case-shopping](https://docs.vespa.ai/en/use-case-shopping.html).


### Optimizations and features
* Vespa supports multiple schemas with multiple fields.
  This can amount to thousands of fields.
  Vespa’s index structures are built for real-time, high-throughput reads and writes.
  With Vespa 8.140, the static memory usage is cut by 75%, depending on field types.
  Find more details in [#26350](https://github.com/vespa-engine/vespa/issues/26350).
* Extracting documents is made easier using *vespa visit* in the [Vespa CLI](https://docs.vespa.ai/en/vespa-cli.html).
  This makes it easier to [clone applications](https://cloud.vespa.ai/en/cloning-applications-and-data)
  with data to/from self-hosted/Vespa Cloud applications.


### pyvespa
Pyvespa – the Vespa Python experimentation library – is now split into two repositories:
[pyvespa](https://pyvespa.readthedocs.io/) and [learntorank](https://vespa-engine.github.io/learntorank/);
this is for better separation of the python API and to facilitate prototyping and experimentation for data scientists.
Pyvespa 0.32 has been released with many new features for fields and ranking;
see the [release notes](https://github.com/vespa-engine/pyvespa/releases/tag/v0.32.0).

This time, most of the new pyvespa features are submitted from non-Vespa Team members!
We are grateful for – and welcome more – contributions. Keep those PRs coming!


### GCP Private Service Connect in Vespa Cloud
In January, we announced AWS Private Link.
We are now happy to announce [support for GCP Private Service Connect](https://cloud.vespa.ai/en/private-endpoints.html#gcp-private-service-connect) in Vespa Cloud.
With this service, you can set up private endpoint services on your application clusters in Google Cloud,
providing clients with safe, non-public access to the application!

In addition, Vespa Cloud supports deployment to both AWS and GCP regions in the *same* application deployment.
This support simplifies migration projects, optimizes costs, adds cloud provider redundancy, and reduces complexity.
We’ve made adopting Vespa Cloud into your processes easy!
* Use the guide to [clone applications](https://cloud.vespa.ai/en/cloning-applications-and-data),
  and you can easily roam the different environments, including self-hosted solutions.
* Use Vespa Cloud’s built-in cloud migration support to take out project risk.
* And use the Vespa toolbox for deployment and migrations to make the process smooth and (almost) without work.
  Check out [vespa-documentation-search](https://github.com/vespa-cloud/vespa-documentation-search/blob/main/src/main/application/deployment.xml) for an example:

        <prod>
            <region>aws-us-east-1c</region>
            <delay minutes="10" />
            <test>aws-us-east-1c</test>
            <region>aws-eu-west-1a</region>
            <region>gcp-us-central1-f</region>
        </prod>


### Blog posts since the last newsletter
* [GPU-accelerated ML inference in Vespa Cloud](https://blog.vespa.ai/gpu-accelerated-ml-inference-in-vespa-cloud/)
* [Improving Search Ranking with Few-Shot Prompting of LLMs](https://blog.vespa.ai/improving-text-ranking-with-few-shot-prompting/)


----

Thanks for reading! Try out Vespa on [Vespa Cloud](https://cloud.vespa.ai/)
or grab the latest release at [vespa.ai/releases](https://vespa.ai/releases) and run it yourself! &#x1F600;

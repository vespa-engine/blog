---
layout: post
title: GPU-accelerated ML inference in Vespa Cloud
date: '2023-03-08'
image: assets/2023-03-08-gpu-accelerated-ml-inference-in-vespa-cloud/sandro-katalina-k1bO_VTiZSs-unsplash.jpg
categories: [product updates]
tags: []
author: mpolden
skipimage: false
excerpt: Today we're introducing support for GPU-accelerated ONNX model inference in Vespa, together with support for GPU instances in Vespa Cloud!
---

<p class="image-credit">
Photo by <a
href="https://unsplash.com/@sandrokatalina?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Sandro
Katalina</a> on <a
href="https://unsplash.com/photos/k1bO_VTiZSs?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
</p>

In machine learning, computing model inference is a good candidate for being
accelerated by special-purpose hardware, such as GPUs. Vespa supports
[evaluating multiple types of machine-learned models in stateless
containers](https://docs.vespa.ai/en/stateless-model-evaluation.html), for
example [TensorFlow](https://docs.vespa.ai/en/tensorflow.html),
[ONNX](https://docs.vespa.ai/en/onnx.html),
[XGBoost](https://docs.vespa.ai/en/xgboost.html) and
[LightGBM](https://docs.vespa.ai/en/lightgbm.html) models. For many use-cases
using a GPU makes it possible to perform model inference with higher
performance, and at a lower price point, compared to using a general purpose
CPU.

Today we're introducing support for GPU-accelerated ONNX model inference in
Vespa, together with support for GPU instances in Vespa Cloud!

## Vespa Cloud

If you're using [Vespa Cloud](https://cloud.vespa.ai/), you can get started with
GPU instances in AWS zones by updating the `<nodes>` configuration in your
`services.xml` file. Our cloud platform will then provision and configure GPU
instances automatically, just like regular instances. See the [services.xml
reference documentation](https://cloud.vespa.ai/en/reference/services#gpu) for
syntax details and examples.

You can then configure which models to evaluate on the GPU in the
`<model-evaluation>` element, in `services.xml`. The GPU device number is
specified as part of the [ONNX inference
options](https://docs.vespa.ai/en/stateless-model-evaluation.html#onnx-inference-options)
for your model.

See [our pricing page](https://cloud.vespa.ai/pricing) for details on GPU
pricing.

## Open source Vespa

GPUs are also supported when using open source Vespa. However, when running
Vespa inside a container, special configuration is required to pass GPU devices
to the container engine (e.g. Podman or Docker).

See the [Vespa documentation](https://docs.vespa.ai/en/vespa-gpu-container.html)
for a tutorial on how to configure GPUs in a Vespa container.

## CORD-19 application benchmark

While implementing support for GPUs in Vespa, we wanted to see if we could find
a real-world use-case demonstrating that a GPU instance can be a better fit than
a CPU instance. We decided to run a benchmark of our [CORD-19
application](https://blog.vespa.ai/vespa-ai-and-the-cord-19-public-api/) - a
Vespa application serving the COVID-19 Open Research Dataset. Its source code is
available on [GitHub](https://github.com/vespa-cloud/cord-19-search).

Our benchmark consisted of a query where the top 30 hits are re-ranked, using a
22M Transformer model using batch inference. The measured latency is end-to-end,
and includes retrieval and inference.

See [our recent blog
post](https://blog.vespa.ai/improving-text-ranking-with-few-shot-prompting/) for
more information about using a Transformer language model to re-rank results.

We compared the following node configurations:

- GPU: 4 vCPUs, 16GB memory, 125 GB disk, 1 GPU with 16GB memory (Vespa Cloud
  cost: 1.87$/hour)
- CPU: 16 vCPUs, 32GB memory, 125 GB disk (Vespa Cloud cost: $2.16/hour)

### Results

<style>
  table, th, td {
    border: 1px solid black;
    margin-bottom: 20px;
  }
  th, td {
    padding: 5px;
  }
</style>

| Instance | Clients | Re-rank (batch) | Avg. latency (ms) | 95 pct. latency | QPS  | GPU util (%) | CPU util (%) |
|----------|---------|-----------------|-------------------|-----------------|------|--------------|--------------|
| GPU      | 1       | 30              | 94                | 102             | 10.2 | 41           | 15           |
| GPU      | 2       | 30              | 160               | 174             | 12.5 | 60           | 19           |
| GPU      | 4       | 30              | 212               | 312             | 18.8 | 99           | 30           |
| CPU      | 1       | 30              | 454               | 473.6           | 2.2  | -            | 27           |
| CPU      | 2       | 30              | 708               | 744             | 2.84 | -            | 33           |
| CPU      | 4       | 30              | 1011              | 1070            | 3.95 | -            | 47           |
| CPU      | 8       | 30              | 1695              | 1975            | 4.73 | -            | 72           |

### Conclusion

The GPU of the GPU instance was saturated at 4 clients, with an average
end-to-end request latency at 212 ms and a throughput of 18.8 QPS. The CPU
instance had a higher average latency, at 1011 ms with 4 clients and a
comparatively low throughput of 3.95 QPS.

So, in this example, the average latency is reduced by 79% when using a GPU,
while costing 13% less.

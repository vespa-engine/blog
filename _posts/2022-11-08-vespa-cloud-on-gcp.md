---
layout: post
title: "Vespa Cloud on Google Cloud Platform"
author: kkraune
date: '2022-11-08'
image: assets/images/nasa-Q1p7bh3SHj8-unsplash.jpg
image_credit: 'Photo by <a href="https://unsplash.com/de/@nasa?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">NASA</a> on <a href="https://unsplash.com/photos/Q1p7bh3SHj8?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>'
tags: [GCP, Google Cloud Platform]
skipimage: false
excerpt: Vespa Cloud is now available on Google Cloud Platform
---

<p class="image-credit">
Photo by <a href="https://unsplash.com/@nasa?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">NASA</a>
on <a href="https://unsplash.com/s/photos/datacenters?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
</p>

[Vespa Cloud](https://cloud.vespa.ai/) has run in AWS zones since its start in 2019.
We are now happy to announce Vespa Cloud availability in Google Cloud Platform (GCP) zones!
To add a gcp zone to your application, simply add `<region>gcp-us-central1-f</region>`
to [deployment.xml](https://cloud.vespa.ai/en/reference/deployment).

GCP availability makes it easier for users with their current workload in GCP to use Vespa Cloud.
Using a GCP zone can reduce data transfer costs, simplify operations, and cut latencies
by locating everything in the same location and cloud provider.

You can always find the currently supported zones in the [zone reference](https://cloud.vespa.ai/en/reference/zones).
[Let us know](https://cloud.vespa.ai/support) if your workload requires additional zones;
expect a two-week ramp-up time.

---
layout: post
title: Private regional endpoints in Vespa Cloud
date: '2023-03-24'
categories: [product updates]
tags: []
image: assets/assets/2021-07-01-http2/simon-connellan-MYSJJWwryPk-unsplash.jpg
author: jvenstad
skipimage: true

excerpt: Set up private endpoint services on your Vespa Cloud application, and access them from your own VPC, in the same region, through the cloud provider's private network. 
---
![Decorative image](/assets/2021-07-01-http2/simon-connellan-MYSJJWwryPk-unsplash.jpg)
<p class="image-credit">
  Photo by <a href="https://unsplash.com/@tvick?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Taylor Vick</a> on <a href="https://unsplash.com/photos/M5tzZtFCOfs?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
</p>

Vespa Cloud exposes application container clusters through public endpoints, by default.
We're happy to announce that we now also support private endpoints, in both AWS and GCP;
that is, our users can connect to their Vespa application, in Vespa Cloud, exclusively
through the private network of the cloud provider. 

## Why use private endpoints

Traffic to private, regional endpoints avoid the trip out onto the public internet,
and both latency and costs are reduced. 
With private endpoints enabled, it is also possible to disable the public endpoints
of the application, for another layer of access control and security.

## How to set up private endpoints in Vespa Cloud

To use this feature, clients must be located within the same region (or availability zone)
as the Vespa clusters they connect to.
Configuring and connecting to the application is done in a few, simple steps:

- Configure and deploy a
  [private endpoint service](https://cloud.vespa.ai/en/reference/deployment.html#endpoint-private),
  optionally
  [disabling the public endpoint](https://cloud.vespa.ai/en/reference/deployment.html#endpoint-zone)
  as well.
- Set up a VPC endpoint in your
  [AWS](https://cloud.vespa.ai/en/private-endpoints.html#aws-private-link) or
  [GCP](https://cloud.vespa.ai/en/private-endpoints.html#gcp-private-service-connect) account,
  in the same region.
- Verify it all works.

Read more about [AWS PrivateLink](https://docs.aws.amazon.com/vpc/latest/privatelink/what-is-privatelink.html)
or [GCP Private Service Connect](https://cloud.google.com/vpc/docs/private-service-connect) for further details. 

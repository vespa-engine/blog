---
layout: post
title: 'Announcing Vespa Cloud Enclave: Bring your own cloud'
date: "2024-01-02"
tags: []
author: oyving
excerpt: Deploy your Vespa Cloud applications inside AWS accounts
  or GCP projects you own, while still managed and operated by
  Vespa.ai.
image: assets/2024-01-02-vespa-cloud-enclave/samsommer-vddccTqwal8-unsplash.jpg
image_credit: 'Photo by <a href="https://unsplash.com/@samsommer?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">samsommer</a> on <a href="https://unsplash.com/photos/landscape-photo-of-mountain-alps-vddccTqwal8?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Unsplash</a>'
---

When you deploy your Vespa application on Vespa Cloud, all cloud resources
needed to run your application will be automatically provisioned with the cloud
provider you chose, and you don’t have to be concerned with the details of
setting up your account with the provider, the lower level network settings,
and so on. For most uses of Vespa, this is absolutely perfect and just how it
is supposed to work.

There are cases, though, where larger applications can have specific
requirements in terms of network connectivity with other in-house services
deployed with the cloud provider or some other policy requirements demanding
all their workloads to run in their own accounts with the cloud provider.

Today, we are pleased to announce a new capability of Vespa Cloud that allows
you to have your Vespa application run inside your own accounts and projects in
AWS and GCP. After granting the initial access to your account, Vespa Cloud
resources are seamlessly provisioned and managed by the same automation that
runs Vespa Cloud, but hosted in an AWS account or GCP project controlled by you.

Enclave is a premium feature, available to customers with a minimum spend -
see the [pricing calculator](https://cloud.vespa.ai/price-calculator) for
details. Vespa Cloud Enclave is great for applications with specific
requirements for control over data and requests, or committed spends with cloud
providers.

With Vespa Cloud Enclave, applications can be hosted within private networks
(VPCs) configured inside your cloud account. You specify inside your
[application package](https://cloud.vespa.ai/en/reference/deployment) in which
account or project your Vespa Cloud deployments should be hosted and whether
you want the same for all deployments, or use different accounts/projects for
different deployments.

<img src="/assets/2024-01-02-vespa-cloud-enclave/figure.png" alt="Architecture illustration">

After working with the Vespa Cloud support team to onboarding you as an Enclave
application, bootstrapping your account is quickly done with our provided
[Terraform modules](https://registry.terraform.io/modules/vespa-cloud/enclave),
making it easy for you to inspect the resources and policies needed to host
Vespa Cloud Enclave. This provides full transparency into the interactions
between Vespa Cloud and your cloud accounts, while little to no work is
required before deploying your first Vespa Cloud Enclave application.

To get started, contact [support](https://cloud.vespa.ai/support) for a
conversation about your Enclave integration needs.

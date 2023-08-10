---
layout: post
title: "Preview of Vespa on ARM64"
date: '2022-02-16'
tags: []
author: aressem
image: assets/2022-02-16-preview-of-vespa-on-arm64/jeremy-bezanger-wl8hZoJBSU8-unsplash.jpg
image_credit: 'Photo by <a href="https://unsplash.com/@jeremybezanger?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Jeremy Bezanger</a> on Unsplash'
skipimage: true

excerpt: "With the increasing adoption of ARM64 based hardware like the AWS Graviton and Apple M1 MacBooks we are making a preview of Vespa available for this architecture."
---

**Update 2022-08-25:**
The preview image will no longer be published for new Vespa versions as all the
[Vespa container images](https://docs.vespa.ai/en/build-install-vespa.html#container-images)
now support both *x86_64* and *ARM64* architectures from version *8.37.26*.

<img src="/assets/2022-02-16-preview-of-vespa-on-arm64/jeremy-bezanger-wl8hZoJBSU8-unsplash.jpg"/>
<p class="image-credit">
Photo by <a href="https://unsplash.com/@unarchive?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText" data-proofer-ignore>Jeremy Bezanger</a>
on <a href="https://unsplash.com/s/photos/cpu?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
</p>

Vespa artifacts like RPMs and container images are currently only released for the *x86_64* CPU architecture. This is what we use internally at Yahoo and our dedication to delivering battle proven versions to the public causes this to be the architecture of choice. With the emerging interest in the *ARM64* CPU architecture that powers both the [AWS Graviton EC2 instances](https://aws.amazon.com/ec2/graviton/) and the [Apple M1 MacBooks](https://www.apple.com/macbook-pro/), we have decided to make a preview for Vespa on this architecture.

## Availability
When a version of Vespa has achieved a high confidence within Yahoo we release this version to the public. High confidence means that it has passed all system tests, performance tests and been running in production for 150 different applications. We publish Java artifacts to Maven Central, RPMs to [Fedora Copr](https://copr.fedorainfracloud.org/coprs/g/vespa/vespa/) and container images to [Docker Hub](https://hub.docker.com/r/vespaengine/vespa/). Vespa is released up to 4 times per week depending on the mentioned confidence measure. The *ARM64* preview will be released at the same cadence.

#### RPMs
The RPMs are available from [Fedora Copr](https://copr.fedorainfracloud.org/coprs/g/vespa/vespa/). This is the same location that the *x86_64* architecture RPMs are available, but there is a difference. We have changed the OS we build for to [CentOS Stream 8](https://www.centos.org/centos-stream/). To install the *ARM64* preview of Vespa on an CentOS Stream 8 OS, execute the following:
```
$ dnf config-manager --add-repo https://copr.fedorainfracloud.org/coprs/g/vespa/vespa/repo/centos-stream-8/group_vespa-vespa-centos-stream-8.repo
$ dnf install vespa
```

#### Container image
We also publish container images of the *ARM64* preview.
As with the RPMs these are also based on [CentOS Stream 8](https://www.centos.org/centos-stream/).
The images are published to the
<a href="https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry" data-proofer-ignore>GitHub Container Registry</a>,
and the latest image can be obtained by pulling `ghcr.io/vespa-engine/vespa-arm64-preview`.

## Vespa Quick Start on *ARM64*
If you would like to test the *ARM64* preview, the easiest way is to use [Docker](https://docker.io) or [Podman](https://podman.io) on a *ARM64* based machine. The [Vespa Quick Start Guide](https://docs.vespa.ai/en/vespa-quick-start.html)
can be followed as described except for the container startup in step 4. There you will have to swap the regular `vespaengine/vespa` image with the *ARM64* preview so this step becomes:
```
$ docker run --detach --name vespa --hostname vespa-container \
  --publish 8080:8080 --publish 19071:19071 \
  ghcr.io/vespa-engine/vespa-arm64-preview
```

## Support
Vespa on *ARM64* is published as a preview for the community to be able to test on this architecture.
Help and support will be provided as a best effort through the [GitHub Issues](https://github.com/vespa-engine/vespa/issues)
and on the [Vespa Slack](http://slack.vespa.ai).
The timeline for a production ready release on the *ARM64* architecture is not set yet.

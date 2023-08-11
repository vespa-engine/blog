---
layout: post
title: "Upcoming changes in OS support for Vespa"
date: '2022-03-29'
tags: []
author: aressem
image: assets/2022-03-29-Upcoming-changes-in-OS-support-for-Vespa/jon-flobrant-rB7-LCa_diU-unsplash.jpg
image_credit: 'Photo by <a href="https://unsplash.com/@jonflobrant?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Jon Flobrant</a> on <a href="https://unsplash.com/photos/rB7-LCa_diU?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>'
excerpt: "Today we support CentOS Linux 7 as the OS for Vespa release artifacts. This is about to change."
skipimage: true
---

<img src="/assets/2022-03-29-Upcoming-changes-in-OS-support-for-Vespa/jon-flobrant-rB7-LCa_diU-unsplash.jpg" />
<p class="image-credit">
Photo by <a href="https://unsplash.com/@jonflobrant">Jon Flobrant</a>
on <a href="https://unsplash.com/photos/rB7-LCa_diU">Unsplash</a>
</p>

Today we support [CentOS Linux](https://www.centos.org) 7 for open source Vespa release artifacts.
These are published as [RPMs on Copr](https://copr.fedorainfracloud.org/coprs/g/vespa/vespa/) and as a
[container image on Docker Hub](https://hub.docker.com/r/vespaengine/vespa). Vespa is released up to
4 times a week depending on internal testing and battle proven verification in our production systems.
In this blog post we will look at options going forward and announce the selected OS support for the
upcoming Vespa 8 release.

# Introduction
We are committed to providing Vespa releases that we have high confidence in. Internally in Yahoo we
migrated to RHEL 8 ([Red Hat Enterprise Linux](https://www.redhat.com/en/technologies/linux-platforms/enterprise-linux))
last year and we want to upgrade the supported OS for open source Vespa as well. Although CentOS 7 is
supported until June 2024, we want to move to an OS that is closer to what we use internally.

This could have been easy, but Red Hat surprised us and deprecated the CentOS Linux 8 in their [December 2020 announcement](https://www.redhat.com/en/blog/centos-stream-building-innovative-future-enterprise-linux).
This resulted in CentOS Linux 8 now being EOL. Since then the community and users of CentOS Linux have
been considering what to do and the void has also resulted in new distributions that are rebuilds of
RHEL just like CentOS Linux 8 was.

# Options
There are a myriad of Linux distributions out there with different purposes and target groups. For us,
we need to choose an OS that is as close to what we use internally as possible. This criteria limits
the options significantly.

![CentOS Stream package flow](/assets/2022-03-29-Upcoming-changes-in-OS-support-for-Vespa/centos-stream-package-flow.png)
<p class="image-credit">Figure 1: Package flow around Red Hat Enterprise Linux</p>

In the figure above we see RHEL in the middle with their nightly build which at some point becomes the
next minor version of RHEL and the released RHEL. Downstream to the right we have distributions that
have emerged after the announcement of the CentOS Linux deprecation. Among these are [Alma Linux](https://almalinux.org/)
and [Rocky Linux](https://rockylinux.org/). Both seem to have gained traction and are now publishing
releases approximately one week after RHEL releases. Since these are rebuilds of the RHEL packages we
should be able to assume the same [ABI compatibility](https://access.redhat.com/articles/rhel8-abi-compatibility).

Furthest upstream we have [Fedora Linux](https://getfedora.org/)
which is the source of all packages in the figure. A given major version of RHEL is branched off a version
of Fedora (Fedora 28 for the RHEL 8 release). The packages then undergo integration testing and QA before
they enter the RHEL nightly build. If the build and test of RHEL nightly is successful the package set is
pushed to [CentOS Stream](https://www.centos.org/centos-stream/). The stability of CentOS Stream could be a
concern compared to the downstream distributions. In the [CentOS Stream is continuous delivery](https://blog.centos.org/2020/12/centos-stream-is-continuous-delivery/)
blog post the author with insight into RHEL pipelines writes that the updates to the CentOS Stream package
set is the RHEL nightly build. Packages that goes into the nightly builds are integration tested and quality
gated. The blog post [CentOS Stream: Why It’s Awesome](https://medium.com/swlh/centos-stream-why-its-awesome-5c45d944fb22) further details
how the packages flow in CentOS Stream and RHEL. Since the RHEL nightly build should be releasable any
day to become the next minor version of RHEL we can assume that the [ABI compatibilities](https://access.redhat.com/articles/rhel8-abi-compatibility)
are valid for CentOS Stream as well. If these break it is a bug and will be fixed. Another advantage for
us would be that we can continue using Fedora Copr to build our packages.

Red Hat has also announced [a free version of RHEL](https://www.redhat.com/en/blog/new-year-new-red-hat-enterprise-linux-programs-easier-ways-access-rhel)
for developers and small workloads. However, it is not hassle free as it requires registration at Red Hat
to be able to use the version. We believe that this will not be well received by the consumers of Vespa
releases.

# Selection
Considering the options, we have chosen CentOS Stream 8 as the supported OS for the next major version of
Vespa, which is due this year. The main reasons for this decision are:
* The OS is available to anyone free of charge
* We will still be able to leverage the Copr build system for open source Vespa artifacts
* Updates and security fixes will be available earlier than for distributions downstream RHEL
* CentOS Stream is close enough to what we use in production to be able to deliver open source Vespa releases with high confidence

This means that we will still build and distribute Vespa [RPMs on Copr](https://copr.fedorainfracloud.org/coprs/g/vespa/vespa/) and we will use the `quay.io/centos/centos:stream8` as the base for the [container image on Docker Hub](https://hub.docker.com/r/vespaengine/vespa).

The consumers of Vespa artifacts can be impacted by this change depending on their environments. For those
that use our RPMs to install directly on VMs or bare metal hosts, the OS will have to be upgraded to CentOS
Stream 8 to be compatible. The OS must also be kept up to date as the Vespa releases will be based on the
state of CentOS Stream 8 at build time. Consumers of the container images will need to upgrade the hosts to
an OS close enough or newer than the CentOS Stream kernel which is currently `4.18.0`.

# Summary
We have selected CentOS Stream 8 and this will be the only supported OS for Vespa 8 artifacts. This decision
will impact those that consume Vespa artifacts like RPMs or container images to various degrees.

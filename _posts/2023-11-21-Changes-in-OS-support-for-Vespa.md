---
layout: post
title: "Changes in OS support for Vespa"
date: '2023-11-21'
tags: []
author: aressem
image: assets/2023-11-21-Changes-in-OS-support-for-Vespa/claudio-schwarz-z508Zk08HNU-unsplash.jpg
image_credit: 'Photo by <a href="https://unsplash.com/@purzlbaum?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Claudio Schwarz</a> on <a href="https://unsplash.com/photos/white-metal-frame-z508Zk08HNU?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Unsplash</a>'
excerpt: "Today the supported OS for Vespa 8 is CentOS Stream 8. This is about to change."
skipimage: true
---

<img src="/assets/2023-11-21-Changes-in-OS-support-for-Vespa/claudio-schwarz-z508Zk08HNU-unsplash.jpg" />
<p class="image-credit">
Photo by <a href="https://unsplash.com/@purzlbaum?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Claudio Schwarz</a>
on <a href="https://unsplash.com/photos/white-metal-frame-z508Zk08HNU?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Unsplash</a>
</p>

Currently, we support [CentOS Stream 8](https://www.centos.org/centos-stream/) for open-source Vespa, and we announced that
in the [Upcoming changes in OS support for Vespa](https://blog.vespa.ai/Upcoming-changes-in-OS-support-for-Vespa) blog 
post in 2022. The choice to use CentOS Stream was made around the time that [RedHat announced the EOL for CentOS 8 and the 
new CentOS  Stream initiative](https://www.redhat.com/en/blog/centos-stream-building-innovative-future-enterprise-linux). 
Other groups were scrambling to be the successor to CentOS, and the landscape was not settled. This is now about to change.

# Introduction
We are committed to providing Vespa releases that we have high confidence in. Internally, at [Vespa.ai](https://vespa.ai),
we have migrated to [AlmaLinux 8](https://almalinux.org/) and 
[Red Hat Enterprise Linux 8](https://www.redhat.com/en/technologies/linux-platforms/enterprise-linux). CentOS Stream 8 is
also approaching its EOL, which is May 31st, 2024. Because of this, we want to change the supported OS for open-source Vespa.

Vespa is released up to 4 times a week depending on internal testing and battle-proven verification in our production 
systems. Each high-confidence version is published as [RPMs](https://rpm.org/) and a [container image](https://opencontainers.org/).
RPMs are built and published on [Copr](https://copr.fedorainfracloud.org/coprs/g/vespa/vespa/), and container images are 
published on [Docker Hub](https://hub.docker.com/r/vespaengine/vespa). In this blog post, we will look at options going 
forward and announce the selected OS support for the upcoming Vespa releases.

# Options

There is a wide selection of Linux distributions out there with different purposes and target groups. For us, we need to choose 
an OS that is as close to what we use internally as possible, and that is acceptable for our open-source users. These 
criteria limit the options significantly to an enterprise Linux-based distribution.

## RPMs
Binary releases of Vespa is a set of RPMs. This set has to be built somewhere and must be uploaded to a 
repository where it can be downloaded by package managers. These RPMs are then installed either on a host machine or in 
container images. We will still build our RPMs on [Copr](https://copr.fedorainfracloud.org/coprs/g/vespa/vespa/), but we 
have a choice there to compile for different environments that are either downstream or upstream of RHEL. In the time 
between the EOL of CentOS 8 (end 2021) and now, Copr has added support to build for 
[EPEL](https://docs.fedoraproject.org/en-US/epel/) 8 and 9. This means that we can build for EPEL 8 and install it on 
RHEL 8 and its downstream clones. 

Distribution of RPMs is currently done on Copr as the built RPMs are directly put in the repository there. The repositories
have limited capacity, and Copr only guarantees that the latest version is available. It would be nice to have an archive 
of more than just the most recent version, but this will rely on vendors offering space and network traffic for the RPMs
to be hosted.

## Container images

Given the choice of building RPMs on Copr for EPEL 8, this opens up a few options when selecting a base image for our 
container image:
* [AlmaLinux](https://almalinux.org/)
* [Rocky Linux](https://rockylinux.org/)
* [Oracle Linux](https://www.oracle.com/ie/linux/)

We should be able to select any of the above due to the [RHEL ABI compatibility](https://access.redhat.com/articles/rhel8-abi-compatibility)
and the distributions' respective guarantees to be binary compatible with RHEL. 

Red Hat has also announced [a free version of RHEL](https://www.redhat.com/en/blog/new-year-new-red-hat-enterprise-linux-programs-easier-ways-access-rhel)
for developers and small workloads. However, it is not hassle-free, as it requires registration at Red Hat
to be able to use the version. We believe that this will not be well received by the consumers of Vespa
releases.


# Selection
## Container Image

Considering the options, we have chosen <strong>AlmaLinux 8</strong> as the supported OS going forward. The main reasons for this decision 
are:
* AlmaLinux is used in the [Vespa Cloud](https://cloud.vespa.ai/) production systems
* The OS is available to anyone free of charge
* We will still be able to leverage the Copr build system for open-source Vespa artifacts

We will use the `docker.io/almalinux:8` image as the base for the [Vespa container image on Docker Hub](https://hub.docker.com/r/vespaengine/vespa).

## RPM distribution
Although we will continue to build RPMs on Copr, we are going to switch to a new RPM repository that can keep an archive
of a limited set of historic releases. We have been accepted as an open-source project at 
[Cloudsmith](https://cloudsmith.com) and will use the
[vespa/open-source-rpms](https://cloudsmith.io/~vespa/repos/open-source-rpms/packages/) repository to distribute our RPMs. 
Cloudsmith generously allows qualified open-source projects to store 50 GB and have 200 GB of network traffic. The 
[vespa-engine.repo](https://raw.githubusercontent.com/vespa-engine/vespa/master/dist/vespa-engine.repo) repository definition
will be updated shortly, and information about how to install Vespa from RPMs can be found in the 
[documentation](https://docs.vespa.ai/en/build-install-vespa.html#rpms). Within our storage limits, we will be able to store 
approximately 50 Vespa releases.

# Compatibility for current Vespa installations
The consumers of Vespa container images should not notice any differences when Vespa changes the base of the container
image to AlmaLinux 8. Everything comes preinstalled in the image, and this is tested the same way as it was before. If 
you use the Vespa container image as a base of custom images, the differences between the latest AlmaLinux 8 and CentOS
Stream 8 are minimal. We do not expect any changes to be required.

For consumers that install Vespa RPMs in their container images or install directly on host instances, we will continue
to build and publish RPMs for CentOS Stream 8 on Copr until Dec 31st, 2023. RPMs built on EPEL 8 will be forward compatible
with CentOS Stream 8 due to the [RHEL ABI compatibility](https://access.redhat.com/articles/rhel8-abi-compatibility). This 
means that you can make the switch by replacing the repository configuration with the one defined in 
[vespa-engine.repo](https://raw.githubusercontent.com/vespa-engine/vespa/master/dist/vespa-engine.repo) the next time Vespa
is upgraded. If you do not, no new Vespa versions will be available for upgrade once we stop building for CentOS Stream 8.

# Future OS support
Predicting the path of future OS support is not trivial in an environment where the landscape is changing. RedHat 
[announced](https://www.redhat.com/en/blog/furthering-evolution-centos-stream) closing off the RHEL sources and strengthening 
CentOS Stream. [Open Enterprise Linux Association](https://openela.org/) has popped up as a response to this, and [AlmaLinux
commits to binary compatibility](https://almalinux.org/blog/future-of-almalinux/). We expect the landscape to change, and 
hopefully, we will have more clarity when deciding on the next OS to support.

Regardless of the landscape, we are periodically publishing a preview on AlmaLinux 9 that can be used at your own risk
[here](https://hub.docker.com/r/vespaengine/vespa-el9-preview). Please use this for testing purposes only.

# Summary
We have selected AlmaLinux 8 as the supported OS for Vespa going forward. The change is expected to have no impact on the 
consumers of Vespa container images and RPMs. The primary RPM repository has moved to a [Cloudsmith](https://cloudsmith.com)-hosted
repository where we can have an archive of releases allowing installation of not just the latest Vespa version.





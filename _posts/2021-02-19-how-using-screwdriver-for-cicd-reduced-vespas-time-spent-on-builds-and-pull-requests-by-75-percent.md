---
layout: post
title: "How Using Screwdriver for CI/CD Reduced Vespa’s Time Spent on Builds and Pull Requests by 75%"
date: '2021-02-22'
tags: []
author: aressem
image: assets/2021-02-19-how-using-screwdriver-for-cicd-reduced-vespas-time-spent-on-builds-and-pull-requests-by-75-percent/cover.jpg
excerpt: Introducing Screwdriver for Vespa's CI/CD needs.
skipimage: true

---
*By [Arnstein Ressem](https://www.linkedin.com/in/arnsteinressem/), Principal Software Systems Engineer, Yahoo*

When Vespa was [open sourced in 2017](https://blog.vespa.ai/open-sourcing-vespa-yahoos-big-data-processing/) we looked for a continuous integration platform to build our source code on. We looked at several hosted solutions as well as [Screwdriver](https://screwdriver.cd/) – an open source CI/CD platform built by Yahoo – that had just been open sourced in 2016. Another platform seemed the best fit for us at that point in time and we integrated with that.

![Decorative image](/assets/2021-02-19-how-using-screwdriver-for-cicd-reduced-vespas-time-spent-on-builds-and-pull-requests-by-75-percent/cover.jpg)
<p class="image-credit"><em>Photo by <a href="https://unsplash.com/@bill_oxford?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Bill Oxford</a> on <a href="https://unsplash.com/s/photos/cogs?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a></em></p>

The [Vespa codebase](https://github.com/vespa-engine/vespa) is large with approximately 700 KLOC C++, 700 KLOC Java and more than 10k unit tests. For a given version of Vespa we build the complete codebase and version the artifacts with [semantic versioning](https://semver.org/). We always build from the master branch and have no feature branches. 

Compiling and testing this codebase is resource demanding and we soon realized that the default VMs that the provider had were not up to the task and took more than 2 hours to complete. This was a serious issue for the developers waiting for feedback on their pull requests. We ended up subscribing to a premium plan and did more caching of Maven artifacts and compiled C++ objects ([ccache](https://ccache.dev/)) to bring the build time just under one hour.

In the fall of 2020 we became aware of big changes in the selected CI/CD platform and we needed to migrate to something else. As part of this work we took another look at the open sourced version of [Screwdriver](https://screwdriver.cd/) as we knew that the project had significantly matured over the past years. [Screwdriver](https://screwdriver.cd/) is an open source build platform designed for Continuous Delivery that can easily be deployed on different IaaS providers and is currently an incubee in the [Continuous Delivery Foundation](https://cd.foundation/).

![Screwdriver](/assets/2021-02-19-how-using-screwdriver-for-cicd-reduced-vespas-time-spent-on-builds-and-pull-requests-by-75-percent/screwdriver.png)
<p class="image-credit"><em>Vespa pipeline on Screwdriver</em></p>

The Vespa team got access to a hosted instance at [cd.screwdriver.cd](https://cd.screwdriver.cd) (*invite only, but publicly readable with guest access*). Working closely with [Screwdriver](https://screwdriver.cd/) we were able to reduce the build times for the master branch and pull requests from 50 minutes on the previous solution to 18 minutes. This result was obtained by using [Screwdriver](https://screwdriver.cd/)’s configurable resource management and fast build caches. We also appreciated the small set of requirements on container images allowing us to optimize the build image for our jobs.

![Github](/assets/2021-02-19-how-using-screwdriver-for-cicd-reduced-vespas-time-spent-on-builds-and-pull-requests-by-75-percent/github.png)
<p class="image-credit"><em>Screwdriver integrated with pull request builds on GitHub</em></p>

To further increase the developer feedback and productivity we decided to do some pull request analysis to check if only C++ or Java source code was touched. In those cases we could only build and test for the respective language. This brought the pull request build times from 18 down to 12 minutes for C++ and 8 minutes for Java. This allowed developers to have more issues discovered in pull requests without having to wait for a long time for the review and merge.

We are very happy with having the **time spent on builds and pull requests reduced by 75% on average** and this leads to better productivity and happier developers.

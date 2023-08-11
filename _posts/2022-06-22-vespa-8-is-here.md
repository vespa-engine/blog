---
layout: post
title: "Vespa 8 is here"
date: '2022-06-22'
tags: []
author: bratseth
image: assets/2022-06-22-vespa-8-is-here/claudio-schwarz-8-unsplash.jpg
image_credit: 'Photo by <a href="https://unsplash.com/@purzlbaum?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Claudio Schwarz</a> on <a href="https://unsplash.com/photos/sD0y9djR-Jk?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>'
skipimage: true
excerpt: "Announcing the release of Vespa 8 - the next major version of vespa.ai"
---
When you’re reading this Vespa 8 - the next major version of [Vespa.ai](https://vespa.ai/) - is available for 
production use both as open source and on [Vespa Cloud](https://cloud.vespa.ai/). A big deal! Or is it?

Back before continuous deployment and [semantic versioning](https://semver.org/), major releases used to mark 
the release of big new features, and people might spend years adapting to all kinds of incompatible changes, 
almost like moving to an entirely new product. 
A major drain on efficiency on both users and developers of the released software.

The times have changed, however. Vespa 8 does not contain a single new feature! 
We’ll keep adding new features and have them used in production rapidly *on* the major version, 
and instead use the major version *change* to mark a point where

- old deprecated functionality is removed,
- we allow ourselves to change the default values of settings, and
- we switch to newer versions of our own dependencies such as JDK and Linux.

And since the delta between Vespa 7 and 8 is so small, we expect everybody to switch to it rapidly - 
3 months max, and we’ll not release any further Vespa 7 minor versions (barring critical security issues).

## What should you do now?

Make sure your application deploys on Vespa 7 without any warnings about using deprecated features. 
If you have Java code, make sure it compiles without deprecation warnings.
Go through the list of changes in the [Vespa 8 release notes](https://docs.vespa.ai/en/vespa8-release-notes.html), 
and [Vespa Cloud 8 release notes](https://cloud.vespa.ai/en/vespa8-release-notes.html) if relevant, 
and for each decide if it affects you and how to handle it. This should all take less than an hour.

When you have done this you are ready to build and deploy your application for Vespa 8. 
If you are on Vespa Cloud set <code>major-version='8'</code> in the deployment.xml file, rebuild and deploy. 
If you are running Vespa yourself, follow the 
[normal upgrade procedure](https://docs.vespa.ai/en/operations/live-upgrade.html), 
but in addition switch to CentOS Stream 8 on each node as you upgrade.

That's it! Once on Vespa 8 you'll be back to receiving a steady stream of new features and improvements
which you'll be able to make use of right away, as we maintain compatibility between each minor release.

---
layout: post
title: Vespa 7 is released!
date: '2019-02-01T14:57:30-08:00'
tags:
- vespa vespa7
tumblr_url: https://blog.vespa.ai/post/182474101666/vespa-7-is-released
---
This week we rolled the major version of Vespa over from 6 to 7.

The releases we make public already run a large number of high traffic production applications on our Vespa cloud, and the 7 versions are no exception.

There are no new features on version 7 since we release all new features incrementally on minors. Instead, the major version change is used to mark the point where we remove legacy features marked as deprecated and change some default settings. We only do this on major version changes, as [Vespa uses semantic versioning](https://docs.vespa.ai/en/vespa-versions.html).

Before upgrading, go through the list of changes in the [release notes](https://docs.vespa.ai/en/vespa7-release-notes.html) to make sure your application and usage is ready. Upgrading can be done by following the regular [live upgrade procedure](https://docs.vespa.ai/en/operations/live-upgrade.html).


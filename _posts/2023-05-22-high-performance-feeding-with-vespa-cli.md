---
layout: post
title: High performance feeding with Vespa CLI
date: '2023-05-22'
image: assets/2023-05-22-high-performance-feeding-with-vespa-cli/shiro-hatori-WR-ifjFy4CI-unsplash.jpg
categories: [product updates]
tags: []
author: mpolden
skipimage: false
excerpt: Vespa CLI can now feed large sets of documents to Vespa efficiently.
---

<p class="image-credit">Photo by <a
href="https://unsplash.com/@shiroscope?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Shiro
hatori</a> on <a
href="https://unsplash.com/photos/WR-ifjFy4CI?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a></p>

For a long time
[vespa-feed-client](https://docs.vespa.ai/en/vespa-feed-client.html) has been
the best option for feeding large sets of documents to Vespa efficiently. While
the client itself performs well, it depends on a Java runtime and its
installation method is rather cumbersome. Compared to Vespa CLI it also lacks
many ease-of-use features such as automatic configuration of authentication and
endpoint discovery.

Since our [initial announcement of Vespa
CLI](https://blog.vespa.ai/introducing-vespa-cli/) it has become the standard
interface for working with Vespa applications, both for self-hosted
installations and [Vespa Cloud](https://cloud.vespa.ai/). However, document
feeding with Vespa CLI was initially limited to single-document operations,
using the `vespa document` command.

Having to juggle multiple tools while working with Vespa is obviously not ideal.
We therefore decided to implement a high performance feeding client inside Vespa
CLI, thus making it a universal client for Vespa.

Today we're excited to announce this new feed client! See it in action in the
screencast below:

<script async id="asciicast-aP3NaRkVTTmLA6TyrgTaqHO1a"
src="https://asciinema.org/a/aP3NaRkVTTmLA6TyrgTaqHO1a.js" data-autoplay="false" data-theme="solarized-dark" data-rows="23" data-loop="false" data-speed="2"></script>

## Performance

The new feed client is ready for most use-cases. If you're already using
`vespa-feed-client` and want to switch to `vespa feed`, we recommend comparing
the feed performance of your particular document set before making the switch.
`vespa feed` outputs statistics on the same format as `vespa-feed-client`,
making comparison easy.

We've invested a lot of time into making `vespa feed` as performant as the old
client. In our performance tests, its current default configuration outperforms
the old client when feeding small- (10B) and medium-sized (1KB) documents, but
it still lags behind `vespa-feed-client` when feeding large (10KB+) documents.

Below you can see a throughput comparison (queries per second) of the two
clients when feeding two million documents at sizes 10B, 1KB and 10KB:

<img src="/assets/2023-05-22-high-performance-feeding-with-vespa-cli/perf.png"/>

We'll continue making performance improvements to the new client, so make sure
to keep your Vespa CLI installation up-to-date.

## Future of the Java client

The introduction of `vespa feed` does not deprecate `vespa-feed-client`. If
you're already using `vespa-feed-client` there is no immediate need to migrate
to the new client. `vespa-feed-client` provides both a Java library and a
command-line interface for that library, both of which will remain supported.

However, if you'd rather use Vespa CLI for all things Vespa and don't depend on
`vespa-feed-client` as a Java library, we encourage you to try our new client.

## Getting started

The new feed client is available in Vespa CLI as of version 8.164. See `vespa
help feed` for usage and the [Vespa
documentation](https://docs.vespa.ai/en/vespa-cli-feed.html) for further
details.

If you're using Homebrew you can upgrade to the latest version using `brew
upgrade vespa-cli` or you can download the latest release from our [GitHub
releases page](https://github.com/vespa-engine/vespa/releases).

New to Vespa CLI? Please see our quick start guides for [self-hosted
Vespa](https://docs.vespa.ai/en/vespa-cli.html) or [Vespa
Cloud](https://cloud.vespa.ai/en/getting-started).

Found a bug or have a feature request? Feel free to file a [GitHub
issue](https://github.com/vespa-engine/vespa/issues). Need help with Vespa CLI
or Vespa in general? Drop by our community [Slack
channel](https://slack.vespa.ai/).

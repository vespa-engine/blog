---
layout: post
title: Introducing Vespa CLI
date: '2021-09-23'
categories: [product updates]
tags: []
author: mpolden
image: assets/2021-09-23-introducing-vespa-cli/screenshot.png
skipimage: true

excerpt: The official command-line tool for Vespa is now available.
---
<script id="asciicast-UyZQXh1TxLo43ON0CMqgFxEj0" src="https://asciinema.org/a/UyZQXh1TxLo43ON0CMqgFxEj0.js" async data-autoplay="true" data-speed="1.5" data-cols="170" data-loop="true"></script>

Historically, the primary methods for deploying and interacting with [Vespa
applications](https://docs.vespa.ai/en/application-packages.html)
has been to use [Vespa APIs](https://docs.vespa.ai/en/api.html) directly or via
our Maven plugin.

While these methods are effective, neither of them are seamless. Using the APIs
typically involves copying dense terminal commands from the Vespa documentation,
and assumes that the user has access to a variety of terminal tools. The Maven
plugin assumes the user has a Java development toolchain installed and
configured, which is unnecessary for some use-cases.

We therefore decided to build an official command-line tool that supports both
self-hosted Vespa installations and Vespa Cloud, focusing on ease of use.

## Vespa CLI

Vespa CLI is a zero-dependency tool built with Go, available for Linux, macOS
and Windows.

Using the initial release of Vespa CLI you can:

- Clone our [sample applications](https://github.com/vespa-engine/sample-apps/)
- Deploy your application to a Vespa installation running locally or remote
- Deploy your application to a dev zone in [Vespa Cloud](https://cloud.vespa.ai)
- Feed and query documents
- Send custom requests with automatic authentication

To install Vespa CLI, choose one of the following methods:

- Homebrew: `brew install vespa-cli`
- [Download from GitHub](https://github.com/vespa-engine/vespa/releases/latest)

To learn how to use Vespa CLI check out our getting started guides:
- [Open source Vespa](https://docs.vespa.ai/en/vespa-quick-start.html)
- [Vespa Cloud](https://cloud.vespa.ai/en/getting-started)

Vespa CLI is open source under the same license as Vespa itself and [its source
code is part of the Vespa
repository](https://github.com/vespa-engine/vespa/tree/master/client/go). If you
encounter problems or want to provide feedback on Vespa CLI, feel free to [file
a GitHub issue](https://github.com/vespa-engine/vespa/issues/new/choose).

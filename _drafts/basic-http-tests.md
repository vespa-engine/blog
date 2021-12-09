---
layout: post
title: Basic HTTP tests
date: '2021-12-08'
categories: [product updates]
tags: []
image: assets/2021-21-10-vespa-basic-http-tests/screenshot.png
author: jvenstad hakonhall
skipimage: true

excerpt: The Vespa CLI now makes it easy to write and run tests for your Vespa application, which can also be used to set up a CD pipeline for the Vespa cloud.
---
<script id="asciicast-UyZQXh1TxLo43ON0CMqgFxEj0" src="https://asciinema.org/a/UyZQXh1TxLo43ON0CMqgFxEj0.js" async data-autoplay="true" data-speed="1.5" data-cols="170" data-loop="true"></script>

HTTP interfaces are the bread and butter for interacting with a Vespa application.
A typical test of a Vespa application consists of a sequence of
HTTP requests, and corresponding assertions on the HTTP responses.

The latest addition to the <a href="https://docs.vespa.ai/en/vespa-cli.html">Vespa CLI</a> is the `test` command, which makes it easy to
develop and run basic HTTP tests, expressed in JSON format.
Like the `document` and `query` commands, endpoint discovery and authentication are
handled by the CLI, leaving developers free to focus on the tests themselves.

Basic HTTP tests are also supported by the CD framework of the Vespa cloud,
allowing applications to be safely, and easily, deployed to production. 

## Developing tests

To get started with Vespa's basic HTTP tests:

- Install <a href="https://docs.vespa.ai/en/vespa-cli.html">Vespa CLI</a>
- Clone the album-recommendation sample app<br/>`vespa clone vespa-cloud/album-recommendation myapp`
- Configure and deploy the application, locally or to the cloud<br/>
  `vespa deploy --wait 600`
- Run the system tests, staging setup tests, or staging tests<br/>
  `vespa test src/test/application/system-test`

To get more information, see the reference documentation <a
href="https://cloud.vespa.ai/en/reference/testing.html">Basic HTTP Testing</a>.

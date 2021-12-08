---
layout: post
title: Basic HTTP system tests for Vespa
date: '2021-12-10'
categories: [product updates]
tags: []
author: jvenstad, hakon
image: assets/2021-21-10-vespa-basic-http-tests/screenshot.png
skipimage: true

excerpt: The Vespa CLI now makes it easy to develop and run system tests for your Vespa application, which can also be used to set up a CD pipeline for the Vespa cloud.
---
<script id="asciicast-UyZQXh1TxLo43ON0CMqgFxEj0" src="https://asciinema.org/a/UyZQXh1TxLo43ON0CMqgFxEj0.js" async data-autoplay="true" data-speed="1.5" data-cols="170" data-loop="true"></script>

HTTP interfaces are the bread and butter for interacting with a Vespa application.
A system test of a Vespa application typically consists of a predefined sequence of
HTTP requests, and corresponding assertions on the HTTP responses.

The latest addition to the Vespa CLI is the `test` command, which makes it easy to
develop and run basic HTTP system tests, expressed in JSON format. 
Like the `document` and `query` commands, endpoint discovery and authentication is
handled by the CLI, leaving developers free to focus on the tests themselves.

The basic HTTP tests are also supported by the CD framework of the Vespa cloud,
allowing applications to be safely, and easily, deployed to production. 

## Developing tests

To get started with Vespa's basic HTTP tests:

- Check out the album-recommendation Vespa cloud sample app
- Configure and deploy the application, locally or to the cloud
- Run the sample tests included under src/test/application

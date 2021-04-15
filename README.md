# blog
[![Vespa Blog Search Feed](https://github.com/vespa-engine/blog/actions/workflows/feed.yml/badge.svg)](https://github.com/vespa-engine/blog/actions/workflows/feed.yml),

The Vespa blog - https://blog.vespa.ai

https://jekyllrb.com/docs/posts/ is useful to understand how to write a post - highlights:

1. Serve on localhost using ```bundle exec jekyll serve --incremental --drafts --trace```

1. Create a file like _drafts/draft-template.md and view it as http://localhost:4000/draft-template/ (the index page is also regenerated, some times ...).

1. After reviewed and good to publish, move file to _posts, possibly in a subdirectory - and it is live

1. We don't have a good system for categories and tags yet, experimental stage




misc:
```
---
layout: post
title: A Trip
categories: [blog, travel]
tags: [hot, summer]
---
```

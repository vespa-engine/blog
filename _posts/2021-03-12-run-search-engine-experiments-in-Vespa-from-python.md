---
layout: post
title: "Run search engine experiments in Vespa from python"
date: '2021-03-12'
tags: []
author: thigm85
image: assets/2021-03-12-run-search-engine-experiments-in-Vespa-from-python/figure_2.jpg
image_credit: 'Photo by <a href="https://unsplash.com/@kristinhillery?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Kristin Hillery</a> on <a href="https://unsplash.com/photos/YId0l2vqc6E?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>'
skipimage: true
excerpt: Three ways to get started with pyvespa.
---

**Three ways to get started with pyvespa.**

[pyvespa](https://pyvespa.readthedocs.io/en/latest/index.html) provides a python API to Vespa.
The library’s primary goal is to allow for faster prototyping and facilitate Machine Learning experiments for Vespa applications.

**UPDATE 2023-02-13:** Code examples are updated to work with the latest releases of
[pyvespa](https://pyvespa.readthedocs.io/en/latest/index.html).

There are three ways you can get value out of `pyvespa`: 

1. You can connect to a running Vespa application.

2. You can build and deploy a Vespa application using pyvespa API.

3. You can deploy an application from Vespa config files stored on disk.

We will review each of those methods.

![Decorative image](/assets/2021-03-12-run-search-engine-experiments-in-Vespa-from-python/figure_2.jpg)
<p class="image-credit">Photo by
<a href="https://unsplash.com/@kristinhillery?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Kristin Hillery</a> on
<a href="https://unsplash.com/@kristinhillery?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a></p>

##  Connect to a running Vespa application

In case you already have a Vespa application running somewhere, you can directly instantiate the [Vespa](https://pyvespa.readthedocs.io/en/latest/reference-api.html#vespa.application.Vespa) class with the appropriate endpoint. The example below connects to the [cord19.vespa.ai](https://cord19.vespa.ai/) application:


```python
from vespa.application import Vespa

app = Vespa(url = "https://api.cord19.vespa.ai")
```

We are then good to go and ready to interact with the application through `pyvespa`:


```python
app.query(body = {
  'yql': 'select title from sources * where userQuery()',
  'hits': 1,
  'summary': 'short',
  'timeout': '1.0s',
  'query': 'coronavirus temperature sensitivity',
  'type': 'all',
  'ranking': 'default'
}).hits
```

    [{'id': 'index:content/1/ad8f0a6204288c0d497399a2',
      'relevance': 0.36920467353113595,
      'source': 'content',
      'fields': {'title': '<hi>Temperature</hi> <hi>Sensitivity</hi>: A Potential Method for the Generation of Vaccines against the Avian <hi>Coronavirus</hi> Infectious Bronchitis Virus'}}]



## Build and deploy with pyvespa API

You can also build your Vespa application from scratch using the pyvespa API. Here is a simple example:


```python
from vespa.package import ApplicationPackage, Field, RankProfile

app_package = ApplicationPackage(name = "sampleapp")
app_package.schema.add_fields(
    Field(
        name="title", 
        type="string", 
        indexing=["index", "summary"], 
        index="enable-bm25")
)
app_package.schema.add_rank_profile(
    RankProfile(
        name="bm25", 
        inherits="default", 
        first_phase="bm25(title)"
    )
)
```

We can then deploy `app_package` to a Docker container
(or directly to [VespaCloud](https://pyvespa.readthedocs.io/en/latest/getting-started-pyvespa-cloud.html)):


```python
from vespa.deployment import VespaDocker

vespa_docker = VespaDocker()
app = vespa_docker.deploy(application_package=app_package)
```

    Waiting for configuration server, 0/300 seconds...
    Waiting for configuration server, 5/300 seconds...
    Waiting for application status, 0/300 seconds...
    Waiting for application status, 5/300 seconds...
    Waiting for application status, 10/300 seconds...
    Waiting for application status, 15/300 seconds...
    Waiting for application status, 20/300 seconds...
    Waiting for application status, 25/300 seconds...
    Finished deployment.

`app` holds an instance of the Vespa class just like our first example,
and we can use it to feed and query the application just deployed.
This can be useful when we want to fine-tune our application based on Vespa features not available through the `pyvespa` API.

There is also the possibility to explicitly export `app_package` to Vespa configuration files (without deploying them):

```
$ mkdir -p /tmp/sampleapp
```
```python
app_package.to_files("/tmp/sampleapp")
```

Clean up:
```python
vespa_docker.container.stop()
vespa_docker.container.remove()
```



## Deploy from Vespa config files

`pyvespa` API provides a subset of the functionality available in `Vespa`. The reason is that `pyvespa` is meant to be used as an experimentation tool for Information Retrieval (IR) and not for building production-ready applications. So, the python API expands based on the needs we have to replicate common use cases that often require IR  experimentation.

If your application requires functionality or fine-tuning not available in `pyvespa`, you simply build it directly through Vespa configuration files as shown in [many examples](https://docs.vespa.ai/en/getting-started.html) on Vespa docs. But even in this case, you can still get value out of `pyvespa` by deploying it from python based on the Vespa configuration files stored on disk. To show that, we can clone and deploy the news search app covered in this [Vespa tutorial](https://docs.vespa.ai/en/tutorials/news-3-searching.html):


```
$ git clone https://github.com/vespa-engine/sample-apps.git
```

The Vespa configuration files of the news search app are stored in the `sample-apps/news/app-3-searching/` folder:


```
$ tree sample-apps/news/app-3-searching/
```

    sample-apps/news/app-3-searching/
    ├── schemas/
    │   └── news.sd
    └── services.xml
    
    1 directory, 2 files


We can then deploy to a Docker container from disk:


```python
from vespa.deployment import VespaDocker

vespa_docker_news = VespaDocker()
app = vespa_docker_news.deploy_from_disk(
    application_name="news",
    application_root="sample-apps/news/app-3-searching")
```

    Waiting for configuration server, 0/300 seconds...
    Waiting for configuration server, 5/300 seconds...
    Waiting for application status, 0/300 seconds...
    Waiting for application status, 5/300 seconds...
    Waiting for application status, 10/300 seconds...
    Waiting for application status, 15/300 seconds...
    Waiting for application status, 20/300 seconds...
    Waiting for application status, 25/300 seconds...
    Finished deployment.

Again, `app` holds an instance of the Vespa class just like our first example,
and we can use it to feed and query the application just deployed.

Clean up:
```python
vespa_docker_news.container.stop()
vespa_docker_news.container.remove()
```


## Final thoughts

We covered three different ways to connect to a `Vespa` application from python using the `pyvespa` library. Those methods provide great workflow flexibility. They allow you to quickly get started with pyvespa experimentation while enabling you to modify Vespa config files to include features not available in the pyvespa API without losing the ability to experiment with the added features.

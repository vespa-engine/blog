---
layout: post
title: "Build a News recommendation app from python with Vespa: Part 1"
date: '2021-03-22'
tags: []
author: thigm85
image: assets/2021-03-22-build-news-search-app-from-python-with-vespa/figure_1.jpg
skipimage: true
excerpt: Part 1 - News search functionality.
---

**Part 1 - News search functionality.**

We will build a news recommendation app in Vespa without leaving a python environment. In this first part of the series, we want to develop an application with basic search functionality. Future posts will add recommendation capabilities based on embeddings and other ML models. 

**UPDATE 2023-02-13:** Code examples are updated to work with the latest release of
[pyvespa](https://pyvespa.readthedocs.io/en/latest/index.html).

![Decorative image](/assets/2021-03-22-build-news-search-app-from-python-with-vespa/figure_1.jpg)
<p class="image-credit">Photo by <a href="https://unsplash.com/@filipthedesigner?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Filip Mishevski</a> on <a href="/?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a></p>

This series is a simplified version of Vespa's [News search and recommendation tutorial](https://docs.vespa.ai/en/tutorials/news-2-basic-feeding-and-query.html). We will also use the demo version of the [Microsoft News Dataset (MIND)](https://msnews.github.io/) so that anyone can follow along on their laptops.

## Dataset

The original Vespa news search tutorial provides a script to download, parse and convert the MIND dataset to Vespa  format. To make things easier for you, we made the final parsed data required for this tutorial available for download:


```python
import requests, json

data = json.loads(
    requests.get("https://thigm85.github.io/data/mind/mind_demo_fields_parsed.json").text
)
data[0]
```




    {'abstract': "Shop the notebooks, jackets, and more that the royals can't live without.",
     'title': 'The Brands Queen Elizabeth, Prince Charles, and Prince Philip Swear By',
     'subcategory': 'lifestyleroyals',
     'news_id': 'N3112',
     'category': 'lifestyle',
     'url': 'https://www.msn.com/en-us/lifestyle/lifestyleroyals/the-brands-queen-elizabeth,-prince-charles,-and-prince-philip-swear-by/ss-AAGH0ET?ocid=chopendata',
     'date': 20191103,
     'clicks': 0,
     'impressions': 0}



The final parsed data used here is a list where each element is a dictionary containing relevant fields about a news article such as `title` and `category`. We also have information about the number of `impressions` and `clicks` the article has received. The demo version of the mind dataset has 28.603 news articles included.


```python
len(data)
```




    28603



## Install pyvespa


```
$ pip install pyvespa
```

## Create the search app

Create the application package. `app_package` will hold all the relevant data related to your application's specification. 


```python
from vespa.package import ApplicationPackage

app_package = ApplicationPackage(name="news")
```

Add fields to the schema. Here is a short description of the non-obvious arguments used below:

* indexing argument: configures the [indexing pipeline](https://docs.vespa.ai/en/reference/advanced-indexing-language.html) for a field, which defines how Vespa will treat input during indexing.

  * "index": Create a search index for this field.

  * "summary": Lets this field be part of the [document summary](https://docs.vespa.ai/en/document-summaries.html) in the result set.
  
  * "attribute": Store this field in memory as an [attribute](https://docs.vespa.ai/en/attributes.html) — for [sorting](https://docs.vespa.ai/en/reference/sorting.html), [querying](https://docs.vespa.ai/en/query-api.html) and [grouping](https://docs.vespa.ai/en/grouping.html).

* index argument: [configure](https://docs.vespa.ai/en/reference/schema-reference.html#index) how Vespa should create the search index.

  * "enable-bm25": set up an index compatible with [bm25 ranking](https://docs.vespa.ai/en/reference/rank-features.html#bm25) for text search.
  
* attribute argument: [configure](https://docs.vespa.ai/en/attributes.html) how Vespa should treat an attribute field.

  * "fast-search": Build an index for an attribute field. By default, no index is generated for attributes, and search over these defaults to a linear scan.


  


```python
from vespa.package import Field

app_package.schema.add_fields(
    Field(name="news_id", type="string", indexing=["summary", "attribute"], attribute=["fast-search"]),
    Field(name="category", type="string", indexing=["summary", "attribute"]),
    Field(name="subcategory", type="string", indexing=["summary", "attribute"]),
    Field(name="title", type="string", indexing=["index", "summary"], index="enable-bm25"),
    Field(name="abstract", type="string", indexing=["index", "summary"], index="enable-bm25"),
    Field(name="url", type="string", indexing=["index", "summary"]),        
    Field(name="date", type="int", indexing=["summary", "attribute"]),            
    Field(name="clicks", type="int", indexing=["summary", "attribute"]),            
    Field(name="impressions", type="int", indexing=["summary", "attribute"]),                
)
```

Add a fieldset to the schema. Fieldset allows us to search over multiple fields easily. In this case, searching over the `default` fieldset is equivalent to searching over `title` and `abstract`.


```python
from vespa.package import FieldSet

app_package.schema.add_field_set(
    FieldSet(name="default", fields=["title", "abstract"])
)
```

We have enough to deploy the first version of our application. Later in this tutorial, we will include an article’s popularity into the relevance score used to rank the news that matches our queries.

## Deploy the app on Docker

If you have Docker installed on your machine, you can deploy the `app_package` in a local Docker container:   


```python
from vespa.deployment import VespaDocker

vespa_docker = VespaDocker()
app = vespa_docker.deploy(
    application_package=app_package, 
)
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

`vespa_docker` will parse the `app_package` and write all the necessary Vespa config files to the `disk_folder`. It will then create the docker containers and use the Vespa config files to deploy the Vespa application. We can then use the `app` instance to interact with the deployed application, such as for feeding and querying. If you want to know more about what happens behind the scenes, we suggest you go through [this getting started with Docker tutorial](https://docs.vespa.ai/en/tutorials/news-1-getting-started.html). 

## Feed data to the app

We can use the `feed_data_point` method. We need to specify:

* `data_id`: unique id to identify the data point

* `fields`: dictionary with keys matching the field names defined in our application package schema.

* `schema`: name of the schema we want to feed data to. When we created an application package, we created a schema by default with the same name as the application name, `news` in our case.

This takes 10 minutes or so:

```python
for article in data:
    res = app.feed_data_point(
        data_id=article["news_id"], 
        fields=article, 
        schema="news"
    )
```

## Query the app

We can use the [Vespa Query API](https://docs.vespa.ai/en/query-api.html) through `app.query` to unlock the full query flexibility Vespa can offer.

### Search over indexed  fields using keywords

Select all the fields from documents where `default` (title or abstract) contains the keyword 'music'.


```python
res = app.query(body={"yql" : "select * from sources * where default contains 'music'"})
res.hits[0]
```

    {
        'id': 'id:news:news::N14152',
        'relevance': 0.25641557752127125,
        'source': 'news_content',
        'fields': {
            'sddocname': 'news',
            'documentid': 'id:news:news::N14152',
            'news_id': 'N14152',
            'category': 'music',
            'subcategory': 'musicnews',
            'title': 'Music is hot in Nashville this week',
            'abstract': 'Looking for fun, entertaining music events to check out in Nashville this week? Here are top picks with dates, times, locations and ticket links.', 'url': 'https://www.msn.com/en-us/music/musicnews/music-is-hot-in-nashville-this-week/ar-BBWImOh?ocid=chopendata',
            'date': 20191101,
            'clicks': 0,
            'impressions': 3
        }
    }

Select `title` and `abstract` where `title` contains 'music' and `default` contains 'festival'.


```python
res = app.query(body = {"yql" : "select title, abstract from sources * where title contains 'music' AND default contains 'festival'"})
res.hits[0]
```

    {
        'id': 'index:news_content/0/988f76793a855e48b16dc5d3',
        'relevance': 0.19587240022210403,
        'source': 'news_content',
        'fields': {
            'title': "At Least 3 Injured In Stampede At Travis Scott's Astroworld Music Festival",
            'abstract': "A stampede Saturday outside rapper Travis Scott's Astroworld musical festival in Houston, left three people injured. Minutes before the gates were scheduled to open at noon, fans began climbing over metal barricades and surged toward the entrance, according to local news reports."
        }
    }



### Search by document type

Select the title of all the documents with document type equal to `news`. Our application has only one document type, so the query below retrieves all our documents.


```python
res = app.query(body = {"yql" : "select title from sources * where sddocname contains 'news'"})
res.hits[0]
```

    {
        'id': 'index:news_content/0/698f73a87a936f1c773f2161',
        'relevance': 0.0,
        'source': 'news_content',
        'fields': {
            'title': 'The Brands Queen Elizabeth, Prince Charles, and Prince Philip Swear By'
        }
    }



### Search over attribute fields such as date

Since `date` is not specified with `attribute=["fast-search"]` there is no index built for it. Therefore, search over it is equivalent to doing a linear scan over the values of the field.

```python
res = app.query(body={"yql" : "select title, date from sources * where date contains '20191110'"})
res.hits[0]
```

    {
        'id': 'index:news_content/0/debbdfe653c6d11f71cc2353',
        'relevance': 0.0017429193899782135,
        'source': 'news_content',
        'fields': {
            'title': 'These Cranberry Sauce Recipes Are Perfect for Thanksgiving Dinner',
            'date': 20191110
        }
    }

Since the `default` fieldset is formed by indexed fields, Vespa will first filter by all the documents that contain the keyword 'weather' within `title` or `abstract`, before scanning the `date` field for '20191110'.


```python
res = app.query(body={"yql" : "select title, abstract, date from sources * where default contains 'weather' AND date contains '20191110'"})
res.hits[0]
```

    {
        'id': 'index:news_content/0/bb88325ae94d888c46538d0b',
        'relevance': 0.27025156546141466,
        'source': 'news_content',
        'fields': {
            'title': 'Weather forecast in St. Louis',
            'abstract': "What's the weather today? What's the weather for the week? Here's your forecast.",
            'date': 20191110
        }
    }

We can also perform range searches:


```python
res = app.query({"yql" : "select date from sources * where date <= 20191110 AND date >= 20191108"})
res.hits[0]
```

    {
        'id': 'index:news_content/0/c41a873213fdcffbb74987c0',
        'relevance': 0.0017429193899782135,
        'source': 'news_content',
        'fields': {
            'date': 20191109
        }
    }



### Sorting

By default, Vespa sorts the hits by descending relevance score. The relevance score is given by the [nativeRank](https://docs.vespa.ai/en/nativerank.html) unless something else is specified, as we will do later in this post.


```python
res = app.query(body={"yql" : "select title, date from sources * where default contains 'music'"})
res.hits[:2]
```

    [
        {
            'id': 'index:news_content/0/5f1b30d14d4a15050dae9f7f',
            'relevance': 0.25641557752127125,
            'source': 'news_content',
            'fields': {
                'title': 'Music is hot in Nashville this week',
                'date': 20191101
            }
        },
        {
            'id': 'index:news_content/0/6a031d5eff95264c54daf56d',
            'relevance': 0.23351089409559303,
            'source': 'news_content',
            'fields': {
                'title': 'Apple Music Replay highlights your favorite tunes of the year',
                'date': 20191105
            }
        }
    ]

However, we can explicitly order by a given field with the `order` keyword.

```python
res = app.query(body={"yql" : "select title, date from sources * where default contains 'music' order by date"})
res.hits[:2]
```

    [
        {
            'id': 'index:news_content/0/d0d7e1c080f0faf5989046d8',
            'relevance': 0.0,
            'source': 'news_content',
            'fields': {
                'title': "Elton John's second farewell tour stop in Cleveland shows why he's still standing after all these years",
                'date': 20191031
            }
        },
        {
            'id': 'index:news_content/0/abf7f6f46ff2a96862075155',
            'relevance': 0.0,
            'source': 'news_content',
            'fields': {
                'title': 'The best hair metal bands',
                'date': 20191101
            }
        }
    ]

`order` sorts in ascending order by default, we can override that with the `desc` keyword:


```python
res = app.query(body={"yql" : "select title, date from sources * where default contains 'music' order by date desc"})
res.hits[:2]
```

    [
        {
            'id': 'index:news_content/0/934a8d976ff8694772009362',
            'relevance': 0.0,
            'source': 'news_content',
            'fields': {
                'title': 'Korg Minilogue XD update adds key triggers for synth sequences',
                'date': 20191113
            }
        },
        {
            'id': 'index:news_content/0/4feca287fdfa1d027f61e7bf',
            'relevance': 0.0,
            'source': 'news_content',
            'fields': {
                'title': 'Tom Draper, Black Music Industry Pioneer, Dies at 79',
                'date': 20191113
            }
        }
    ]


### Grouping

We can use Vespa's [grouping](https://docs.vespa.ai/en/grouping.html) feature to compute the three news categories with the highest number of document counts:

* news with 9115 articles

* sports with 6765 articles

* finance with 1886 articles


```python
res = app.query(body={"yql" : "select * from sources * where sddocname contains 'news' limit 0 | all(group(category) max(3) order(-count())each(output(count())))"})
res.hits[0]
```

    {
        'id': 'group:root:0',
        'relevance': 1.0,
        'continuation': {
            'this': ''
        },
        'children': [
            {
                'id': 'grouplist:category',
                'relevance': 1.0,
                'label': 'category',
                'continuation': {
                    'next': 'BGAAABEBGBC'
                },
                'children': [
                    {
                        'id': 'group:string:news',
                        'relevance': 1.0,
                        'value': 'news',
                        'fields': {
                            'count()': 9115
                        }
                    },
                    {
                        'id': 'group:string:sports',
                        'relevance': 0.6666666666666666,
                        'value': 'sports',
                        'fields': {
                            'count()': 6765
                        }
                    },
                    {
                        'id': 'group:string:finance',
                        'relevance': 0.3333333333333333,
                        'value': 'finance',
                        'fields': {
                            'count()': 1886
                        }
                    }
                ]
            }
        ]
    }



## Use news popularity signal for ranking

Vespa uses [nativeRank](https://docs.vespa.ai/en/nativerank.html) to compute relevance scores by default. We will create a new rank-profile that includes a popularity signal in our relevance score computation. 


```python
from vespa.package import RankProfile, Function

app_package.schema.add_rank_profile(
    RankProfile(
        name="popularity",
        inherits="default",
        functions=[
            Function(
                name="popularity", 
                expression="if (attribute(impressions) > 0, attribute(clicks) / attribute(impressions), 0)"
            )
        ], 
        first_phase="nativeRank(title, abstract) + 10 * popularity"
    )
)
```

Our new rank-profile will be called `popularity`. Here is a breakdown of what is included above:

* inherits="default"

This configures Vespa to create a new rank profile named popularity, which inherits all the default rank-profile properties; only properties that are explicitly defined, or overridden, will differ from those of the default rank-profile.

* function popularity

This sets up a function that can be called from other expressions. This function calculates the number of clicks divided by impressions for indicating popularity. However, this isn’t really the best way of calculating this, as an article with a low number of impressions can score high on such a value, even though uncertainty is high. But it is a start :)

* first-phase

Relevance calculations in Vespa are two-phased. The calculations done in the first phase are performed on every single document matching your query. In contrast, the second phase calculations are only done on the top n documents as determined by the calculations done in the first phase. We are just going to use the first-phase for now.

* expression: nativeRank + 10 * popularity

This expression is used to rank documents. Here, the default ranking expression — the nativeRank of the default fieldset — is included to make the query relevant, while the second term calls the popularity function. The weighted sum of these two terms is the final relevance for each document. Note that the weight here, 10, is set by observation. A better approach would be to learn such values using machine learning, which we'll get back to in future posts.

### Redeploy the application

Since we have changed the application package, we need to redeploy our application:


```python
app = vespa_docker.deploy(
    application_package=app_package, 
)
```

    Waiting for configuration server, 0/300 seconds...
    Waiting for configuration server, 5/300 seconds...
    Waiting for application status, 0/300 seconds...
    Waiting for application status, 5/300 seconds...
    Waiting for application status, 10/300 seconds...
    Finished deployment.

<!-- ToDo: app.deployment_message does snot seem to print the below -->

```python
app.deployment_message
```




    ["Uploading application '/app/application' using http://localhost:19071/application/v2/tenant/default/session",
     "Session 3 for tenant 'default' created.",
     'Preparing session 3 using http://localhost:19071/application/v2/tenant/default/session/3/prepared',
     "WARNING: Host named 'news' may not receive any config since it is not a canonical hostname. Disregard this warning when testing in a Docker container.",
     "Session 3 for tenant 'default' prepared.",
     'Activating session 3 using http://localhost:19071/application/v2/tenant/default/session/3/active',
     "Session 3 for tenant 'default' activated.",
     'Checksum:   fa83365f9aacba5133026e09c3e42cea',
     'Timestamp:  1615287349323',
     'Generation: 3',
     '']



### Query using the new popularity signal

When the redeployment is complete, we can use it to rank the matched documents by using the `ranking` argument.


```python
res = app.query(body={
    "yql" : "select * from sources * where default contains 'music'",
    "ranking" : "popularity"
})
res.hits[0]
```

    {
        'id': 'id:news:news::N5870',
        'relevance': 5.156596018746151,
        'source': 'news_content',
        'fields': {
            'sddocname': 'news',
            'documentid': 'id:news:news::N5870',
            'news_id': 'N5870',
            'category': 'music',
            'subcategory': 'musicnews',
            'title': 'Country music group Alabama reschedules their Indy show until next October 2020',
            'abstract': 'INDIANAPOLIS, Ind.   Fans of the highly acclaimed country music group Alabama, scheduled to play Bankers Life Fieldhouse Saturday night, will have to wait until next year to see the group. The group famous for such notable songs like "If You\'re Gonna Play in Texas", "Love In The First Degree", and "She and I", made the announcement that their 50th Anniversary Tour is being rescheduled till ...',
            'url': 'https://www.msn.com/en-us/music/musicnews/country-music-group-alabama-reschedules-their-indy-show-until-next-october-2020/ar-BBWB0d7?ocid=chopendata',
            'date': 20191108,
            'clicks': 1,
            'impressions': 2
        }
    }

## Clean up:
```python
vespa_docker.container.stop()
vespa_docker.container.remove()
```

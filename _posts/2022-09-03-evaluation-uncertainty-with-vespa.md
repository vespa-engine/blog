---
layout: post
title: "IR evaluation metrics with uncertainty estimates"
date: '2022-09-03'
tags: []
author: thigm85
image: assets/2022-09-03-evaluation-uncertainty-with-vespa/passage_uncertainty.png
excerpt: Compare different metrics and their uncertainty in the passage ranking dataset.
skipimage: true
---

**Compare different metrics and their uncertainty in the passage ranking dataset.**

When working with search engine apps, be it a text search or a recommendation system, part of the job is doing experiments around components such as ranking functions and deciding which experiments deliver the best result.

This tutorial builds a text search app with [Vespa](https://vespa.ai/), feeds a sample of the passage ranking dataset to the app, and evaluates two ranking functions across three different metrics. **In addition to return point estimates of the evaluation metrics, we compute confidence intervals as illustrated in the plot below**. Measuring uncertainty around the metric estimates gives us a better sense of how significant is the impact of our changes in the application.

![Passage uncertainty](/assets/2022-09-03-evaluation-uncertainty-with-vespa/passage_uncertainty.png)

The code and the data used in this end-to-end tutorial are available and can be reproduced in a Jupyter Notebook.

## Create the Vespa application package

Create a Vespa application package to perform passage ranking experiments using the `create_basic_search_package`.


```python
from learntorank.passage import create_basic_search_package

app_package = create_basic_search_package()
```

We can inspect how the [Vespa search definition](https://docs.vespa.ai/en/schemas.html) file looks like:


```python
print(app_package.schema.schema_to_text)
```

    schema PassageRanking {
        document PassageRanking {
            field doc_id type string {
                indexing: attribute | summary
            }
            field text type string {
                indexing: index | summary
                index: enable-bm25
            }
        }
        fieldset default {
            fields: text
        }
        rank-profile bm25 {
            first-phase {
                expression: bm25(text)
            }
            summary-features {
                bm25(text)
            }
        }
        rank-profile native_rank {
            first-phase {
                expression: nativeRank(text)
            }
        }
    }


In this tutorial, we are going to compare two ranking functions. One is based on [NativeRank](https://docs.vespa.ai/en/reference/nativerank.html), and the other is based on [BM25](https://docs.vespa.ai/en/reference/bm25.html).

## Deploy the application

Deploy the application package in a Docker container for local development. Alternatively, it is possible to deploy the application package to [Vespa Cloud](https://pyvespa.readthedocs.io/en/latest/deploy-vespa-cloud.html).


```python
from vespa.deployment import VespaDocker

vespa_docker = VespaDocker()
app = vespa_docker.deploy(application_package=app_package)
```

    Waiting for configuration server, 0/300 seconds...
    Waiting for configuration server, 5/300 seconds...
    Waiting for configuration server, 10/300 seconds...
    Waiting for configuration server, 15/300 seconds...
    Waiting for application status, 0/300 seconds...
    Waiting for application status, 5/300 seconds...
    Waiting for application status, 10/300 seconds...
    Waiting for application status, 15/300 seconds...
    Waiting for application status, 20/300 seconds...
    Waiting for application status, 25/300 seconds...
    Waiting for application status, 30/300 seconds...
    Waiting for application status, 35/300 seconds...
    Finished deployment.


Once the deployment is finished, we can interact with the deployed application through the `app` variable.

## Get sample data

We can load passage ranking sample data with `PassageData.load`. By default, it will download pre-generated sample data.


```python
from learntorank.passage import PassageData

data = PassageData.load()
```


```python
data
```




    PassageData(corpus, train_qrels, train_queries, dev_qrels, dev_queries)




```python
data.summary
```

    Number of documents: 1000
    Number of train queries: 100
    Number of train relevance judgments: 100
    Number of dev queries: 100
    Number of dev relevance judgments: 100


## Feed the application

Get the document corpus in a `DataFrame` format.


```python
corpus_df = data.get_corpus()
corpus_df.head()
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>doc_id</th>
      <th>text</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>5954248</td>
      <td>Why GameStop is excited for Dragon Age: Inquis...</td>
    </tr>
    <tr>
      <th>1</th>
      <td>7290700</td>
      <td>metaplasia definition: 1. abnormal change of o...</td>
    </tr>
    <tr>
      <th>2</th>
      <td>5465518</td>
      <td>Candice Net Worth. According to the report of ...</td>
    </tr>
    <tr>
      <th>3</th>
      <td>3100518</td>
      <td>Under the Base Closure Act, March AFB was down...</td>
    </tr>
    <tr>
      <th>4</th>
      <td>3207764</td>
      <td>There are a number of career opportunities for...</td>
    </tr>
  </tbody>
</table>
</div>



Feed the data to the deployed application.


```python
responses = app.feed_df(df=corpus_df, include_id=True, id_field="doc_id")
```

    Successful documents fed: 1000/1000.
    Batch progress: 1/1.


We can also check the number of successfully fed documents through the responses status code:


```python
sum([response.status_code == 200 for response in responses])
```




    1000



## Query the application

Get the dev set queries in a `DataFrame` format.


```python
dev_queries_df = data.get_queries(type="dev")
dev_queries_df.head()
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>query_id</th>
      <th>query</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>1101971</td>
      <td>why say the sky is the limit</td>
    </tr>
    <tr>
      <th>1</th>
      <td>712898</td>
      <td>what is an cvc in radiology</td>
    </tr>
    <tr>
      <th>2</th>
      <td>154469</td>
      <td>dmv california how long does it take to get id</td>
    </tr>
    <tr>
      <th>3</th>
      <td>930015</td>
      <td>what's an epigraph</td>
    </tr>
    <tr>
      <th>4</th>
      <td>860085</td>
      <td>what is va tax</td>
    </tr>
  </tbody>
</table>
</div>



Get the first query text to use as an example when querying our passage search application.


```python
sample_query = dev_queries_df.loc[0, "query"]
sample_query
```




    'why say the sky is the limit'



### Query with QueryModel

Create the `bm25` [QueryModel](https://pyvespa.readthedocs.io/en/latest/reference-api.html#querymodel), which uses [Vespa's weakAnd](https://docs.vespa.ai/en/reference/query-language-reference.html#weakand) operator to match documents relevant to the query and use the `bm25` `rank-profile` that we defined in the application package above to rank the documents.


```python
from vespa.query import QueryModel, WeakAnd, RankProfile

bm25_query_model = QueryModel(
    name="bm25", 
    match_phase=WeakAnd(hits=100), 
    rank_profile=RankProfile(name="bm25")
)
```

Once a `QueryModel` is specified, we can use it to query our application.


```python
from pprint import pprint

response = app.query(
    query=sample_query, 
    query_model=bm25_query_model
)
pprint(response.hits[0:2])
```

    [{'fields': {'doc_id': '7407715',
                 'documentid': 'id:PassageRanking:PassageRanking::7407715',
                 'sddocname': 'PassageRanking',
                 'summaryfeatures': {'bm25(text)': 11.979235042476953,
                                     'vespa.summaryFeatures.cached': 0.0},
                 'text': 'The Sky is the Limit also known as TSITL is a global '
                         'effort designed to influence, motivate and inspire '
                         'people all over the world to achieve their goals and '
                         'dreams in life. TSITL’s collaborative community on '
                         'social media provides you with a vast archive of '
                         'motivational pictures/quotes/videos.'},
      'id': 'id:PassageRanking:PassageRanking::7407715',
      'relevance': 11.979235042476953,
      'source': 'PassageRanking_content'},
     {'fields': {'doc_id': '84721',
                 'documentid': 'id:PassageRanking:PassageRanking::84721',
                 'sddocname': 'PassageRanking',
                 'summaryfeatures': {'bm25(text)': 11.310323797415357,
                                     'vespa.summaryFeatures.cached': 0.0},
                 'text': 'Sky Customer Service 0870 280 2564. Use the Sky contact '
                         'number to get in contact with the Sky customer services '
                         'team to speak to a representative about your Sky TV, Sky '
                         'Internet or Sky telephone services. The Sky customer '
                         'Services team is operational between 8:30am and 11:30pm '
                         'seven days a week.'},
      'id': 'id:PassageRanking:PassageRanking::84721',
      'relevance': 11.310323797415357,
      'source': 'PassageRanking_content'}]


### Query with Vespa Query Language

We can also translate the query created with the `QueryModel` into the [Vespa Query Language (YQL)](https://docs.vespa.ai/en/query-language.html) by setting `debug_request=True`:


```python
response = app.query(
    query = sample_query, 
    query_model=bm25_query_model, 
    debug_request=True
)
yql_body = response.request_body
pprint(yql_body)
```

    {'ranking': {'listFeatures': 'false', 'profile': 'bm25'},
     'yql': 'select * from sources * where ([{"targetNumHits": '
            '100}]weakAnd(default contains "why", default contains "say", default '
            'contains "the", default contains "sky", default contains "is", '
            'default contains "the", default contains "limit"));'}


We can use Vespa YQL directly via the `body` parameter:


```python
yql_response = app.query(body=yql_body)
pprint(yql_response.hits[0:2])
```

    [{'fields': {'doc_id': '7407715',
                 'documentid': 'id:PassageRanking:PassageRanking::7407715',
                 'sddocname': 'PassageRanking',
                 'summaryfeatures': {'bm25(text)': 11.979235042476953,
                                     'vespa.summaryFeatures.cached': 0.0},
                 'text': 'The Sky is the Limit also known as TSITL is a global '
                         'effort designed to influence, motivate and inspire '
                         'people all over the world to achieve their goals and '
                         'dreams in life. TSITL’s collaborative community on '
                         'social media provides you with a vast archive of '
                         'motivational pictures/quotes/videos.'},
      'id': 'id:PassageRanking:PassageRanking::7407715',
      'relevance': 11.979235042476953,
      'source': 'PassageRanking_content'},
     {'fields': {'doc_id': '84721',
                 'documentid': 'id:PassageRanking:PassageRanking::84721',
                 'sddocname': 'PassageRanking',
                 'summaryfeatures': {'bm25(text)': 11.310323797415357,
                                     'vespa.summaryFeatures.cached': 0.0},
                 'text': 'Sky Customer Service 0870 280 2564. Use the Sky contact '
                         'number to get in contact with the Sky customer services '
                         'team to speak to a representative about your Sky TV, Sky '
                         'Internet or Sky telephone services. The Sky customer '
                         'Services team is operational between 8:30am and 11:30pm '
                         'seven days a week.'},
      'id': 'id:PassageRanking:PassageRanking::84721',
      'relevance': 11.310323797415357,
      'source': 'PassageRanking_content'}]


## Evaluate query models

In this section, we want to evaluate and compare the `bm25_query_model` defined above with the `native_query_model` defined below:


```python
native_query_model = QueryModel(
    name="native_rank", 
    match_phase=WeakAnd(hits=100), 
    rank_profile=RankProfile(name="native_rank")
)
```

We specify three metrics to evaluate the models.


```python
from vespa.evaluation import (
    Recall, 
    ReciprocalRank, 
    NormalizedDiscountedCumulativeGain
)

metrics = [
    Recall(at=10), 
    ReciprocalRank(at=3), 
    NormalizedDiscountedCumulativeGain(at=3)
]
```

### Point estimates

It is straightforward to obtain point estimates of the evaluation metrics for each query model being compared. In this case, we computed the mean and the standard deviation for each of the metrics.


```python
evaluation = app.evaluate(
    labeled_data=data.get_labels(type="dev"), 
    eval_metrics=metrics, 
    query_model=[native_query_model, bm25_query_model], 
    id_field="doc_id",
    aggregators=["mean", "std"]
 )
```


```python
evaluation
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>model</th>
      <th>bm25</th>
      <th>native_rank</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th rowspan="2" valign="top">recall_10</th>
      <th>mean</th>
      <td>0.935833</td>
      <td>0.845833</td>
    </tr>
    <tr>
      <th>std</th>
      <td>0.215444</td>
      <td>0.342749</td>
    </tr>
    <tr>
      <th rowspan="2" valign="top">reciprocal_rank_3</th>
      <th>mean</th>
      <td>0.935000</td>
      <td>0.755000</td>
    </tr>
    <tr>
      <th>std</th>
      <td>0.231977</td>
      <td>0.394587</td>
    </tr>
    <tr>
      <th rowspan="2" valign="top">ndcg_3</th>
      <th>mean</th>
      <td>0.912839</td>
      <td>0.749504</td>
    </tr>
    <tr>
      <th>std</th>
      <td>0.242272</td>
      <td>0.381792</td>
    </tr>
  </tbody>
</table>
</div>



Given the nature of the data distribution of the metrics described above, it is not trivial to compute a confidence interval from the mean and the standard deviation computed above. In the next section, we solve this by using bootstrap sampling on a per query metric evaluation.

### Uncertainty estimates

Instead of returning aggregated point estimates, we can also compute the metrics per query by setting `per_query=True`. This gives us more granular information on the distribution function of the metrics. 


```python
evaluation_per_query = app.evaluate(
    labeled_data=data.get_labels(type="dev"), 
    eval_metrics=metrics, 
    query_model=[native_query_model, bm25_query_model], 
    id_field="doc_id",
    per_query=True
)
```


```python
evaluation_per_query.head()
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>model</th>
      <th>query_id</th>
      <th>recall_10</th>
      <th>reciprocal_rank_3</th>
      <th>ndcg_3</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>native_rank</td>
      <td>1101971</td>
      <td>1.0</td>
      <td>1.0</td>
      <td>1.0</td>
    </tr>
    <tr>
      <th>1</th>
      <td>bm25</td>
      <td>1101971</td>
      <td>1.0</td>
      <td>1.0</td>
      <td>1.0</td>
    </tr>
    <tr>
      <th>2</th>
      <td>native_rank</td>
      <td>712898</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
    </tr>
    <tr>
      <th>3</th>
      <td>bm25</td>
      <td>712898</td>
      <td>1.0</td>
      <td>1.0</td>
      <td>1.0</td>
    </tr>
    <tr>
      <th>4</th>
      <td>native_rank</td>
      <td>154469</td>
      <td>1.0</td>
      <td>0.0</td>
      <td>0.0</td>
    </tr>
  </tbody>
</table>
</div>



We then created a function that uses the evaluation per query data and computes uncertainty estimates via bootstrap sampling.


```python
from learntorank.stats import compute_evaluation_estimates

estimates = compute_evaluation_estimates(
    df = evaluation_per_query
)
```


```python
estimates
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>metric</th>
      <th>model</th>
      <th>low</th>
      <th>median</th>
      <th>high</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>ndcg_3</td>
      <td>bm25</td>
      <td>0.867175</td>
      <td>0.916406</td>
      <td>0.956971</td>
    </tr>
    <tr>
      <th>1</th>
      <td>ndcg_3</td>
      <td>native_rank</td>
      <td>0.671242</td>
      <td>0.750765</td>
      <td>0.821555</td>
    </tr>
    <tr>
      <th>2</th>
      <td>recall_10</td>
      <td>bm25</td>
      <td>0.893313</td>
      <td>0.938333</td>
      <td>0.973333</td>
    </tr>
    <tr>
      <th>3</th>
      <td>recall_10</td>
      <td>native_rank</td>
      <td>0.776625</td>
      <td>0.848333</td>
      <td>0.910042</td>
    </tr>
    <tr>
      <th>4</th>
      <td>reciprocal_rank_3</td>
      <td>bm25</td>
      <td>0.890000</td>
      <td>0.940000</td>
      <td>0.975000</td>
    </tr>
    <tr>
      <th>5</th>
      <td>reciprocal_rank_3</td>
      <td>native_rank</td>
      <td>0.678292</td>
      <td>0.756667</td>
      <td>0.826667</td>
    </tr>
  </tbody>
</table>
</div>



We can then create plots based on this data to make it easier to judge the magnitude of the differences between ranking functions.


```python
from plotnine import *

print((ggplot(estimates) + 
 geom_point(aes("model", "median")) + 
 geom_errorbar(aes(x="model", ymin="low",ymax="high")) + 
 facet_wrap("metric") + labs(y="Metric value")
))
```


    
![Passage uncertainty](/assets/2022-09-03-evaluation-uncertainty-with-vespa/passage_uncertainty.png)
    


    


## Cleanup the environment


```python
vespa_docker.container.stop(timeout=600)
vespa_docker.container.remove()
```

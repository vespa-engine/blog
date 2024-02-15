---
layout: post
title: Learning to Rank with Vespa – Getting started with Text Search
author: thigm85
date: '2019-12-04T23:28:07-08:00'
image: assets/2019-12-04-learning-to-rank-with-vespa-getting-started-with/0280c78756d9a59068630a85ff30aad3876cdf97.png
tags:
- machine learning
- search
- tensorflow
- vespa
- learning to rank
tumblr_url: https://blog.vespa.ai/post/189478730081/learning-to-rank-with-vespa-getting-started-with
---
[Vespa.ai](https://vespa.ai/) have just published two tutorials to help people to get started with text search applications by building scalable solutions with Vespa.
The tutorials were based on the [full document ranking task](https://microsoft.github.io/msmarco/TREC-Deep-Learning-2019#document-ranking-task)
released by [Microsoft’s MS MARCO dataset](https://microsoft.github.io/msmarco/)’s team.

[The first tutorial](https://docs.vespa.ai/en/tutorials/text-search.html) helps you to create and deploy a basic text search application with Vespa as well as to download, parse and feed the dataset to a running Vespa instance. They also show how easy it is to experiment with ranking functions based on built-in ranking features available in Vespa.

[The second tutorial](https://docs.vespa.ai/en/tutorials/text-search-ml.html) shows how to create a training dataset containing Vespa ranking features that allow you to start training ML models to improve the app’s ranking function. It also illustrates the importance of going beyond pointwise loss functions when training models in a learning to rank context.

Both tutorials are detailed and come with code available to reproduce the steps. Here are the highlights.

## Basic text search app in a nutshell

The main task when creating a basic app with Vespa is to write a search definition file containing information about the data you want to feed to the application and how Vespa should match and order the results returned in response to a query.

Apart from some additional details described in [the tutorial](https://docs.vespa.ai/en/tutorials/text-search.html), the search definition for our text search engine looks like the code snippet below. We have a title and body `field` containing information about the documents available to be searched. The `fieldset` keyword indicates that our query will match documents by searching query words in both title and body fields. Finally, we have defined two `rank-profile`, which controls how the matched documents will be ranked. The `default` rank-profile uses `nativeRank,` which is one of many [built-in rank features](https://docs.vespa.ai/en/reference/rank-features.html) available in Vespa. The `bm25` rank-profile uses the widely known [BM25 rank feature](https://docs.vespa.ai/en/reference/bm25.html).

    search msmarco { 
        document msmarco {
            field title type string
            field body type string 
        }
        fieldset default {
            fields: title, body
        }    
        rank-profile default {
            first-phase {
                expression: nativeRank(title, body)
            }
        }
        rank-profile bm25 inherits default {
            first-phase {
                expression: bm25(title) + bm25(body)
            }
        } 
    }

When we have more than one rank-profile defined, we can chose which one to use at query time, by including the `ranking` parameter in the query:

    curl -s "<URL>/search/?query=what+is+dad+bod"
    curl -s "<URL>/search/?query=what+is+dad+bod&ranking=bm25"

The first query above does not specify the `ranking` parameter and will therefore use the `default` rank-profile. The second query explicitly asks for the `bm25` rank-profile to be used instead.

Having multiple rank-profiles allow us to experiment with different ranking functions. There is one relevant document for each query in the MSMARCO dataset. The figure below is the result of an evaluation script that sent more than 5.000 queries to our application and asked for results using both rank-profiles described above. We then tracked the position of the relevant document for each query and plotted the distribution for the first 10 positions.

<figure data-orig-width="650" data-orig-height="700" class="tmblr-full"><img src="/assets/2019-12-04-learning-to-rank-with-vespa-getting-started-with/e873ef7129f426267ae17825c3b4accb4370ade3.png" data-orig-width="650" data-orig-height="700"></figure>

It is clear that the `bm25` rank-profile does a much better job in this case. It places the relevant document in the first positions much more often than the `default` rank-profile.

## Data collection sanity check

After setting up a basic application, we likely want to collect rank feature data to help improve our ranking functions. Vespa allow us to return rank features along with query results, which enable us to create training datasets that combine relevance information with search engine rank information.

There are different ways to create a training dataset in this case. Because of this, we believe it is a good idea to have a sanity check established before we start to collect the dataset. The goal of such sanity check is to increase the likelihood that we catch bugs early and create datasets containing the right information associated with our task of improving ranking functions.

Our proposal is to use the dataset to train a model using the same features and functional form used by the baseline you want to improve upon. If the dataset is well built and contains useful information about the task you are interested you should be able to get results at least as good as the one obtained by your baseline on a separate test set.

Since our baseline in this case is the `bm25` rank-profile, we should fit a linear model containing only the bm25 features:

    a + b * bm25(title) + c * bm25(body)

Having this simple procedure in place helped us catch a few silly bugs in our data collection code and got us in the right track faster than would happen otherwise. Having bugs on your data is hard to catch when you begin experimenting with complex models as we never know if the bug comes from the data or the model. So this is a practice we highly recommend.

## How to create a training dataset with Vespa

Asking Vespa to return ranking features in the result set is as simple as setting the `ranking.listFeatures` parameter to `true` in the request. Below is the body of a POST request that specify the query in [YQL format](https://docs.vespa.ai/en/query-language.html) and enable the rank features dumping.

    body = {
        "yql": 'select * from sources * where (userInput(@userQuery));',
        "userQuery": "what is dad bod",
        "ranking": {"profile": "bm25", "listFeatures": "true"},
    }

Vespa returns [a bunch of ranking features](https://github.com/vespa-engine/system-test/blob/master/tests/search/rankfeatures/dump.txt) by default, but we can explicitly define which features we want by creating a rank-profile and ask it to `ignore-default-rank-features` and list the features we want by using the `rank-features` keyword, as shown below. The `random` first phase will be used when sampling random documents to serve as a proxy to non-relevant documents.

    rank-profile collect_rank_features inherits default {
    
        first-phase {
            expression: random
        }
    
        ignore-default-rank-features
    
        rank-features {
            bm25(title)
            bm25(body)
            nativeRank(title)
            nativeRank(body)
        }
    
    }

We want a dataset that will help train models that will generalize well when running on a Vespa instance. This implies that we are only interested in collecting documents that are matched by the query because those are the documents that would be presented to the first-phase model in a production environment. Here is the data collection logic:

    hits = get_relevant_hit(query, rank_profile, relevant_id)
    if relevant_hit:
        hits.extend(get_random_hits(query, rank_profile, n_samples))
        data = annotate_data(hits, query_id, relevant_id)
        append_data(file, data)

For each query, we first send a request to Vespa to get the relevant document associated with the query. If the relevant document is matched by the query, Vespa will return it and we will expand the number of documents associated with the query by sending a second request to Vespa. The second request asks Vespa to return a number of random documents sampled from the set of documents that were matched by the query.

We then parse the hits returned by Vespa and organize the data into a tabular form containing the rank features and the binary variable indicating if the query-document pair is relevant or not. At the end we have a dataset with the following format. More details can be found in [our second tutorial](https://docs.vespa.ai/en/tutorials/text-search-ml.html).

<figure class="tmblr-full" data-orig-height="268" data-orig-width="1324"><img src="/assets/2019-12-04-learning-to-rank-with-vespa-getting-started-with/27eb0eb7626c85140d8596d0a82c9dd8b5a558fe.png" data-orig-height="268" data-orig-width="1324"></figure>
## Beyond pointwise loss functions

The most straightforward way to train the linear model suggested in our data collection sanity check would be to use a vanilla logistic regression, since our target variable `relevant` is binary. The most commonly used loss function in this case (binary cross-entropy) is referred to as a pointwise loss function in the LTR literature, as it does not take the relative order of documents into account.

However, as we described in [our first tutorial](https://docs.vespa.ai/en/tutorials/text-search.html), the metric that we want to optimize in this case is the Mean Reciprocal Rank (MRR). The MRR is affected by the relative order of the relevance we assign to the list of documents generated by a query and not by their absolute magnitudes. This disconnect between the characteristics of the loss function and the metric of interest might lead to suboptimal results.

For ranking search results, it is preferable to use a listwise loss function when training our model, which takes the entire ranked list into consideration when updating the model parameters. To illustrate this, we trained linear models using the [TF-Ranking framework](https://github.com/tensorflow/ranking). The framework is built on top of TensorFlow and allow us to specify pointwise, pairwise and listwise loss functions, among other things.

We [made available](https://github.com/vespa-engine/sample-apps/tree/master/text-search) the script that we used to train the two models that generated the results displayed in the figure below. The script uses simple linear models but can be useful as a starting point to build more complex ones.

<figure class="tmblr-full" data-orig-height="700" data-orig-width="650"><img src="/assets/2019-12-04-learning-to-rank-with-vespa-getting-started-with/0280c78756d9a59068630a85ff30aad3876cdf97.png" data-orig-height="700" data-orig-width="650"></figure>

Overall, on average, there is not much difference between those models (with respect to MRR), which was expected given the simplicity of the models described here. However, we can see that a model based on a listwise loss function allocate more documents in the first two positions of the ranked list when compared to the pointwise model. We expect the difference in MRR between pointwise and listwise loss functions to increase as we move on to more complex models.

The main goal here was simply to show the importance of choosing better loss functions when dealing with LTR tasks and to give a quick start for those who want to give it a shot in their own Vespa applications. Now, it is up to you, check out [the tutorials](https://docs.vespa.ai/en/tutorials/text-search.html), build something and [let us know](https://twitter.com/vespaengine) how it went. Feedbacks are welcome!


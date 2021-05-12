---
layout: post
title: Introducing JSON queries
date: '2018-08-08T14:20:06-07:00'
tags: []
tumblr_url: https://blog.vespa.ai/post/176767364771/introducing-json-queries
---
 **We recently introduced a new addition to the Search API - JSON queries. The search request can now be executed with a POST request, which includes the query-parameters within its payload. Along with this new query we also introduce a new parameter `SELECT` with the sub-parameters `WHERE` and `GROUPING`, which is equivalent to YQL.**

**The new query**

With the Search APIs newest addition, it is now possible to send queries with HTTP POST. The query-parameters has been moved out of the URL and into a POST request body - therefore, no more URL-encoding. You also avoid getting all the queries in the log, which can be an advantage.

This is how a GET query looks like:

    GET /search/?param1=value1¶m2=value2&...

The general form of the new POST query is:

    POST /search/ { param1 : value1, param2 : value2, ... }

The dot-notation is gone, and the query-parameters are now nested under the same key instead.

Let’s take this query:

    GET /search/?yql=select+%2A+from+sources+%2A+where+default+contains+%22bad%22%3B&ranking.queryCache=false&ranking.profile=vespaProfile&ranking.matchPhase.ascending=true&ranking.matchPhase.maxHits=15&ranking.matchPhase.diversity.minGroups=10&presentation.bolding=false&presentation.format=json&nocache=true

and write it in the new POST request-format, which will look like this:

    POST /search/ { "yql": "select \* from sources \* where default contains \"bad\";", "ranking": { "queryCache": "false", "profile": "vespaProfile", "matchPhase": { "ascending": "true", "maxHits": 15, "diversity": { "minGroups": 10 } } }, "presentation": { "bolding": "false", "format": "json" }, "nocache": true }

With Vespa running (see [Quick Start](https://docs.vespa.ai/en/vespa-quick-start.html) or [Blog Search Tutorial](https://docs.vespa.ai/en/tutorials/blog-search.html)), you can try building POST-queries with the _new querybuilder GUI_ at [http://localhost:8080/querybuilder/](http://localhost:8080/querybuilder/), which can help you build queries with e.g. autocompletion of YQL:

<figure data-orig-width="934" data-orig-height="1408" class="tmblr-full"><img src="/assets/2018-08-08-introducing-json-queries/tumblr_inline_pd55x78hVH1vpfrlb_540.png" alt="image" data-orig-width="934" data-orig-height="1408"></figure>

**The Select-parameter**

The `SELECT`-parameter is used with POST queries and is the JSON equivalent of YQL queries, so they can not be used together. The `query`-parameter will overwrite `SELECT`, and decide the query’s querytree.

**Where**

The SQL-like syntax is gone and the tree-syntax has been enhanced. If you’re used to the query-parameter syntax you’ll feel right at home with this new language. YQL is a regular language and is parsed into a query-tree when parsed in Vespa. You can now build that tree in the `WHERE`-parameter with JSON. Lets take a look at the yql: `select * from sources * where default contains foo and rank(a contains "A", b contains "B");`, which will create the following query-tree:

<figure data-orig-width="1323" data-orig-height="622" class="tmblr-full"><img src="/assets/2018-08-08-introducing-json-queries/tumblr_inline_pd55yrwNbZ1vpfrlb_540.png" alt="image" data-orig-width="1323" data-orig-height="622"></figure>

You can build the tree above with the `WHERE`-parameter, like this:

    {
        "and" : [
            { "contains" : ["default", "foo"] },
            { "rank" : [
                { "contains" : ["a", "A"] },
                { "contains" : ["b", "B"] }
            ]}
        ]
    }

Which is equivalent with the YQL.

**Grouping**

The grouping can now be written in JSON, and can now be written with structure, instead of on the same line. Instead of parantheses, we now use curly brackets to symbolise the tree-structure between the different grouping/aggregation-functions, and colons to assign function-arguments.

A grouping, that will group first by year and then by month, can be written as such:

    | all(group(time.year(a)) each(output(count())
             all(group(time.monthofyear(a)) each(output(count())))

and equivalentenly with the new `GROUPING`-parameter:

    "grouping" : [
        {
            "all" : {
                "group" : "time.year(a)",
                "each" : { "output" : "count()" },
                "all" : {
                    "group" : "time.monthofyear(a)",
                    "each" : { "output" : "count()" },
                }
            }
        }
    ]

**Wrapping it up**

In this post we have provided a gentle introduction to the new Vepsa POST query feature, and the `SELECT`-parameter. You can read more about writing [POST queries in the Vespa documentation](https://docs.vespa.ai/en/query-api.html). More examples of the POST query can be found in the Vespa tutorials.

Please share experiences. Happy searching!


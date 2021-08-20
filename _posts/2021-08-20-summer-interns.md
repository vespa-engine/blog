---
layout: post
title: "Internship at Vespa"
author: chunnoo onorum
date: "2021-08-20"
image: assets/2021-08-20-summer-interns/interns.jpg
tags: []
excerpt: After the summer internship of 2021 the interns have summarised what they have done and their experience at Vespa
---


<p class="image credits">
Photo by <a href="https://unsplash.com/@charlesdeluvio">Charles Deluvio</a> on <a href="https://unsplash.com/s/photos/working-baby">Unsplash</a></p>

Over the course of the summer we the interns have gotten to explore the Vespa
engine and the workings of the company. At the start of our internship we got
an introduction to the company and the tools that the they used. To get
familiar with the vespa engine we went through the getting started tutorial,
where we made made a news recomendation system.

During our internship we got to work on many different things, but 
our two main projects were to use Vespa to implement two sample
applications for searching through the Vespa documentation. These two sample
apps were named
[search-as-you-type](https://github.com/vespa-engine/sample-apps/tree/master/incremental-search/search-as-you-type)
and
[search-suggestions](https://github.com/vespa-engine/sample-apps/tree/master/incremental-search/search-suggestions).

### Search-as-you-type

The search-as-you-type application aims to implement an interface where results
are displayed live while the user is typing in the search bar. This requires
the search to both generate hits on incomplete words and to retrieve these hits
as close to instantly as possible. A substring search would fit the need for
incomplete word searches, however for large corpora, this would not meet the
performance requirement. Our solution instead uses n-grams (groups of n
characters) to simulate a substring-like search. The idea is to search for
n-grams and rank the hits where the n-grams are bunched up together higher than
the hits where the n-grams are spread throughout the document. After trying
various configurations we found that 3-grams in combination with Vespas
[nativeRank](https://docs.vespa.ai/en/reference/nativerank.html) fit our needs
very well. In addition we combined this with index search such that if the
search string consists of complete words the indexed search hits would rank
higher than the n-gram search hits.

<pre>
schema doc {
    field gram_content type string {
        indexing: input content | index | summary
        match {
            gram
            gram-size: 3
        }
        summary: dynamic
    }
...
    document doc {
...
        field content type string {
            indexing: index | summary
            summary: dynamic
            stemming: best
        }
...
    rank-profile weighted_doc_rank inherits default {
        rank-properties {
            $contentWeight: 10.0
            $gramContentWeight: 1.0
        }
        first-phase {
            expression {
                query(contentWeight) * nativeRank(content)
                + query(gramContentWeight) * nativeRank(gram_content)
            }
        }
    }
}
</pre>

After the Vespa application was in place, we needed an actual search bar for
the search as you type to take place. This was implemented by incorporating a
simple static web page java server into the Vespa application and writing some
javascript to query the Vespa application every time a character was entered
into the search bar. In addition, a debounce-function was used to avoid race
condition due to simultaneous query requests.

### Search-suggestion

The idea behind the search-suggestion application is to suggest possible search
terms to the user before they have typed out their whole query. In our
implementation these suggestions comes either from the document texts the users are
searching through or from previous searches performed by other users.

The first iteration of the search-suggestion application fed new search terms
by "put", which thus resulted in storing multiples of the same terms. To
calculate relevance and single out terms, the generated hits where grouped and
counted.  This was not a scalable solution as more data for the same search
terms would result in a linear increase in both storage space and process time
for each query. To solve this we switched to feeding by "update". In other
words, adding unseen terms and incrementing their "query\_count" variable when
processing previously seen terms.

<pre>
[
  {
    "update": "id:term:term::example",
    "create": true,
    "fields": {
      "term": {
        "assign": "example"
      },
      "corpus_count": {
        "assign": 181
      },
      "document_count": {
        "assign": 40
      }
    }
  },
  {
    "update": "id:term:term::example",
    "create": true,
    "fields": {
      "term": { "assign": "example" },
      "query_count": { "increment": 1 }
    }
  }
]
</pre>

Since we were going to use queries written by users as suggestions, we had to
implement some form of moderation as to what could be suggested. To solve this
problem we made a list of allowed terms and used a document processor to filter
out any documents that contained terms not in the list. We chose to generate
the allowed-list by listing every word used in the document text. This made it
so that all relevant terms could be suggested, and things that could be seen as
offensive or otherwise irrelevant would not come up as suggestions, as they was
not contained in the document text and thus would be blocked by the document
processor and not fed.

For the first iteration of the search-suggestion, the application used Vespas
streaming search with prefix matching to search for documents with matching
prefixes. After a presentation of the application and some discussion it was
believed that streaming search would not be scalable as the number of
concurrent users increased. To test this belief we did a benchmark of the
application using fbench ([benchmark results](https://github.com/vespa-engine/sample-apps/blob/master/incremental-search/search-suggestions/README-benchmarking.md)).
As suspected the performance of streaming search drastically decreased as
the number of concurrent users increased. We decided to change the application
to use index prefix search, and after a comparison benchmark test it was
confirmed that this implementation scaled much better than streaming search.

Like we did with the search-as-you-type application, we incorporated a static
web page java server into the Vespa application and wrote some javascript for
querying suggestions on every input and showing these suggestions in a dropdown
under the search bar.

We also took the two sample applications we made and integrated them in to an
already existing sample application
[vespa-documentation-search](https://github.com/vespa-engine/sample-apps/tree/master/vespa-cloud/vespa-documentation-search)
which is deployed on to Vespa Cloud. As of now this deployment is also used for
search suggestion on the Vespa documentation sites in the search bar.

#### AWS Lambda

One of the goals of the search-suggestion application was to favor searches
that where previously searched for. To accomplish this we decided to create a AWS
Lambda function which would read query logs and feed search term from these
back into the Vespa application. The reason for this was that the query logs
where stored in AWS S3 buckets and that this would make it possible to
continuously trigger the Lambda function and process future query logs. The
biggest problem we faced when writing this Lambda function was decompressing
the logs. Vespa stores its query logs compressed with zstd-compression and
finding a zstd-library usable in a AWS Lambda context was not straight forward.
Initially a lot of time was spent learning AWS SAM and deploying a docker image
to the Lambda function, as this would let us use native C++ libraries in the
Lambda. However, we later found a library which compiled to web assembly and
would let us decompress filed with just a Node.js Lambda function.

### Other projects

While working on the main projects, we also got to work on other smaller side
projects. One of these side projects was to implement a visualization view of
[protons](https://docs.vespa.ai/en/proton.html) memory usage. This view was
created using react and incorporated into the Vespa Console. We also got to
work with Vespas performance tests and moved some of the private performance
tests over to the public opensource repository by changing the document sets so
that they did not use private or sensitive data.

### The experience at Vespa

At the start of the internship it felt a bit daunting to make our own sample 
applications, given that the vespa engine was something completely new to us. 
Even after the getting started tutorial many things were still unclear, but as we 
started working on the sample applications, more and more things became clearer as 
we had to dive in to the documentation and previously written code to be able to 
make the applications from scratch.

Since there is so much you can do with Vespa it was hard at times to find the answers 
to our questions in the documentation. Not necessarily because it did not exist, but
because we did not know what to search for to find the right documents. This led to us
some times using Vespas public github-repositories to find answers to our questions. 
Even though we some times did not find the answers we were looking for, we never felt
lost as there were always someone ready to help us out when we got stuck.

During our internship at Vespa we got to learn a lot about the vespa search
engine and information retrieval in general. We have especially learned some 
different methods of doing search with incomplete queries and query processing. 
We have also gotten a feel for how it is to work in a software company through 
daily stand-ups and presentations of our projects.

Working here have given us insight into the workflow and github etiquette of a
software company. The internship has given us experience with working in a
team of developers and how to collaborate through github effectively. We
have touched upon various technologies from writing user interfaces in React to
writing performance tests in Ruby. We have also gotten to work with and learn 
about important platforms and services like Amazon Web Service and Docker, which 
is commonly used in companies but not taught in schools. 

Even after the internship there are still many things that we have not touched 
upon or learned about, and we wish we could explore more. To go deeper in 
to the lower levels of the code and the working of Vespa, and to learn more about
search from the experienced people working at Vespa. We grew attached to the 
projects we worked on and wished we had more time to fine tune, and improve 
them to get an even better search in the vespa documentation.

We really enjoyed our stay here, with a nice staff who have an incredible
expertise regarding search and information retrieval, from whom we have learned a
lot. The experience at Vespa has been really pleasant and educational, and is some thing
that has and will benefit us in the future.
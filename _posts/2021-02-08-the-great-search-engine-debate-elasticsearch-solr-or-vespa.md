---
layout: post
title: 'Q&A from &ldquo;The Great Search Engine Debate - Elasticsearch, Solr or Vespa?&rdquo; Meetup'
date: '2021-02-08'
tags: []
author: kkraune
image: assets/2021-02-08-the-great-search-engine-debate-elasticsearch-solr-or-vespa/cover.png
excerpt: This blog post addresses the Vespa-related questions,
    with quicklinks into the recording for easy access.
    We have also responded to the unanswered questions from the chat log.
---

On January 28th, 2021, at 17:00 CET,
Charlie Hull from [OpenSource Connections](https://opensourceconnections.com/) hosted
<a href="https://www.meetup.com/Haystack-Search-Relevance-Online/events/275820872/" data-proofer-ignore>
The Great Search Engine Debate - Elasticsearch, Solr or Vespa?</a> -
a meetup on Haystack LIVE!,
with Anshum Gupta, VP of Apache Lucene, Josh Devins from Elastic and Jo Kristian Bergum from Vespa.

So many great questions were asked that there was no time to go through them all.
This blog post addresses the Vespa-related questions,
with quicklinks into the [recording](https://youtu.be/SzZ_A9G6PMY) for easy access.
We have also extracted the unanswered questions from the chat log, linking to Vespa resources.
Please let us know if this is useful.
Feel free to follow up with the Vespa Team using the resources at
[https://vespa.ai/support](https://vespa.ai/support),
<a href="https://app.gitter.im/#/room/#vespa-engine_Lobby:gitter.im" data-proofer-ignore>Gitter live chat</a>.
You will also find us in the #vespa channel of [Relevance Slack](https://www.opensourceconnections.com/slack).
You can also find Charlie’s summary post at
[Solr vs Elasticsearch vs Vespa – what did we learn at The Great Search Engine Debate?](https://opensourceconnections.com/blog/2021/02/02/solr-vs-elasticsearch-vs-vespa-what-did-we-learn-at-the-great-search-engine-debate/).


<hr/>


**All three speakers were asked to do a pitch and closing words.
Three things that make you recommend your technology -
see the [Vespa pitch](https://youtu.be/SzZ_A9G6PMY?t=756) and [Vespa top three](https://youtu.be/SzZ_A9G6PMY?t=5741) -
summary:**
 
1. Vespa has a great toolbox for modern retrieval, state-of-the-art retrieval/ranking with Machine Learning
2. Vespa’s indexing architecture allows true partial updates at scale, with high indexing volume - when combined with #1, one can have realtime updated models to make decisions in real time, on updated information
3. Vespa’s scalability and true elastic content cluster. You don’t have to pre-determine the number of shards. Can go from 1 node to 100 nodes, just add nodes.

Resources: [ranking](https://docs.vespa.ai/en/ranking.html),
[reads and writes](https://docs.vespa.ai/en/reads-and-writes.html),
[elastic Vespa](https://docs.vespa.ai/en/elastic-vespa.html)


<hr/>


**Use case differentiator, I am curious if the participants could walk through:
let’s say I have an index with text for search, but also a couple dozen features I intend to use in LTR.
I want to update two of the dozen features across several billion documents because I changed my feature extraction.
How does the engine deal with this?**

[ [quicklink](https://youtu.be/SzZ_A9G6PMY?t=1819) ].
Common and widely used Vespa use case.
True partial updates of attribute fields which are in-memory, update and evaluate in place -
no need to read the entire document and apply the update and write it to a new index segment
like in Solr/Elasticsearch which builds on Lucene.
Vespa can do 50,000 numeric partial updates per second per node.
Ranking will immediately see the update and use value in computations (search, rank, sorting, faceting).

Resources: [ranking](https://docs.vespa.ai/en/ranking.html),
[reads and writes](https://docs.vespa.ai/en/reads-and-writes.html),
[elastic Vespa](https://docs.vespa.ai/en/elastic-vespa.html)


<hr/>


**Much of the popularity around ES and Solr arises from the fact that they are very "approachable" technologies.
It's simple for a beginner to get started indexing and searching documents at a basic level,
and most importantly, understanding and influencing which documents are returned.
My impression is that the technical entry level for Vespa is much more advanced.
Would you agree or disagree? How would you recommend starting out with Vespa?**

[ [quicklink](https://youtu.be/SzZ_A9G6PMY?t=2024) ].
Learned a lot from Elasticsearch on developer friendliness,
maybe at 80% ease of use. With Vespa, it’s easy to go from laptop to full cloud deployment.
Use Docker to run Vespa on your laptop.
Use Vespa application package to go from laptop to full size - it is the same config.

Resources: [application packages](https://docs.vespa.ai/en/application-packages.html),
[getting started](https://docs.vespa.ai/en/getting-started.html),
[cloud.vespa.ai](https://cloud.vespa.ai/)


<hr/>


**I have a question regarding Vespa: How is the support for non-English languages regarding tokenizers, stemmers, etc.?
I'm especially interested in German, Russian, Polish, Czech and Hungarian.
How big would be the effort to adapt Solr / OpenNLP resources to use them with Vespa?**

[ [quicklink](https://youtu.be/SzZ_A9G6PMY?t=2427) ].
Vespa integrates with [Apache OpenNLP](https://opennlp.apache.org/),
so any language supported by it, Vespa supports it.
It’s easy to integrate with new linguistic libraries and we’ve already received CJK contributions to Vespa.

Resources: [linguistics](https://docs.vespa.ai/en/linguistics.html) 


<hr/>


**Which search engine is best for a write-heavy application?
Based on my experience, Elasticsearch read performance is impacted when there are heavy writes.**

[ [quicklink](https://youtu.be/SzZ_A9G6PMY?t=2623) ].
Vespa moved away from indexing architecture similar to Elasticsearch and Solr,
where it used small immutable index segments that were later merged.
Vespa has a mutable in-memory index in front of immutable index segments.
All IO writes are sequential. No shards. Attributes fields are searchable, in-place updateable.
Efficient use of OS buffer cache for random reads from search.
Real-time indexing with Solr and Elasticsearch creates many immutable segments
which all need to be searched (single threaded execution as well),
so latency is definitively impacted more than with Vespa which has a memory index + larger immutable index.

Resources: [reads and writes](https://docs.vespa.ai/en/reads-and-writes.html),
[attributes](https://docs.vespa.ai/en/attributes.html),
[proton](https://docs.vespa.ai/en/proton.html) 


<hr/>


**"Join" is always a problem with SOLR/Elasticsearch. How does Vespa handle it?**

[ [quicklink](https://youtu.be/SzZ_A9G6PMY?t=3148) ].
Supported scalable join is implemented using parent/child relationship.
The parent is a global document - distributed across all nodes in the cluster.
Child documents access attribute in-memory fields imported from parent documents.
Can also use the stateless container, deploy a custom Java searcher, do joins on top of multiple searches.

Resources: [parent-child](https://docs.vespa.ai/en/parent-child.html),
[Vespa overview](https://docs.vespa.ai/en/overview.html),
[attributes](https://docs.vespa.ai/en/attributes.html)


<hr/>


**Can people talk a bit more about kubernetes integrations?**

[ [quicklink](https://youtu.be/SzZ_A9G6PMY?t=3406) ].
Yes, one can run Vespa on K8s.

Resources: [vespa-quick-start-kubernetes](https://docs.vespa.ai/en/vespa-quick-start-kubernetes.html)


<hr/>


**How does Vespa compare to FAISS?**

[ [quicklink](https://youtu.be/SzZ_A9G6PMY?t=3607) ].
[FAISS](https://ai.facebook.com/tools/faiss) uses [HSNW](https://arxiv.org/abs/1603.09320) like Vespa.
FAISS can only nearest neighbor search returning the ID of the vector, very fast.
In Vespa, combine with query filters,
not like the [Open Distro for Elasticsearch k-NN plugin](https://opendistro.github.io/for-elasticsearch-docs/docs/knn/)
that does post-processing step after retrieving the nearest neighbors.
With a restrictive filter, like last day, might end up with zero documents.
Vespa combines ANN search and filters.

Vespa has hybrid evaluation;
Term-at-a-time (TAAT) which is much more cache friendly, and document-at-a-time (DAAT).
Can evaluate part of the query tree using TAAT,
then search in the HNSW graph using the documents eligible as an input filter.
Including a filter makes ANN a bit slower, but the value it adds makes it worth it.

FAISS is faster as it does not have an HTTP api and distribution layer with realtime updates -
FAISS is a library, batch oriented.

Resources: [using-approximate-nearest-neighbor-search-in-real-world-applications](https://blog.vespa.ai/using-approximate-nearest-neighbor-search-in-real-world-applications/),
[approximate nearest neighbor, hnsw](https://docs.vespa.ai/en/approximate-nn-hnsw.html),
[feature tuning](https://docs.vespa.ai/en/performance/feature-tuning.html)


<hr/>


**Since Vespa has a different approach, is there anything Vespa is learning from Elastic/Solr/Lucene?
Also the other way around, Elastic/Solr learning from Vespa?**

[ [quicklink](https://youtu.be/SzZ_A9G6PMY?t=3822)].
Both are great engines! Vespa's toolbox is bigger.
Learned how Elasticsearch became popular:
developer friendliness, nice APIs, great support for analytics, great for handling immutable data.
Lucene has had a large developer crowd for 20 years.


<hr/>


**If I remember correctly, FAISS or similar libraries support indexing/searching with the power of GPU,
how does this compare to Vespa/Elastic/Solr?**

[ [quicklink](https://youtu.be/SzZ_A9G6PMY?t=4218) ].
Vespa is CPU only, but looking at GPU as pretrained language models grow larger.
GPU easier to use in indexing than serving.
We are trying to find models that run efficiently on GPU. Vespa is written in C++,
making use of OpenBLAS and special instructions to get the most out of CPUs.

Resources: [github.com/vespa-engine/vespa/issues/14406](https://github.com/vespa-engine/vespa/issues/14406) 


<hr/>


**Given large language model dominance, in 5 years, how much do we need to support manual relevance tuning operations?
Should that be our focus? Or will search engines just be initial retrieval before sending docs to eg. BERT?**

[ [quicklink](https://youtu.be/SzZ_A9G6PMY?t=4438) ].
BERT and pretrained language models helps machines understand text better than before,
dramatic progress on ranking, roughly 2x BM25 on multiple Information retrieval datasets.
However more than just text matching and ranking, like click models and site popularity.
In Vespa, ranking with BERT locally on the content nodes,
can combine scoring from language model into LTR framework, taking other signals into account.
There are ways to use BERT that could lead to close to random ranking,
e.g. using BERT as a representation model without fine-tuning for the retrieval task
where there are many many negative (irrelevant) documents.

However, good zero-shot transfer capabilities for interaction based models
has demonstrated strong ranking accuracy on other data sets.
See Pretrained Transformers for Text Ranking: BERT and Beyond.

Resources: [from-research-to-production-scaling-a-state-of-the-art-machine-learning-system](https://blog.vespa.ai/from-research-to-production-scaling-a-state-of-the-art-machine-learning-system/)


<hr/>


**Can you speak about the history of Vespa? All top contributors work at Verizon/Yahoo.
Are you aware of prominent Vespa users beside Verizon? Who's behind Vespa Cloud?
Is there a (larger) ecommerce shop using Vespa in production already?**

[ [quicklink](https://youtu.be/SzZ_A9G6PMY?t=4793) ].
[cloud.vespa.ai](https://cloud.vespa.ai/) is run by Verizon Media.
In Verizon Media, Vespa is used for search and recommendation (including APAC e-commerce) + Gemini ad serving stack.
Vespa’s background is from Fast Search and Transfer, founded in 1997 from NTNU in Trondheim, Norway.

Resources: [vespa.ai](https://vespa.ai/)


<hr/>


**What are your plans for growing your communities?
Where should we go to ask questions and have discussion?**

[ [quicklink](https://youtu.be/SzZ_A9G6PMY?t=5352) ].
[\#vespa on Stack Overflow](https://stackoverflow.com/questions/tagged/vespa),
<a href="https://app.gitter.im/#/room/#vespa-engine_Lobby:gitter.im" data-proofer-ignore>Gitter channel</a>,
\#vespa channel of [Relevance Slack](https://www.opensourceconnections.com/slack).
Asking the extended Vespa team to document use cases / blog posts.

Resources: [docs.vespa.ai](https://docs.vespa.ai/),
[vespa.ai/support](https://vespa.ai/support)


<hr/>


**What type of node? Helps me understand 50k/node number**

Single value update assign of an int field on a c5d.2xlarge, 8 v-cpu, 16GB, 200G SSD. 49K updates/s.


<hr/>


**How does vespa handle search query contain both dense vector + scalar fields?
I.e. internally, it first retrieves top-k doc and then to the filters?**

See the *How does Vespa compare to FAISS?* question above -
filter first, maybe using TAAT for speed, then top-k.
This to ensure low latency and non-empty result sets.


<hr/>


**Which engine supports the usage of KNN clustering together with vector similarity queries?**

Vespa supports approximate nearest neighbor search using HNSW,
but can also be combined with pre-computed KNN clustering
where vectors have been assigned a cluster id at indexing time.
Using the Vespa ranking framework,
one can combine (approximate) nearest neighbor queries with any other computations.
Using tensors and operations on these, custom algorithms can be built.

Resources: [tensor user guide](https://docs.vespa.ai/en/tensor-user-guide.html),
[approximate nearest neighbor HNSW](https://docs.vespa.ai/en/approximate-nn-hnsw.html),
[ranking](https://docs.vespa.ai/en/ranking.html)


<hr/>


**Which engine would you use for real-time systems with emphasis on queries latency?**

The Vespa Team has helped implementation of numerous applications
with millisecond latency requirements and update rates in thousands per second per node in Verizon Media.
When the feed operation is ack'ed, the operation is visible.
There is no index refresh delay or immutable batch indexing
as in engines like Solr or Elasticsearch using the batch oriented Lucene library.
Vespa also allows using multiple searcher threads per query to scale latency versus throughput,
functionality which is not exposed in Solr or Elasticsearch.


<hr/>


**Does Vespa support IBM ICU libraries? (language processing question as well)**

Yes, used in [sorting](https://docs.vespa.ai/en/reference/sorting.html).


<hr/>


**For what kind of problem would you recommend Elastic or Solr for (over Vespa)?**

See the question above for *anything Vespa is learning from Elastic/Solr/Lucene?*

Resources: [vespa-elastic-solr](https://vespa.ai/vespa-elastic-solr)


<hr/>


**Can any of the search engine beat Redis when it comes to read performance? Do we have any benchmarking?**

The Vespa Team has not compared Vespa with Redis, as they are built for different use cases.
Vespa is built for Big Data Serving with distributed computations over large, mutable data sets.
Use Redis for in-memory database, cache, and message broker.


<hr/>


**All 3 search engines rely on OS file caching for read optimizations.
How does that work in kubernetes when multiple processes/pods/containers are racing against each other for that?**

The Vespa Team has not tested specifically for K8s and we would love to learn from the community when tested!
We run multiple Docker multi-process containers on bare-metal and AWS hosts, memory is isolated, but the IO is shared.
We hence monitor IO, but not more than that.


<hr/>


**I’d love to read more about the TAAT/DAAT mix and ANN, I don’t follow that yet.
Any chance you can drop a code link or doc link?**

See [feature-tuning](https://docs.vespa.ai/en/performance/feature-tuning.html).
We will see if we can publish a paper or article on this subject.


<hr/>


**With regard to GPU vs CPU this is also asking "How do you execute code on multi-arch cluster?".
If you’re on K8s, you may just be calling out across the nodes.
Something like the nboost proxy is an interesting example**

Moving computation to where the data lives is the mantra for both Vespa and the Map Reduce paradigm (Hadoop).
This allows scaling latency and throughput without moving data across the wire.
Vespa integrates with many machine learning techniques and allows,
e.g. using the pre-trained language model relevancy score in combination with other core ranking features
like pagerank, quality, freshness, predicted CTR for users given previous context and more.
As mentioned in a different answer,
ranking is not only about the BERT prediction score for real world search use cases.


<hr/>


**Preface, I'm unaware of how much of a leap forward Vespa is.
Is there a point of corpus size or a cost threshold
where you'd have to make the same optimizations that Lucene does,
that directly led to the limitations of its design,
or is just a matter of maturity before a search engine like that takes over all text search?**

Refer to the question on write heavy application above, and the Vespa top three summary.
Vespa is heavily performance-optimized over more than 20 years, while adding features like native tensor support.
The ranking framework enables any computations, including text features.

Resources: [tensor user guide](https://docs.vespa.ai/en/tensor-user-guide.html),
[ranking](https://docs.vespa.ai/en/ranking.html)


<hr/>


**How are these search engines different than Google?**

Google Web Search is built on in-house Google technology. Vespa is open source.
Vespa was originally built for web search on alltheweb.com,
but also enterprise search in various FAST Search & Transfer products.
You can build the serving part of web search using Vespa, the technology is scalable for this.

Resources: [vespa.ai](https://vespa.ai/),
[sizing search](https://docs.vespa.ai/en/performance/sizing-search.html)


<hr/>


**With regards to Vespa, in my opinion, it’s not just documentation,
but also Kibana (makes it easy to play with ES immediately)
and that ES doesn’t make you pay attention to schema up front**

The Vespa Team likes Kibana a lot, and we would really appreciate contributions to integrate Kibana with Vespa.
The visualizations are great!

As Vespa is built for Big Data Serving,
we find that our users are very concerned with designing the best performing schema.
We also recognize that having safe features for evolving the schema
(add fields, automatic reindexing, etc) is really important to maintain service availability -
no need to spin another instance to innovate on the app and schema!
Invalid schema changes are stopped in deployment, before hitting the serving nodes.
But we realize this is a tradeoff, the no-schema feature is great for simple experiments.

Please see the Elasticsearch migration guide for how to get started with Vespa schema auto-generation
from an Elasticsearch instance.

Resources: [schemas](https://docs.vespa.ai/en/schemas.html),
[migrating-from-elastic-search-to-vespa](https://vespa.ai/migrating-from-elastic-search-to-vespa),
[reindexing](https://docs.vespa.ai/en/reindexing.html)

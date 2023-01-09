--- 
layout: post 
title: "Improving Zero-Shot Ranking with Vespa Hybrid Search - part two"
author: jobergum 
date: '2023-01-09' 
image: assets/2023-01-10-improving-zero-shot-ranking-with-vespa-part-two/tamarcus-brown-YWI8pZdcuAA-unsplash.jpg
skipimage: true 
tags: [] 
excerpt: Where should you begin if you plan to implement search functionality but have not yet collected data from user interactions to train ranking models?
---

![Decorative
image](/assets/2023-01-10-improving-zero-shot-ranking-with-vespa-part-two/tamarcus-brown-YWI8pZdcuAA-unsplash.jpg)
<p class="image-credit">
Photo by <a href="https://unsplash.com/@tamarcusbrown?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Tamarcus Brown</a> 
on <a href="https://unsplash.com/photos/YWI8pZdcuAA?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
   </p>
_Where should you begin if you plan to implement search functionality
but have not yet [collected data from user
interactions](https://blog.vespa.ai/the-big-data-maturity-levels/) to
train ranking models?_

In the [first
post](https://blog.vespa.ai/improving-zero-shot-ranking-with-vespa/) in
the series, we introduced the difference between in-domain and
out-of-domain (zero-shot) ranking. We also presented the BEIR
benchmark and highlighted cases where in-domain effectiveness does
not transfer to another domain in a zero-shot setting.

In this second post in this series, we introduce and evaluate three
different Vespa ranking methods on the
[BEIR](https://github.com/beir-cellar/beir) benchmark in a zero-shot
setting. We establish a new and strong BM25 baseline for the BEIR
dataset, which outperforms previously reported BM25 results. We
then show how a unique hybrid approach, combining a neural ranking
method with BM25, outperforms other evaluated methods on 12 out of
13 datasets on the BEIR benchmark. We also compare the effectiveness
of the hybrid ranking method with emerging few-shot methods that
generate in-domain synthetic training data via prompting large
language models (LLMs).


## Establishing a strong baseline
In the [BEIR paper](https://openreview.net/forum?id=wCu6T5xFjeJ),
the authors find that [BM25](https://docs.vespa.ai/en/reference/bm25.html)
is a strong generalizable baseline text ranking model. Many, if not
most, of the dense single vector embedding models trained on MS
MARCO labels are outperformed by BM25 in an out-of-domain setting.
Quote from [BEIR: A Heterogeneous Benchmark for Zero-shot Evaluation
of Information Retrieval
Models](https://openreview.net/forum?id=wCu6T5xFjeJ):

>In-domain performance is not a good indicator for out-of-domain
generalization. We observe that BM25 heavily underperforms neural
approaches by 7-18 points on in-domain MS MARCO. However, BEIR
reveals it to be a strong baseline for generalization and generally
outperforming many other, more complex approaches. **This stresses
the point, that retrieval methods must be evaluated on a broad range
of datasets**.

What is interesting about reporting BM25 baselines is that there
are multiple implementations, variants, and performance tweaks, as
demonstrated in [Which BM25 Do You Mean? A Large-Scale Reproducibility
Study of Scoring
Variants](https://link.springer.com/chapter/10.1007/978-3-030-45442-5_4).
Unfortunately, various papers have reported conflicting results for BM25 on 
the same BEIR benchmark datasets. The BM25 effectiveness can vary due to different
hyperparameters and different linguistic processing methods used in different system implementations,
such as removing stop words, stemming, and tokenization. Furthermore, researchers want to contrast their proposed ranking
approach with a baseline ranking method. It could be tempting to
report a weak BM25 baseline, which makes the proposed ranking method
stand out better.

Several serving systems implement BM25 scoring, including Vespa.
Vespa’s lexical or sparse retrieval is also [accelerated using the
weakAnd Vespa query
operator](https://docs.vespa.ai/en/using-wand-with-vespa.html).
This is important because implementing a BM25 scoring function in
a system is trivial, but scoring all documents that contains at
least one of the query terms approaches linear complexity. Dynamic
pruning algorithms like `weakAnd` improve the 
retrieval efficiency significantly compared to naive
brute-force implementations that scores all documents matching any of the query terms.

[BM25](https://docs.vespa.ai/en/reference/bm25.html) has two
hyperparameters, `k1` and `b`, which impact ranking effectiveness.
Additionally, most (14 out of 18) of the BEIR datasets have both
title and text document fields, which in a real-production environment
would be the first thing that a seasoned search practitioner would
tune the relative importance of. In our BM25 baseline, 
we configure Vespa to independently calculate the
[BM25](https://docs.vespa.ai/en/reference/bm25.html) score of both
title and text, and we combine the two BM25 scores
linearly. The complete [Vespa rank
profile](https://docs.vespa.ai/en/ranking.html) is given below.

<pre>
rank-profile bm25 inherits default {
   first-phase {
      expression: bm25(title) + bm25(text)
   }
   rank-properties {
      bm25(title).k1: 0.9
      bm25(title).b: 0.4
      bm25(text).k1: 0.9
      bm25(text).b: 0.4
   }
}
</pre>

We modify the BM25 `k1` and `b` parameters but use the same parameters for
both fields. The values align with [Anserini
defaults](https://github.com/castorini/anserini/blob/master/docs/experiments-msmarco-passage.md#bm25-tuning)
(k1=0.9, b=0.4).

The following table reports `nDCG@10` scores on a subset (13) of the
BEIR benchmark datasets. We exclude the four datasets that are not
publicly available. We also exclude the BEIR CQADupStack dataset
because it consists of 12 sub-datasets where the overall `nDCG@10`
score is found by [averaging each
](https://github.com/beir-cellar/beir/issues/9#issuecomment-842147129)sub-dataset's
`nDCG@10` score. Adding these sub-datasets would significantly increase
the evaluation effort.

<style>
  table, th, td {
    border: 1px solid black;
  }
  th, td {
    padding: 5px;
  }
</style>

<table>
  <tr>
   <td><strong>BEIR Dataset</strong> </td> <td><strong>BM25 from
   BEIR Paper</strong> </td> <td><strong>Vespa BM25</strong> </td>
  </tr> <tr>
   <td>MS MARCO </td> <td>0.228 </td> <td>0.228 </td>
  </tr> <tr>
   <td>TREC-COVID </td> <td>0.656 </td> <td>0.690 </td>
  </tr> <tr>
   <td>NFCorpus </td> <td>0.325 </td> <td>0.313 </td>
  </tr> <tr>
   <td>Natural Questions (NQ) </td> <td>0.329 </td> <td>0.327 </td>
  </tr> <tr>
   <td>HotpotQA </td> <td>0.603 </td> <td>0.623 </td>
  </tr> <tr>
   <td>FiQA-2018 </td> <td>0.236 </td> <td>0.244 </td>
  </tr> <tr>
   <td>ArguAna </td> <td>0.315 </td> <td>0.393 </td>
  </tr> <tr>
   <td>Touché-2020 (V2) </td> <td>0.367 </td> <td>0.413 </td>
  </tr> <tr>
   <td>Quora </td> <td>0.789 </td> <td>0.761 </td>
  </tr> <tr>
   <td>DBPedia </td> <td>0.313 </td> <td>0.327 </td>
  </tr> <tr>
   <td>SCIDOCS </td> <td>0.158 </td> <td>0.160 </td>
  </tr> <tr>
   <td>FEVER </td> <td>0.753 </td> <td>0.751 </td>
  </tr> <tr>
   <td>CLIMATE-FEVER </td> <td>0.213 </td> <td>0.207 </td>
  </tr> <tr>
   <td>SciFact </td> <td>0.665 </td> <td>0.673 </td>
  </tr> <tr>
   <td><strong>Average (excluding MS MARCO)</strong> </td> <td>0.440
   </td> <td>0.453 </td>
  </tr>
</table>
_The table summarizes the BM25 nDCG@10 results. Vespa BM25 versus 
BM25 from [BEIR paper](https://openreview.net/forum?id=wCu6T5xFjeJ)._

The table above demonstrates that the Vespa implementation has set a new high
standard, outperforming reported BM25 baselines on the BEIR benchmark.

## Evaluating Vespa ranking models in a zero-shot setting
With the new strong BM25 baseline established in the above section, we 
will now introduce two neural ranking models and compare their performance with the baseline.

### Vespa ColBERT
We have previously described the Vespa ColBERT implementation in
this [blog
post](https://blog.vespa.ai/pretrained-transformer-language-models-for-search-part-3/),
and we use the same [model
weights](https://huggingface.co/vespa-engine/col-minilm) in this
work. The Vespa ColBERT model is based on a distilled 6-layer MiniLM
model with 22M parameters, using quantized `int8` weights (post-training
quantization). The model uses only 32 vector dimensions per query
and document [wordpiece](https://huggingface.co/course/chapter6/6?fw=pt)), 
in contrast to the original ColBERT model, which
uses 128 dimensions. Furthermore, we use Vespa’s support for
[bfloat16](https://docs.vespa.ai/en/reference/tensor.html#tensor-type-spec)
to reduce the per-dimension storage usage from 4 bytes per dimension
with `float` to 2 bytes with `bfloat16`. We configure the maximum query
length to 32 [wordpieces](https://huggingface.co/course/chapter6/6?fw=pt), and maximum document length to 180
wordpieces. Both maximum length parameters align with the training and experiments
on MS MARCO.

The ColBERT MaxSim scoring is implemented as a re-ranking model
using Vespa [phased ranking](https://docs.vespa.ai/en/phased-ranking.html),
re-ranking the top 2K hits ranked by BM25. We also compute and store
the title term embeddings for datasets with titles, meaning we have
two MaxSim scores for datasets with titles. We use a linear combination
to combine the title and text MaxSim scores.

The complete [Vespa rank profile](https://docs.vespa.ai/en/ranking.html)
is given below.

<pre>
rank-profile colbert inherits bm25 {
   inputs {
      query(qt) tensor&lt;float&gt;(qt{}, x[32])
      query(title_weight): 0.5
   }
   second-phase {
      rerank-count: 2000
	   expression {
	   (1 - query(title_weight))* sum(
	    reduce(
	      sum(
		      query(qt) * cell_cast(attribute(dt), float), x
	      ),
	      max, dt
	    ),
	    qt
	   ) +
	   query(title_weight) * sum(
	    reduce(
	      sum(
		      query(qt) * cell_cast(attribute(title_dt), float), x
	      ),
	      max, dt
	    ),
	    qt
	  )
	}
}
</pre>

The per wordpiece ColBERT vectors are stored in Vespa using Vespa’s
support for storing and computing over[
tensors](https://docs.vespa.ai/en/tensor-user-guide.html). 

**Note**: Users
can also trade efficiency versus cost by storing the tensors on
disk, or in-memory using
[paging](https://docs.vespa.ai/en/attributes.html#paged-attributes)
options. Paging is highly efficient in a re-ranking pipeline, as
just a few K tensors values are potentially paged on-demand.


### Vespa Hybrid ColBERT + BM25
There are several ways to combine the ColBERT MaxSim with BM25,
including [reciprocal rank
fusion](https://plg.uwaterloo.ca/~gvcormac/cormacksigir09-rrf.pdf)(RRF)
which does not consider model scores, just the ordering (ranking) the
scores produce. Quote from [Reciprocal Rank Fusion outperforms Condorcet and
individual Rank Learning Methods](https://plg.uwaterloo.ca/~gvcormac/cormacksigir09-rrf.pdf):

>RRF is simpler and more effective than Condorcet Fuse, while sharing
the valuable property that it combines ranks without regard to the
arbitrary scores returned by particular ranking methods_

Another approach is to combine the model scores into a new score
to produce a new ranking. We use a linear combination in this work
to compute the hybrid score. Like the ColBERT-only model, we use
BM25 as the first-phase ranking model and only calculate the hybrid
score for the global top-ranking K documents from the BM25 model.

Before combining the scores, we want to normalize both the unbound
BM25 and the bound ColBERT score. Normalization is accomplished by
simple [max-min](https://en.wikipedia.org/wiki/Feature_scaling)
scaling of the scores. With max-min scaling, scores from any ranking
model are scaled from 0 to 1. This makes it easier to combine the
two using relative weighting.

Since scoring in a production serving system might be spread across
multiple nodes, each node involved in the query will not know the
**global** max scores. We solve this problem by letting Vespa content
nodes involved in the query return both scores using Vespa
[match-features](https://docs.vespa.ai/en/reference/schema-reference.html#match-features).

A [custom searcher](https://docs.vespa.ai/en/searcher-development.html)
is injected in the query dispatching stateless Vespa service. This
searcher calculates the max and min for both model scores using
match features for hits within the window of global top-k hits
ranked by BM25. As with the ColBERT rank profile, we use a re-ranking
window of 2000 hits, but we perform feature-score scaling and
re-ranking in a stateless custom searcher instead of on the content
nodes.

The complete Vespa rank profile is given below. Notice the
`match-features`, which are returned with each hit to the stateless
searcher
([implementation](https://github.com/vespa-cloud/cord-19-search/blob/main/src/main/java/ai/vespa/example/cord19/searcher/HybridSearcher.java)),
which performs the normalization and re-scoring. The first-phase
scoring function is inherited from the previously described bm25
rank profile.
<pre>
rank-profile hybrid-colbert inherits bm25 {
   function bm25() {
	   expression: bm25(title) + bm25(text)
   }

   function colbert_maxsim() {
	   expression {
	      2*sum(
	         reduce(
	            sum(
		            query(qt) * cell_cast(attribute(dt), float) , x
	            ),
	         max, dt
	         ),
	         qt
	      ) +
	      sum(
	         reduce(
	            sum(
		            query(qt) * cell_cast(attribute(title_dt), float), x
	            ),
	         max, dt
	         ),
	         qt
	      )
      }
   }
   match-features {
	   bm25
	   colbert_maxsim
   }
}
</pre>

## ​​Results and analysis
As with the BM25 baseline model, we index one of the BEIR datasets
at a time on a Vespa instance and evaluate the models. The following
table summarizes the results. All numbers are `nDCG@10`. The
best-performing model score per dataset is in **bold**.

<table>
  <tr>
   <td><strong>BEIR Dataset</strong> </td> <td><strong>Vespa
   BM25</strong> </td> <td><strong>Vespa ColBERT</strong> </td>
   <td><strong>Vespa Hybrid</strong> </td>
  </tr> <tr>
   <td>MS MARCO (<i>in-domain</i>) </td> <td>0.228 </td> <td><strong>0.401
   </strong> </td> <td>0.344 </td>
  </tr> <tr>
   <td>TREC-COVID </td> <td>0.690 </td> <td>0.658 </td>
   <td><strong>0.750</strong> </td>
  </tr> <tr>
   <td>NFCorpus </td> <td>0.313 </td> <td>0.304 </td>
   <td><strong>0.350</strong> </td>
  </tr> <tr>
   <td>Natural Questions (NQ) </td> <td>0.327 </td> <td>0.403 </td>
   <td><strong>0.404</strong> </td>
  </tr> <tr>
   <td>HotpotQA </td> <td>0.623 </td> <td>0.298 </td>
   <td><strong>0.632</strong> </td>
  </tr> <tr>
   <td>FiQA-2018 </td> <td>0.244 </td> <td>0.252 </td>
   <td><strong>0.292</strong> </td>
  </tr> <tr>
   <td>ArguAna </td> <td>0.393 </td> <td>0.286 </td>
   <td><strong>0.404</strong> </td>
  </tr> <tr>
   <td>Touché-2020 (V2) </td> <td>0.413 </td> <td>0.315 </td>
   <td><strong>0.415</strong> </td>
  </tr> <tr>
   <td>Quora </td> <td>0.761 </td> <td>0.817 </td>
   <td><strong>0.826</strong> </td>
  </tr> <tr>
   <td>DBPedia </td> <td>0.327 </td> <td>0.281 </td>
   <td><strong>0.365</strong> </td>
  </tr> <tr>
   <td>SCIDOCS </td> <td>0.160 </td> <td>0.107 </td>
   <td><strong>0.161</strong> </td>
  </tr> <tr>
   <td>FEVER </td> <td>0.751 </td> <td>0.534 </td>
   <td><strong>0.779</strong> </td>
  </tr> <tr>
   <td>CLIMATE-FEVER </td> <td><strong>0.207</strong> </td> <td>0.067
   </td> <td>0.191 </td>
  </tr> <tr>
   <td>SciFact </td> <td>0.673 </td> <td>0.403 </td>
   <td><strong>0.679</strong> </td>
  </tr> <tr>
   <td><strong>Average nDCG@10 (excluding MS MARCO)</strong> </td>
   <td>0.453 </td> <td>0.363 </td> <td><strong>0.481</strong> </td>
  </tr>
</table>
_The table summarizes the nDCG@10 results per dataset. Note that MS MARCO is in-domain for ColBERT and Hybrid.
Average `nDCG@10` is only computed for zero-shot and out-of-domain datasets._

As shown in the table above, in a in-domain setting on MS MARCO, 
the Vespa ColBERT model outperforms the BM25
baseline significantly. The resulting `nDCG@10` score aligns with reported `MRR@10`
results from [previous work using
ColBERT](https://blog.vespa.ai/pretrained-transformer-language-models-for-search-part-3/)
in-domain on MS MARCO. However, mixing the baseline BM25 using the hybrid model on MS MARCO evaluation
hurts the `nDCG@10` score, as we combine two models where the unsupervised BM25
model is significantly weaker than the ColBERT model.

The Vespa ColBERT model underperforms BM25 on out-of-domain datasets,
especially CLIMATE-FEVER. The CLIMATE-FEVER dataset has very long
queries (avg 20.2 words). The long questions challenge the ColBERT
model, configured with a max query length of 32 wordpieces in the
experimental setup. Additionally, the Vespa ColBERT model underperforms
reported results for the [full-sized ColBERT
V2](https://arxiv.org/abs/2112.01488) model using 110M parameters
and 128 dimensions. This result could indicate that the compressed
(in the number of dimensions) and model distillation have a more
significant negative impact when applied in a zero-shot setting
compared to in-domain.

These exceptions aside, the data shows that the unique hybrid Vespa ColBERT and BM25 combination **is highly
effective, performing the best on 12 of 13 datasets**. Its average
`nDCG@10` score improves from 0.453 to 0.481 compared to the strong
Vespa BM25 baseline. 

To reproduce the results of this benchmark,
follow the open-sourced
[instructions](https://github.com/vespa-cloud/cord-19-search/blob/main/beir.md).

## Comparing hybrid zero-shot with few-shot methods
To compare the hybrid Vespa ranking performance with other models,
we include the results reported in [Promptagator: Few-shot Dense
Retrieval From 8 Examples](https://arxiv.org/abs/2209.11755) from
Google Research.

Generating synthetic training data in-domain via prompting LLMs is a recent
emerging Information Retrieval(IR) trend also described in 
[InPars: Data Augmentation for Information Retrieval using Large Language
Models](https://arxiv.org/abs/2202.05144). 

The basic idea is to "prompt" a large language model (LLM) to generate synthetic queries
for use in training of in-domain ranking models. A typical prompt include a few
examples of queries and relevant documents, then the LLM is “asked”
to generate syntetic queries for many of the documents in the corpus. 
The generated syntetic query, document pairs can be used to train neural ranking models. 
We include a quote describing the approach from the Promptagator paper:

>Running the prompt on all documents from DT, we can create a large
set of synthetic (q, d) examples, amplifying the information from
few examples into a large synthetic dataset whose query distribution
is similar to true task distribution QT and query-document pairs
convey the true search intent IT. We use FLAN (Wei et al., 2022a)
as the LLM for query generation in this work. FLAN is trained on a
collection of tasks described via instructions and was shown to
have good zero/few-shot performance on unseen tasks. We use the
137B FLAN checkpoint provided by the authors.

The Promptagator authors report results on a different subset of
the BEIR datasets (excluding Quora and Natural Questions). In the following
table we compare their reported results on the same BEIR datasets used
in this work. We also include the most effective single-vector representation model (TAS-B) from the BEIR
benchmark (zero-shot).

<table>
  <tr>
   <td><strong>BEIR Dataset</strong> </td> <td><strong>Vespa
   BM25</strong> </td> <td><strong>Vespa Hybrid</strong> </td>
   <td><strong>TAS-B (dense)</strong> </td> <td><strong>PROMPTAGATOR
   few-shot (dense)</strong> </td> <td><strong>PROMPTAGATOR few-shot
   (cross-encoder)</strong> </td>
  </tr> <tr>
   <td>TREC-COVID </td> <td><p style="text-align: right">
0.690</p>

   </td> <td><p style="text-align: right">
0.750</p>

   </td> <td><p style="text-align: right">
0.481</p>

   </td> <td><p style="text-align: right">
0.756</p>

   </td> <td><p style="text-align: right">
0.762</p>

   </td>
  </tr> <tr>
   <td>NFCorpus </td> <td><p style="text-align: right">
0.313</p>

   </td> <td><p style="text-align: right">
0.350</p>

   </td> <td><p style="text-align: right">
0.319</p>

   </td> <td><p style="text-align: right">
0.334</p>

   </td> <td><p style="text-align: right">
0.37</p>

   </td>
  </tr> <tr>
   <td>HotpotQA </td> <td><p style="text-align: right">
0.623</p>

   </td> <td><p style="text-align: right">
0.632</p>

   </td> <td><p style="text-align: right">
0.584</p>

   </td> <td><p style="text-align: right">
0.614</p>

   </td> <td><p style="text-align: right">
0.736</p>

   </td>
  </tr> <tr>
   <td>FiQA-2018 </td> <td><p style="text-align: right">
0.244</p>

   </td> <td><p style="text-align: right">
0.292</p>

   </td> <td><p style="text-align: right">
0.300</p>

   </td> <td><p style="text-align: right">
0.462</p>

   </td> <td><p style="text-align: right">
0.494</p>

   </td>
  </tr> <tr>
   <td>ArguAna </td> <td><p style="text-align: right">
0.393</p>

   </td> <td><p style="text-align: right">
0.404</p>

   </td> <td><p style="text-align: right">
0.429</p>

   </td> <td><p style="text-align: right">
0.594</p>

   </td> <td><p style="text-align: right">
0.63</p>

   </td>
  </tr> <tr>
   <td>Touché-2020 (V2) </td> <td><p style="text-align: right">
0.413</p>

   </td> <td><p style="text-align: right">
0.415</p>

   </td> <td><p style="text-align: right">
0.173</p>

   </td> <td><p style="text-align: right">
0.345</p>

   </td> <td><p style="text-align: right">
0.381</p>

   </td>
  </tr> <tr>
   <td>DBPedia </td> <td><p style="text-align: right">
0.327</p>

   </td> <td><p style="text-align: right">
0.365</p>

   </td> <td><p style="text-align: right">
0.384</p>

   </td> <td><p style="text-align: right">
0.38</p>

   </td> <td><p style="text-align: right">
0.434</p>

   </td>
  </tr> <tr>
   <td>SCIDOCS </td> <td><p style="text-align: right">
0.160</p>

   </td> <td><p style="text-align: right">
0.161</p>

   </td> <td><p style="text-align: right">
0.149</p>

   </td> <td><p style="text-align: right">
0.184</p>

   </td> <td><p style="text-align: right">
0.201</p>

   </td>
  </tr> <tr>
   <td>FEVER </td> <td><p style="text-align: right">
0.751</p>

   </td> <td><p style="text-align: right">
0.779</p>

   </td> <td><p style="text-align: right">
0.700</p>

   </td> <td><p style="text-align: right">
0.77</p>

   </td> <td><p style="text-align: right">
0.868</p>

   </td>
  </tr> <tr>
   <td>CLIMATE-FEVER </td> <td><p style="text-align: right">
0.207</p>

   </td> <td><p style="text-align: right">
0.191</p>

   </td> <td><p style="text-align: right">
0.228</p>

   </td> <td><p style="text-align: right">
0.168</p>

   </td> <td><p style="text-align: right">
0.203</p>

   </td>
  </tr> <tr>
   <td>SciFact </td> <td><p style="text-align: right">
0.673</p>

   </td> <td><p style="text-align: right">
0.679</p>

   </td> <td><p style="text-align: right">
0.643</p>

   </td> <td><p style="text-align: right">
0.65</p>

   </td> <td><p style="text-align: right">
0.731</p>

   </td>
  </tr> <tr>
   <td><strong>Average nDCG@10</strong> </td> <td><p style="text-align:
   right">
0.436</p>

   </td> <td><p style="text-align: right">
0.456</p>

   </td> <td><p style="text-align: right">
0.399</p>

   </td> <td><p style="text-align: right">
0.478</p>

   </td> <td><p style="text-align: right">
0.528</p>

   </td>
  </tr>
</table>
_Vespa ranking model comparison with few-shot models and singe-vector TAS-B (zero-shot). 
The PROMPTAGATOR results are from table 2 in the paper._

The dense
[TAS-B](https://huggingface.co/sebastian-hofstaetter/distilbert-dot-tas_b-b256-msmarco)
model underperforms both the BM25 baseline and the hybrid model.
This result is in line with other dense models trained on MS MARCO;
dense single-vector representation models struggle with generalization in new domains.

The `PROMPTAGATOR` single-vector representation model (110M parameter)
performs better than the zero-shot Vespa hybrid model.
Still, given that it has performed in-domain adoption, we don’t
think the difference is that significant (0.456 versus 0.478). 
Furthermore, we could also adapt the hybrid model on a per-dataset
basis, for example, by adjusting the relative importance of the
title and text fields. Interestingly, `PROMPTGATOR` reports a BM25 baseline
`nDCG@10` score of 0.418 across these datasets, which is considerably
weaker than the strong Vespa BM25 baseline of 0.436.

We also include the `PROMPTGATOR` re-ranking model, a cross-encoder
model with another 110M parameters, to re-rank the top-200 results
from the retriever model. This model outperforms all other methods
described in this blog post series. 

There is also exciting work ([InPars
v2](https://arxiv.org/abs/2301.01820)) using LLMs to generate synthetic
training data that report strong cross-encoder model results on
BEIR, but with models of up to 3B parameters, which makes it impractical and costly
in production use cases.

Cross-encoder models can only be deployed as a
re-ranking phase as they input both the query and the document and
is more computationally intensive than other methods presented in this
blog post. Nevertheless, the computationally inexpensive Vespa
hybrid model could be used as a first-phase retriever for cross-encoder
models. We described cross-encoder models in Vespa in part four
in our [Pretrained Transformer 
Language Models for Search](https://blog.vespa.ai/pretrained-transformer-language-models-for-search-part-4/)
blog post series.

## Deploying hybrid ranking models to production
We’ve made everything you need to deploy this solution available.

This research, evaluating Vespa zero-shot models on BEIR began
with [COVID-19 Open Research Dataset
(CORD-19)](https://github.com/allenai/cord19). We have indexed the complete, final
version of the CORD-19 dataset on
[https://cord19.vespa.ai/](https://cord19.vespa.ai/). You
can select between all three ranking models described in this blog
post. The demo search also includes result facets, result pagination,
result snippets, and highlighting of matched query terms. 
Essentially, everything you [expect from a search
engine implementation](https://blog.vespa.ai/will-vector-dbs-dislodge-search-engines/).

The Vespa [app is
open-source](https://github.com/vespa-cloud/cord-19-search) and
deployed on [Vespa Cloud](https://cloud.vespa.ai/), and the app can
also be run locally using the open-source Vespa container image.
The Vespa ColBERT model is CPU-friendly and does not require expensive
GPU/TPU acceleration to meet user-serving latency requirements. The
end-to-end retrieval and ranking pipeline, including query encoding,
retrieval, and re-ranking, takes less than 60 ms.

## Summary
In this blog post in a series on zero-shot ranking, we established
a strong BM25 baseline on multiple BEIR datasets, improving over
previously reported results. We believe that without a strong BM25
baseline model, we can overestimate the neural ranking progress,
especially in a zero-shot setting where neural single vector
representations struggle with generalization.

We then introduced a unique hybrid ranking model, combining ColBERT with
BM25 and setting a new high bar for efficient and effective zero-shot
ranking. We also compared this unique model's effectiveness with much larger models
that use few-shot in-domain adoption techniques involving billion-sized LLMs.

Importantly, all the results presented in this blog post are easily
[reproduced](https://github.com/vespa-cloud/cord-19-search/blob/main/beir.md)
using the open-sourced [Vespa
app](https://github.com/vespa-cloud/cord-19-search/), which is
deployed to production and available at
[https://cord19.vespa.ai/](https://cord19.vespa.ai/). 

For those interested in learning more about hybrid search in a zero-shot
setting, we highly recommend two Vespa related talks presented at [Berlin Buzzwords
2022](https://blog.vespa.ai/vespa-at-berlin-buzzwords/).
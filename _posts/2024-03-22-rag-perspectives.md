---  
layout: post
title: "Perspectives on R in RAG"
author: jobergum
date: '2024-03-22'
image: assets/2024-03-22-rag-perspectives/anika-huizinga-RmzR87vTiYw-unsplash.jpg
skipimage: false
image_credit: 'Photo by <a href="https://unsplash.com/@iam_anih?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Anika Huizinga</a> on <a href="https://unsplash.com/photos/selective-focus-photography-of-woman-holding-clear-glass-ball-RmzR87vTiYw?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Unsplash</a>'
excerpt: "In this blog post, I share perspectives on the R in RAG."

---

Retrieval-augmented generation (RAG) has led to a surge in the
number of developers interested in working on retrieval. In this
blog post, I share perspectives providing insights and perspectives
on the R in RAG.


## The case for hybrid search and ranking

Hybrid retrieval and ranking pipelines allow you to combine signals
from unsupervised methods (such as BM25) with supervised methods
(such as neural rankers). By combining unsupervised and supervised
techniques,[ we have shown that ranking
accuracy](https://blog.vespa.ai/improving-zero-shot-ranking-with-vespa/)
increases compared to using either method independently.  The rise
in popularity of hybrid models can be attributed to the lack of the
necessary tools, data,  time and resources to fine-tune text embedding
models specifically for their retrieval tasks. Extensive research
and experimentation have shown that hybrid ranking outperforms
either method when used alone in a new setting or a new domain with
slightly different texts than what the model was trained on.

What is often overlooked in this hybrid search discussion is the
ability to perform standard full-text-search (FTS) functionality
like exact and phrase matching. Text embedding models are limited
by their fixed vocabulary, leading to poor search results for unseen
words not in the vocabulary. This is particularly evident in cases
such as searching for a product identifier, a phone number, a zip
code, or a code snippet, where text embedding models with fixed
vocabularies fail. For example, if we look at BERT, one of the most
popular language models, its default vocabulary does not include
the word 2024.

```python
>>>from transformers import AutoTokenizer
>>>tokenizer = AutoTokenizer.from_pretrained("bert-base-uncased")

>>>tokenizer.tokenize("2024")
['202', '##4']

>>>tokenizer.encode("2024", add_special_tokens=False)
[16798, 2549]

>>>tokenizer.tokenize("90210")
['90', '##21', '##0']
[3938, 17465, 2692]

```

Examples of language model tokenization, mapping free text to the
fixed vocabulary where there exist token vectors (that are injected
into the deep neural transformer network). We can highly recommend
[this video tutorial](https://www.youtube.com/watch?v=zduSFxRajkE)
for understanding tokenization of texts for language models.


In real-world RAG applications, these search cases are essential.
However, the relevancy datasets used to evaluate retrieval and
ranking techniques often lack queries of these types. Consequently,
when comparing and evaluating retrieval methods on various benchmarks,
we only consider limited types of search use cases.

As more developers address retrieval challenges in the context of
RAG, it's important to remember that text embedding models alone
cannot handle simple table stakes search issues.


## Multilingual text processing in full-text search

Different languages have unique characteristics that require specific
approaches to tokenization, stemming and normalization. BM25 is
suitable for multilingual settings, but it requires attention to
diverse languages, character sets and language-specific features.

Tokenization splits text into tokens like words or subwords. It
should consider language-specific traits.

Normalization often includes converting text to a consistent case,
such as lowercase or uppercase, to eliminate case-sensitive variations.
A fun-fact in this respect is that many multilingual text embedding
models are built on multilingual tokenizer vocabularies which are
case sensitive. That means that the vector representation of “Can”
is different from “can”.

```python
>>> from transformers import AutoTokenizer
>>> tokenizer = AutoTokenizer.from_pretrained("intfloat/multilingual-e5-large")
>>> tokenizer.tokenize("Can can")
['▁Can', '▁can']
>>> tokenizer.encode("Can can", add_special_tokens=False)
[4171, 831]
```

These mentioned search text processing techniques have an influence
on the shape of the recall and precision curve. In scenarios where
high recall is crucial, such as text search, it is generally
undesirable for casing to be a decisive factor. However, in other
contexts, preserving case may be necessary, especially when
distinguishing named entities from other text components.

Vespa as a flexible text search platform integrates[ linguistic
processing](https://docs.vespa.ai/en/linguistics.html) components
(Apache OpenNLP, [Apache
Lucene](https://docs.vespa.ai/en/lucene-linguistics.html)) which
provides text processing capabilities for more than 40 languages.
Plus, you can roll your own custom linguistic implementation. In
addition to the linguistic text processing capabilities, Vespa
offers a wide range of [matching
capabilities](https://docs.vespa.ai/en/reference/schema-reference.html#match)
like prefix, fuzzy, exact, case sensitive and n-gram catering for
a wide range of full-text search use cases.


## To chunk or not to chunk

While advancements have introduced LLMs with longer context windows,
text embedding models still face limitations in handling long text
representations and are [outperformed by simple BM25
baselines](https://blog.vespa.ai/announcing-long-context-colbert-in-vespa/)
when used with longer documents. In other words, to produce meaningful
text embedding representations for search, we must split longer
texts into manageable chunks that can be consumed by the text
embedding model.

To address this challenge, developers choosing to work with
single-vector databases like Pinecone, have chunked the document
into independent retrievable units or rows into the database. This
means the original context, the surrounding chunks or other document
level metadata is not preserved unless it’s duplicated into the
chunk-level retrievable row.

Developers using Vespa, the most versatile vector database for RAG,
don't need to segment the original long document into smaller
retrievable units. [Multi-vector
indexing](https://blog.vespa.ai/semantic-search-with-multi-vector-indexing/)
per document prevents losing the original context and provides easy
access to all the chunks from the same document. As a result,
developers [can retrieve entire documents, not individual
chunks](https://blog.vespa.ai/scaling-large-vector-datasets-with-cohere-binary-embeddings-and-vespa/).

Another advantage of this representation is that it retains the
complete context of the document including metadata. This allows
us to employ hybrid retrieval and ranking, which combines signals
from both the document level and the chunk level. This technique
can be used for candidate retrieval, where relevant documents are
identified based on the entire context. The chunk level text embedding
representations can then be used to further refine or re-rank the
results. Additionally, in the final step of a RAG pipeline, including
adjacent chunks or even all the chunks of the document becomes
straightforward, provided that the generative model supports a long
context window.


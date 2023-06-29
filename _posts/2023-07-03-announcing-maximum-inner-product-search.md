---  
layout: post 
title: "Announcing Maximum Inner Product Search"
author: arnej geirst
date: '2023-07-03' 
image: assets/2023-07-03-announcing-maximum-inner-product-search/nicole-avagliano-TeLjs2pL5fA-unsplash.jpg
skipimage: true 
tags: [] 
excerpt: "Vespa can now solve Maximum Inner Product Search problems using an internal transformation to a Nearest Neighbor search.
This is enabled by the new dotproduct distance metric."
---

![Decorative
image](/assets/2023-07-03-announcing-maximum-inner-product-search/nicole-avagliano-TeLjs2pL5fA-unsplash.jpg)
<p class="image-credit">Photo by <a href="https://unsplash.com/@nicolescapturedmoments?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Nicole Avagliano</a> on <a href="https://unsplash.com/photos/TeLjs2pL5fA?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
</p>

We are pleased to announce Vespa's new feature to solve Maximum Inner Product Search (*MIPS*) problems,
using an internal transformation to a Nearest Neighbor search.
This is enabled by the new [dotproduct](https://docs.vespa.ai/en/reference/schema-reference.html#dotproduct)
distance metric, used for distance calculations and an extension to HNSW index structures. 


## What is MIPS, and why is it useful
The Maximum Inner Product Search (*MIPS*) problem arises naturally in
[recommender systems](https://en.wikipedia.org/wiki/Matrix_factorization_(recommender_systems)),
where item recommendations and user preferences are modeled with vectors,
and the scoring is just the dot product (inner product) between the item vector and the query vector.

In recent years MIPS has seen many new applications in the machine learning community as well:
- [Hierarchical Memory Networks](https://arxiv.org/abs/1605.07427v1)
- [Efficient Natural Language Response Suggestion for Smart Reply](https://arxiv.org/abs/1705.00652)

Many openly available models are trained and targeted for MIPS; for example the
[Cohere Multilingual Embedding Model](https://docs.cohere.com/docs/multilingual-language-models)
was trained using dot product calculations.

The MIPS problem is closely related to a nearest neighbor search (*NNS*) with angular distance metric,
which can use the negative dot product as a distance after normalizing the vectors.
Still, for MIPS we will also give higher scores to vectors with bigger magnitude.
This means nearest neighbor search cannot be used directly for MIPS;
trying to would mean a vector may not be its own closest neighbor,
which usually has catastrophic consequences for NNS index building.

In some cases, pre-normalizing all vectors to the same magnitude is possible, and then MIPS becomes identical to angular distance.
Therefore many NNS implementations offer using the negative or inverse of dot product as a distance,
e.g., NMSLIB has [negdotprod](https://github.com/nmslib/nmslib/blob/master/manual/spaces.md#inner-product-spaces).

Vespa also has this feature as part of its NNS implementation, named
[prenormalized-angular](https://docs.vespa.ai/en/reference/schema-reference.html#prenormalized-angular)
to emphasize that using it requires the data to be normalized before feeding them into Vespa.

But most MIPS use cases really need the true dot product with non-normalized magnitudes,
and Vespa now offers a direct way to handle this.


## How is MIPS solved using nearest neighbor search
We use a transformation first described in 
[Speeding up the Xbox recommender system using a euclidean transformation for inner-product spaces](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/XboxInnerProduct.pdf);
where an extra dimension is added to the vectors.
The value in this dimension is computed based on the maximal norm for all vectors in that dataset
in such a way that distance in the N+1 dimensional space becomes a proxy for the inner-product in the original N dimensions.
A short explanation of the transformation is available at
[towardsdatascience.com](https://towardsdatascience.com/maximum-inner-product-search-using-nearest-neighbor-search-algorithms-c125d24777ef).

![Transformation into 3D hemisphere](/assets/2023-07-03-announcing-maximum-inner-product-search/hemisphere.png "image_tooltip")
<font size="3"><i>Illustration showing how adding an extra dimension transforms points in a 2D plane into points on a 3D hemisphere,
where all vectors have the same magnitude (the radius of the hemisphere).</i></font><br/>

The original transformation described in the research literature assumes the entire dataset is available for pre-processing in batch.
Alternatively, one could set some parameter beforehand (describing the data globally), such as the maximal norm possible for a vector.
With Vespa, we cannot make these assumptions, as we allow our users to start with an empty index and feed in data - often generated
in real-time - so no such a priori knowledge is available.

Therefore Vespa will build the HNSW index incrementally and keep track of the maximal vector norm seen so far.
The extra dimension will be computed on demand to allow this value to change as more data is seen.
In practice, even with a large variation, a good approximation is reached very soon,
and the graph will adapt to the parameter change as it grows.

In practice, the extra dimension value is only needed during indexing (HNSW graph construction).
At query time, we can use the negative of the dot product as the distance directly.
This works because HNSW graph traversal only needs to compare distances to find the smaller ones,
so large negative numbers effectively evaluate as “closer” distances.

However, the transformation means that the nearest neighbor search
isn’t actually measuring any sort of distance seen in the original data.
Because of this we have chosen to give non-standard outputs from the Vespa rank-features
[distance](https://docs.vespa.ai/en/reference/rank-features.html#distance(dimension,name)) and
[closeness](https://docs.vespa.ai/en/reference/rank-features.html#closeness(dimension,name)).
For `distance`, we just return the negative dot product as used by the graph traversal.
For all other [distance metrics](https://docs.vespa.ai/en/reference/schema-reference.html#distance-metric),
the `distance` rank-feature gives a number that is a natural distance measure,
while `closeness` usually gives a normalized number with 1.0 indicating a “perfect match”.
But with MIPS, you can always have a better match, so `closeness` instead just gives the raw dot product,
which can have any value (with larger positive numbers indicating a better hit).


## Recall experiments
We have experimented with the
[Wikipedia simple English](https://huggingface.co/datasets/Cohere/wikipedia-22-12-simple-embeddings) dataset using the
[dotproduct](https://docs.vespa.ai/en/reference/schema-reference.html#dotproduct)
distance metric to see if recall is affected by the order in which the documents are fed to Vespa.
This dataset consists of 485851 paragraphs across 187340 Wikipedia documents,
where each paragraph has a 768-dimensional embedding vector generated by the
[Cohere Multilingual Embedding Model](https://docs.cohere.com/docs/multilingual-language-models).
We used the following schema:

```
schema paragraph {
    document paragraph {
        field id type long {
            indexing: attribute | summary
        }
        field embedding type tensor<float>(x[768]) {
            indexing: attribute | index | summary
            attribute {
                distance-metric: dotproduct
            }
            index {
                hnsw {
                    max-links-per-node: 48
                    neighbors-to-explore-at-insert: 200
                }
            }
        }
    }
    rank-profile default {
        inputs {
            query(paragraph) tensor<float>(x[768])
        }
        first-phase {
            expression: closeness(field,embedding)
        }
    }
    document-summary minimal {
        summary id {}
    }
}
```

We fed 400k paragraph documents in three different orders: random, ascending, and descending (ordered by the embedding vector norm).
We created 10k queries using the
[nearestNeighbor](https://docs.vespa.ai/en/reference/query-language-reference.html#nearestneighbor) query operator with
[targetHits:10](https://docs.vespa.ai/en/reference/query-language-reference.html#targethits)
and query embeddings from the last 10k paragraphs in the dataset.
By running each query with [approximate:true](https://docs.vespa.ai/en/reference/query-language-reference.html#approximate) (ANN with HNSW index)
and `approximate:false` (brute-force full scan), we can compare the results and calculate the recall@10 for ANN.
The recall can be adjusted by increasing
[hnsw.exploreAdditionalHits](https://docs.vespa.ai/en/reference/query-language-reference.html#hnsw-exploreadditionalhits)
to explore more neighbors when searching the HNSW index. The results are summarized in the following table:

<style>
.styled-table {
    font-size: 0.9rem;
    border-collapse: separate;
    padding-top: 0px;
    padding-bottom: 25px;
}
.styled-table td,
.styled-table th {
  padding: 3px;
  padding-left: 30px;
}
</style>

{:.styled-table}

| exploreAdditionalHits | Order: Random | Order: Ascending | Order: Descending |
|-----------------------|---------------|------------------|-------------------|
| 0 | 54.2 | 55.3 | 81.9 |
| 90 | 81.9 | 90.5 | 98.6 |
| 190 | 87.4 | 95.1 | 99.6 |
| 490 | 92.4 | 98.2 | 99.8 |

The best recall is achieved by feeding the document with the largest embedding vector norm first.
This matches the transform and technique used in the research literature.
However, we still achieve good recall in the random order case, which best matches a real-world scenario.
In this case, the maximal vector norm seen so far increases over time,
and the value in the N+1 dimension for a given vector might also change over time.
This can lead to slight variations in distance calculations for a given vector neighborhood based on when the calculations were performed.   

To tune recall for a particular use case and dataset, conduct experiments by adjusting
[HNSW index settings](https://docs.vespa.ai/en/reference/schema-reference.html#index-hnsw) and
[hnsw.exploreAdditionalHits](https://docs.vespa.ai/en/reference/query-language-reference.html#hnsw-exploreadditionalhits).


## Summary
Solving Maximum Inner Product Search (*MIPS*) problems using the new
[dotproduct](https://docs.vespa.ai/en/reference/schema-reference.html#dotproduct)
distance metric and the
[nearestNeighbor](https://docs.vespa.ai/en/reference/query-language-reference.html#nearestneighbor)
query operator is available in Vespa 8.172.18.
Given a vector dataset, no a priori knowledge is needed about the maximal vector norm.
Just feed the dataset as usual, and Vespa will handle the required transformations.

Got questions? Join the Vespa community in [Vespa Slack](http://slack.vespa.ai/).



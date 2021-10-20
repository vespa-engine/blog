---
layout: post
title: "Computing with tensors in Vespa"
date: '2021-09-30'
tags: []
author: lesters
image: assets/2021-09-30-computing-with-tensors/pietro-jeng-n6B49lTx7NM-unsplash.jpg
skipimage: true

excerpt: "In this blog post, we'll explore some of the unique properties of tensors in Vespa."
---

![Decorative image](/assets/2021-09-30-computing-with-tensors/pietro-jeng-n6B49lTx7NM-unsplash.jpg)
<p class="image-credit">
Photo by <a href="https://unsplash.com/@pietrozj?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Pietro Jengr</a> on <a href="https://unsplash.com/photos/n6B49lTx7NM?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
</p>


In computer science, a tensor is a data structure that generalizes scalars,
vectors, matrices, and higher-order structures into a single construct.

In Vespa we have introduced a tensor formalism that differs from what one
usually finds in most modern machine learning frameworks today. The main
differences are:

- Named dimensions
- Unified sparse and dense tensor types
- A small but very powerful set of core functions

In this blog post, we'll explore these and other aspects of tensors in Vespa.
We will also introduce the recently released [tensor
playground](https://docs.vespa.ai/playground/), a tool to get familiar with and
explore tensors and tensor expressions in an interactive environment.


# Tensor representation

Tensors are multi-dimensional arrays of numeric values and can be viewed as a
generalization of vectors and matrices. A tensor with one dimension (a
first-order tensor) is a vector, a two-dimensional (second-order) tensor is a
matrix, and so on. A scalar value is a tensor without any dimensions.

In most frameworks, these dimensions have an implicit ordering. For instance, a
matrix has two dimensions. A multiplication between two matrices, `A` and `B`
with sizes `(i,j)` and `(j,k)`, results in a matrix with size `(i,k)`. Values
along the columns in `A` and the rows in `B` are multiplied and summed.  Thus
these must have equal size.  If not, for instance if `B` had size `(k,j)`, `B`
would need a transpose to `(j,k)` before multiplication.

Implicitly ordered dimensions pose a problem: what do the dimensions represent?
For instance, consider loading a (monochrome) image from a file into a matrix.
It is not immediately clear which dimension represents the height or width, as
that depends on the file format. Additionally, a file containing a set of color
images has two additional dimensions: the number of images, and the color
channels (e.g.  RGB). This is called NCHW format. Sometimes it is stored as
NHWC, which is the default representation in TensorFlow. Interestingly, NCHW is
the preferred format on GPUs.

Knowing which dimension is which is essential when performing various
operations; one generally wants to rotate images by working on the height and
width dimensions, not on the channel and height dimensions. However, after a
series of data manipulations, keeping track of dimensions can quickly become
challenging.

However, the tensor does not contain the information itself to help describe the
dimensions. As a result, practitioners often use comments such as the following
to document the dimension order:

```
# Num x Height x Width x Channel
tensor = torch.tensor(numpy.load("images.npy"))
tensor.shape
> torch.Size([100, 64, 64, 3])
```

This is obviously error-prone.

In Vespa, we have taken a different approach and introduced named dimensions.
This enables a strong tensor type system. An example of a tensor type in Vespa
which holds the same data as above:

```
tensor(num[100], height[64], width[64], channel[3])
```

This type system provides more formal documentation, which makes it easier to
work with for humans. It also introduces the ability for tensors and tensor
operations to be semantically verified. This means we can perform static type
inference for all computation, catching errors at an early compile-time stage
rather than during runtime.

Later in the post, we'll see how this enables arbitrarily complex computation
with only a minimal, concise set of core operations.


## Sparse and dense tensors

The tensor as a multi-dimensional array is often considered to be _dense_. This
means that all combinations of dimension indexes have a value, even if that
value is `0` or `NaN`. However, a tensor with many such values could be
represented more efficiently as a _sparse_ tensor, where only the non-empty values
are defined. This can lead to considerable savings in space.

Unfortunately, the internal representation of sparse tensors in most frameworks
makes them incompatible with regular dense tensors. This leads to an entirely
separate set of functions operating on sparse and dense tensors, with functions
to convert between the two.

Vespa supports dense, sparse, and tensors that contain both dense and sparse
dimensions, called a _mixed_ tensor. A dense tensor is a tensor containing only
"indexed" dimensions. An indexed dimension is indexed by integers, like an
array. The following is an example of a dense tensor containing two indexed
dimensions:

```
tensor(width[128], height[96])
```

A sparse tensor is conversely a tensor consisting of only "mapped" dimensions. A
mapped dimension is indexed by strings, like a map or hash table. An example of
a sparse tensor containing two mapped dimensions:

```
tensor(model_id{}, feature{})
```

A mixed tensor can contain both types:

```
tensor(model_version_id{}, first_layer_weights[64], second_layer_weights[128])
```

This particular example effectively works as a lookup table. By providing the
`model_version_id`, one can extract a dense tensor (called a dense subspace).
For instance, this can be useful for a single tensor to contain the weights for
multiple versions of a model, e.g., a neural network.

All in all, this enables a very flexible data representation.


## Tensor operations

Most frameworks that operate on and manipulate tensors have an extensive library
of functions. For instance, TensorFlow has hundreds of different operations
organized in various groups according to their function. Examples are
constructors, general manipulation, linear algebra, neural networks, and so on.
Some operations work element-wise, some on entire tensors, and some combine
tensors.

All operations have assumptions on their input tensors. For instance, a matrix
multiplication operation requires two matrix tensors with the same column/row
size. Likewise, a dot product operation requires two vectors with the same
vector length. These two operations are essentially the same: the sum of the
products of elements along a dimension. Yet two different operations are
provided: `matmul` and `dotprod`.

A two-dimensional convolution requires an input of four dimensions: the batch
size, color channels, width and height. This ordering is called NCHW, which is
the most efficient for GPU processing. However, the default in TensorFlow is
NHWC. Therefore, the operations working on these tensors need to know the
format, which must be provided by the developer as the format is not part of the
tensor.

Another example is the different operations based on tensor type. For instance,
there are two different operations for `concat`: one for a dense tensor and one
for sparse.

The inevitable consequence is that most frameworks get an extensive library of
operations. The problem with such large libraries is interoperability and
maintainability.

Assume you train a model on one framework and want to run inference on another.
The common way to represent the model is as a computational graph, where each
vertex is an operation. Evaluating a given graph on another system requires the
implementation of all operations in the graph. To guarantee general
interoperability between two frameworks, all operations in the original
framework must have an implementation. This becomes increasingly less feasible
as frameworks grow to have hundreds or thousands of operations.

In addition, many developers add custom operations. This further decreases
interoperability by requiring binary compatibility.

The tensor framework in Vespa, on the other hand, takes a different approach.
Tensors with named dimensions allow for a strong type system with well-founded
semantics. This makes it possible to define a small set of foundational
mathematical operations in which all other computations can be expressed.

Unary operations work on single tensors; examples include filtering and
reduction. Binary operations combine two input tensors to an output tensor, for
instance, joining, extending, or calculating some relation. By combining these
operations, they can express very complex computation.

Vespa provides just 8 core operations to transform tensors:

- `tensor` - construct a new tensor from a given expression
- `map` - apply a function to all values
- `reduce` - aggregate values along a dimension
- `rename` - rename a dimension
- `slice` - returns a tensor with all cells matching a partial address
- `join` - the natural join between two input tensors with a custom expression applied
- `merge` - merge two input tensors with a custom expression
- `concat` - concatenate two tensors along a given dimension

To aid developers, Vespa additionally provides higher-level, non-core
operations, which are all implemented in terms of these core operations.

This approach enables interoperability as implementing this small set is all
that is needed to realize complete support for tensor computation. Furthermore,
it makes optimization work more efficient. This is because low-level
optimizations are only required on this set of functions. Higher-level
optimizations can work on whichever chunks of these operations are beneficial,
independent of any chunking into higher-level functions humans happen to find
meaningful.


# The tensor formalism

In this section, we'll describe Vespa's full tensor formalism, including
tensors and tensor types, and the core set of tensor operations.

## Tensor types

A *tensor type* consists of a *value type* and a set of *dimensions*. The value type is a numeric data type: double, float, int8, bfloat16, etc. The default value type is double.

A dimension consists of a *name* and a *type*. The type can be either *indexed* or *mapped*, and, if indexed, can optionally include a *size*. The number of dimensions in the tensor is called its *order*. A tensor without dimensions (0-order) is a single scalar value. A tensor with one dimension (first-order) is a vector. A tensor with two dimensions (second-order) is a matrix.

Note that this notion of dimensions is not to be confused with the concept of dimensions in vector space, where a vector with 3 elements can represent a vector in a 3-dimensional space.

A value in a dimension is addressed by a label. For mapped dimensions, this label is a string. For indexed dimensions this label is an integer index. Tensors with mapped dimensions only hold values for the labels that exist. Indexed dimensions must have values for all indices.

Some examples:

- `tensor()` - a scalar value (double)
- `tensor<float>(x[3])` - An indexed vector with 3 floats
- `tensor(x[2], y[3])` - An indexed matrix of size 2-by-3
- `tensor(name{})` - A (sparse) map of named values
- `tensor<int8>(name{}, x[2])` - A map of named vectors of int8


## Tensors

A tensor is simply a tensor type and a set of values.  Values are held in
*cells* that are fully defined by the address given by the labels in each
dimension.  A tensor has a *string representation* defined by the type followed
by the cell values.

Some examples:

- `tensor():3.0` - a scalar value (double)
- `tensor<float>(x[3]):[1.0, 2.0, 3.0]` - An indexed vector with 3 floats
- `tensor(x[2], y[3]):[[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]]` - An indexed matrix of size 2-by-3
- `tensor(name{}):{ {name:foo}:2, {name:bar}:5 }` - A (sparse) map of named values
- `tensor(name{}):{ foo:2, bar:5 }` - Same as above with inferred dimension (single sparse)
- `tensor<int8>(name{}, x[2]):{foo:[1,2], bar:[3,4]}` - A map of named vectors of int8


## Tensor functions

Vespa has a small core set of just 8 tensor functions:

- Creational: `tensor`
- Unary: `map`, `reduce`, `rename`, `slice`
- Binary: `join`, `merge`, `concat`

These can be combined and used to express potentially complex computation, as
some take general lambda expressions as arguments. Please refer to the [tensor
function
reference](https://docs.vespa.ai/en/reference/ranking-expressions.html#tensor-functions)
for detailed descriptions of these functions.

We'll provide some examples to demonstrate the expressive power of `join` and
`reduce` in the following. These examples are also provided with a link to the
[tensor playground](https://docs.vespa.ai/playground/). In this interactive
environment, you can experiment with tensor expressions. Feel free to take any
of these examples and play around with them

### Vector outer product

Given two tensors representing vectors, `A` and `B`:

```
A: tensor(x[3]):[1,2,3]
B: tensor(y[3]):[4,5,6]
```

Notice that these tensors have different dimension names. We can multiply
these two tensors together, `A * B`, and the result is:

```
tensor(x[3],y[3]):[[4.0, 5.0, 6.0], [8.0, 10.0, 12.0], [12.0, 15.0, 18.0]]
```

This tensor has type `tensor(x[3],y[3])`. To see what is happening
here, note that the expression `A * B` is a convenience form of the underlying
expression:

```
join(A, B, f(a,b)(a * b))
```

The `join` function is the most used function when combining two input tensors.
As input, it takes two tensors and a lambda function (here `f(a,b)(a * b)`) to
define how to combine matching cells. The resulting tensor is the natural join
between the input tensors, and the cell values are defined by the lambda.  The
resulting type is the union of dimensions from the input tensors.

The actual operation is to combine all cells in `A` with all matching cells in
`B`, where a match is defined as having equal values on their common dimensions.
If `A` and `B` have no common dimensions, this combines all cells in `A` with
all cells in `B`.

In this example, the two input tensors have different dimensions. Since there
are no overlapping dimensions, this is in effect a Cartesian product. As
vectors, this represents an outer product and the result is thus an `x-by-y`
matrix.

[Play around with this example in the playground.](https://docs.vespa.ai/playground/index.html#N4KABGBEBmkFxgNrgmUrWQPYAd5QFNIAaFDSPBdDTAO30gEESybIiFIAXA2gZywAnABQAPRAGYAugEo4iAIzEATMWmRWEAL6stpDNXK4GRfW0ppNdBgCEWNTByg9+Q4QE9Js+QBZiAVmIANikNBx0MPVZDTGNOUysKfBjyek57B0IGRjAAKjA7KwjUKINEuKyzcgsU63SqtidIACssAEtaYUZiAp7oYQBDYgAjGUHc0ZkwmmLtFCkQLSA)


### Vector inner product (dot product)

Again, given the two vectors `A` and `B` representing vectors:

```
A: tensor(x[3]):[1,2,3]
B: tensor(x[3]):[4,5,6]
```

Here, the vectors have the same dimension name. Given the exact same expression
as above, `A * B` or, equivalently, `join(A, B, f(a,b)(a * b))`, the result is
now:

```
tensor(x[3]):[4.0, 10.0, 18.0]
```

Since the two tensors now have a common dimension, the `join` matches the cells
with equal values in that dimension. So `x[0]` from `A` is combined with `x[0]`
from `B`, and so on. The lambda expression `f(a,b)(a * b)` defines these values
should be multiplied. This is called the element-wise product.

The actual inner (dot) product requires these values to be summed. Thus we can
add a `sum` operation so the expression becomes `sum(A * B)`. The `sum`
operation is actually a `reduce` operation, so this expands fully to the
following:

```
reduce(join(A, B, f(a,b)(a * b)), sum)
```

The `reduce` operation aggregates values along a dimension (or all dimensions if
omitted). Vespa has a set of built-in aggregators: `sum`, `max`, `min`, `prod`,
`count`, and `avg`. In any case, the result is:

```
tensor():32
```

So, we have implemented a dot product function by combining the `join` and
`reduce` operations.

[Play around with this example in the playground.](https://docs.vespa.ai/playground/index.html#N4KABGBEBmkFxgNrgmUrWQPYAd5QFNIAaFDSPBdDTAO30gEESybIiFIAXA2gZywAnABQAPRAGYAugEo4iAIzEATMWmRWEAL6stpDNXK4GRfW0ppNdBgCEWNTByg9+QsZNnyALMQCsxADYpDQcdDD1WQ0xjTlMrCnwo8npOewdCBkYwACowOysw1AiDeJiMs3ILJOtUirYnSAArLABLWmFGYjyu6GEAQ2IAIxl+7OGZEJpC7Trq7At2NMrEqwhIFKgl+oY+AFcAWw7smwmC3VnShbiHBKpVqA3ILfIGwQIAE12AYwJhZraOl0bD1+kMRn0xjIZF09vtTqFdCgpCAtEA)


### Matrix multiplication

Consider the two following tensors, `A` and `B` representing matrices:

```
A: tensor(i[2],j[3]):[[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]]
B: tensor(j[3],k[2]):[[4.0, 5.0], [6.0, 7.0], [8.0, 9.0]]
```

Recall that a matrix multiplication between an `n-by-x` matrix and an `x-by-m`
matrix results in a `n-by-m` matrix. This is because the multiplication iterates
over each column in the first tensor and each row in the second, and sums the
products of elements together. This is, in essence, an inner product, or dot
product, for each column and row vector in the matrices.

Multiplying (`A * B`) these two tensors together, or equivalently, joining with
a multiplication (`join(A, B, f(a,b)(a * b))`), we get the following:

```
tensor(i[2],j[3],k[2]):[
    [[4.0, 5.0], [12.0, 14.0], [24.0, 27.0]],
    [[16.0, 20.0], [30.0, 35.0], [48.0, 54.0]]
]
```

This tensor type is, as expected, the union of dimensions. The `join` has
combined all cells with a given `j` index in `A` with all cells with the same
`j` index in `B`, and multiplied the matching values together. This is entirely
similar to the first step of the dot product seen above. In mathematics, this is
called the Hadamard product.

Like the dot product, we need to sum over the common dimension `j`. Again, this
is either a `sum(A, B, j)` or `reduce(join(A, B, f(a,b)(a * b)), sum, j)`. Note
that we need to specify the dimension in this case because we are not summing
all elements together. This results in:

```
tensor(i[2],k[2]):[[40.0, 46.0], [94.0, 109.0]]
```

The tensor type here is as expected: the `i-by-j` matrix multiplied with
the`j-by-k` matrix resulted in a `i-by-k` matrix. So the matrix multiplication is
a `join` followed by a `sum` `reduce` over the common dimension, like the inner
product. This pattern is generalizable to tensors of any order.

Vespa also provides a higher-level `matmul` function which performs this same
operation: `matmul(A, B, j)`. This is provided as an aid for developers.
However, it is entirely implemented by the core functions `join` and `reduce`.

[Play around with this example in the playground.](https://docs.vespa.ai/playground/index.html#N4KABGBEBmkFxgNrgmUrWQPYAd5QFNIAaFDSPBdDTAO30gEESybIiFIAXA2gZywAnABQBLRACYAusQBWiAMxSAlHEQBGYhOILiAFmIBWYgDYpkVhAC+rK6QzVyuBkXttKaS3QYAhFjUwOKB5+IWF5JWIAa0kVNUQ9ADoABmIwQxSZJBMUtIB2TLTEAA5csABOTPMvGww7VkdMZ05XLwp8RvJ6Tn8AwgZZLFFaYUY0nzToYQBDYgAjZRmAKgXlCwDa1HqHNub+t3IPTu8eg7YgyEECABMAVwBjAnChkbGwCbAp2YWZsCWwVZpPi3AC2aVkaxqtjOx2wHnYvUOHS8EEg3SgiPODBB0y4INuABtRuNwZCNrYUFIQFYgA)


## Discussion

The interesting point here is that the three operations just demonstrated, outer
product, dot product, and matrix multiplication, are performed with the same
low-level functions. Thus, there is no need for multiple distinct functions or
even another separate set of functions for sparse tensors.

Much of the expressive power of Vespa's tensor language comes from two features:
**argument lambdas** and the generality afforded by using **named dimensions**
in 'join's.

Many of the functions accept a **lambda**, which allows for evaluating general
expressions in context of a unary or binary function. These expressions can
perform any necessary calculation on their scalar inputs, and have a set of
mathematical functions available. In addition, tensor generation accepts a
lambda function without arguments that has access to other variables. This can
be used to generate a tensor by looking up values from another tensor. This is
called *peeking*:

```
tensor(y[3])(another_tensor{x:(y)})
```

The generality of the `join` resulting from tensors with named dimensions is
arguably the most unique aspect of the language:

- A `join` between tensors with the same dimensions is equivalent to performing
  an operation element-wise between the input tensors. If the lambda defines a
  multiplication, this is the same as an element-wise product.
- A `join` between tensors with disjunct dimensions is the cross join, or
  Cartesian product, between the input tensors.
- A `join` between tensors with partially overlapping dimensions produces
  results in-between these extremes, as seen in the matrix multiplication
  example above.

By combining `join` with `rename`, any such semantics can be achieved for any
tensors.

The `join` operation implements a natural join between tensors: it combines
cells in one tensor with cells from another based on the matching cells in their
common dimensions. It is thus the tensor language counterpart of the logical AND
operator.


## Summary

In this post, we've presented Vespa's tensor language. This formalism provides
generic computation over dense and sparse tensors, with full static type
inference, using just eight foundational tensor functions. Named dimensions are
used to add semantic information and achieve generality, and index labels
provide support for models working with strings.

In Vespa, this formalism makes numerical computation easier to express,
understand, and optimize.

For more information, take a look at Vespa's [tensor
guide](https://docs.vespa.ai/en/tensor-user-guide.html).

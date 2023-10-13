---
layout: post
title: Introducing Vespa Lucene Linguistics
author: dainiusjocas
categories: []
tags: [linguistics, bm25, stemming]
---

This post is about an idea that was born at the [Berlin Buzzwords 2023](https://tickets.plainschwarz.com/bbuzz23/) conference and its journey towards the production-ready implementation of the new [Apache Lucene](https://lucene.apache.org/)-based [Vespa Linguistics component](https://docs.vespa.ai/en/linguistics.html).
The primary goal of the Lucene linguistics is to make it easier to migrate existing search applications from Lucene-based search engines to Vespa.
Also, it can help improve your current Vespa applications.
More on that next!

## Context

Even though these days all the rage is about the modern neural-vector-embeddings-based retrieval (or at least that was the sentiment in the Berlin Buzzwords conference), the traditional lexical search is not going anywhere:
search applications still need tricks like filtering, faceting, phrase matching, paging, etc.
Vespa is well suited to leverage both traditional and modern techniques.

At Vinted we were working on the search application migration from Elasticsearch to Vespa.
The application over the years has grown to support multiple languages and for each  we have crafted custom Elasticsearch [analyzers](https://www.elastic.co/guide/en/elasticsearch/reference/8.9/specify-analyzer.html) with dictionaries for synonyms, stopwords, etc.
Vespa has a different approach towards lexical search than Elasticsearch, and we were researching ways to transfer all that accumulated knowledge without doing the “Big Bang” migration.

And here comes a part with a chat with the legend himself, [Jo Kristian Bergum](https://twitter.com/jobergum), on the sunny roof terrace at the Berlin Buzzwords 2023 conference.
Among other things, I’ve asked if it is technically possible to implement a Vespa Linguistics component on top of the Apache Lucene library.
With Jo’s encouragement, I’ve got to work and the same evening there was a working proof of concept.
This was huge!
It gave a promise that it is possible to convert almost any Elasticsearch analyzer into the Vespa Linguistics configuration and in this way solve one of the toughest problems for the migration project.

## Show me the code!

In case you just want to get started with the Lucene Linguistics the easiest way is to explore the [demo apps](https://github.com/vespa-engine/sample-apps/tree/master/examples/lucene-linguistics).
There are 4 apps:
- Minimal: example of the bare minimum configuration that is needed to set up Lucene linguistics;
- Advanced: demonstrates the “usual” things that can be expected when leveraging Lucene linguistics.
- Going-Crazy: plenty of contrived features that real-world apps might require.
- Non-Java: an app without Java code.

To learn more: read the [documentation](https://docs.vespa.ai/en/lucene-linguistics.html).

## Architecture

The scope of the Lucene linguistics component is **ONLY** the tokenization of the text.
[Tokenization](https://docs.vespa.ai/en/linguistics.html#tokenization) removes any non-word characters, and splits the string into tokens on each word boundary, e.g.:

```
“Vespa is awesome!” => [“vespa”, “is”, “awesome”]
```

In the Lucene land, the Analyzer class is responsible for the tokenization. 
So, the core idea for Lucene linguistics is to implement the Vespa [`Tokenizer`](https://github.com/vespa-engine/vespa/blob/master/linguistics/src/main/java/com/yahoo/language/process/Tokenizer.java) interface that wraps a configurable Lucene Analyzer.

For building a configurable Lucene Analyzer there is a handy class called [`CustomAnalyzer`](https://github.com/apache/lucene/blob/538b7d0ffef7bb71dd214d7fb111ef787bf35bcd/lucene/analysis/common/src/java/org/apache/lucene/analysis/custom/CustomAnalyzer.java#L99).
The `CustomAnalyzer.Builder` has convenient methods for configuring Lucene text analysis components such as CharFilters, Tokenizers, and TokenFilters into an Analyzer.
It can be done by calling methods with signatures:

```java
public Builder addCharFilter(String name, Map<String, String> params)
public Builder withTokenizer(String name, Map<String, String> params)
public Builder addTokenFilter(String name, Map<String, String> params)
```

All the parameters are of type `String`, so they can easily be stored in a configuration file!

When it comes to discovery of the text analysis components, it is done using the Java Service Provider Interface ([SPI](https://www.baeldung.com/java-spi)).
In practical terms, this means that when components are prepared in a certain way then they become available without explicit coding! You can think of it as [plugins](https://en.wikipedia.org/wiki/Plug-in_%28computing%29).

The trickiest bit was to configure Vespa to load resource files required for the Lucene components.
Luckily, there is a `CustomAnalyzer.Builder` factory method that accepts a Path parameter.
Even more luck comes from the fact that `Path` is the type exposed by the [Vespa configuration definition language](https://docs.vespa.ai/en/reference/config-files.html)!
With all that in place, it was possible to load resource files from the application package just by providing a relative path to files.
Voila!

All that was nice, but it made simple application packages more complicated than they needed to be:
a directory with at least a dummy file was required!
The requirement stemmed from the fact that in Vespa configuration parameters of type `Path` were mandatory.
This means that if your component can use a parameter of the `Path` type, it must be used.
Clearly, that requirement can be a bit too strict.

Luckily, the Vespa team quickly implemented a [change](https://github.com/vespa-engine/vespa/pull/28472) that allowed for configuration of `Path` type to be declared `optional`.
For the Lucene linguistics it meant 2 things:
1. Base component configuration became simpler.
1. When no path is set up, the `CustomAnalyzer` loads resource files from the classpath of the application package, i.e. even more flexibility in where to put resource files.

To wrap it up:
Lucene Linguistics accepts a configuration in which custom Lucene analysis components can be fully configured.

## Languages and analyzers

The Lucene linguistics supports 40 languages [out-of-the-box](https://docs.vespa.ai/en/lucene-linguistics.html).
To customize the way the text is analyzed there are 2 options:
1. Configure the text analysis in [`services.xml`](https://docs.vespa.ai/en/reference/services.html).
2. Extend a Lucene Analyzer class in your application package and register it as a [Component](https://docs.vespa.ai/en/jdisc/injecting-components.html#depending-on-all-components-of-a-specific-type).

In case there is no analyzer set up, then the Lucene [StandardAnalyzer](https://lucene.apache.org/core/9_8_0/core/org/apache/lucene/analysis/standard/StandardAnalyzer.html) is used.

### Lucene linguistics component configuration

It is possible to configure Lucene linguistics directly in the `services.xml` file.
This option works best if you’re already knowledgeable with Lucene text analysis components.
A configuration for the English language could look something like this:

```xml
<component id="linguistics"
           class="com.yahoo.language.lucene.LuceneLinguistics"
           bundle="my-vespa-app">
  <config name="com.yahoo.language.lucene.lucene-analysis">
    <configDir>linguistics</configDir>
    <analysis>
      <item key="en">
        <tokenizer>
          <name>standard</name>
        </tokenizer>
        <tokenFilters>
          <item>
            <name>stop</name>
            <conf>
              <item key="words">en/stopwords.txt</item>
              <item key="ignoreCase">true</item>
            </conf>
          </item>
          <item>
            <name>englishMinimalStem</name>
          </item>
        </tokenFilters>
      </item>
    </analysis>
  </config>
</component>
```

The above analyzer uses the `standard` tokenizer, then `stop` token filter loads stopwords from the `en/stopwords.txt` file that must be placed in your application package under the `linguistics` directory; and then the `englishMinimalStem` is used to stem tokens.

### Component registry

The Lucene linguistics takes in an ComponentRegistry of the `Analyzer` class.
This option works best for projects that contain custom Java code because your IDE will help you build an Analyzer instance.
Also, JUnit is your friend when it comes to testing.

In the example below, the [`SimpleAnalyzer`](https://lucene.apache.org/core/9_8_0/analysis/common/org/apache/lucene/analysis/core/SimpleAnalyzer.html) class coming with Lucene is wrapped as a component and set to be used for the English language.

```xml
<component id="en"
           class="org.apache.lucene.analysis.core.SimpleAnalyzer"
           bundle="my-vespa-app" />
```

### Mental model

With that many options using Lucene linguistics might seem a bit complicated.
However, the mental model is simple: priority for conflict resolution.
The priority of the analyzers in the descending order is:
1. Lucene linguistics component configuration;
1. Component that extend the Lucene Analyzer class;
1. Default analyzers per language;
1. `StandardAnalyzer`.

This means that e.g. if both a configuration and a component are specified for a language, then an analyzer from the configuration is used because it has a higher priority.

### Asymmetric tokenization

Going against [suggestions](https://docs.vespa.ai/en/linguistics.html#stemming) you can achieve an asymmetric tokenization for some language.
The trick is to, e.g. index with stemming turned on and query with stemming turned off.
Under the hood a pair of any two Lucene analyzers can do the job.
However, it becomes your problem to set up analyzers that produce matching tokens.

## Differences from Elasticsearch

Even though Lucene does the text analysis, not everything that you do in Elasticsearch is easily translatable to the Lucene Linguistics.
E.g. The `multiplex` token filter is [just not available in Lucene](https://github.com/apache/lucene/issues/9374).
This means that you have to implement that token filter yourself (probably by looking into how Elasticsearch implemented it [here](https://github.com/elastic/elasticsearch/blob/b31715db0113a3648d4eff0547942cb17ac28b03/modules/analysis-common/src/main/java/org/elasticsearch/analysis/common/MultiplexerTokenFilterFactory.java#L32)).

However, Vespa has advantages over Elasticsearch when leveraging Lucene text analysis.
The big one is that you configure and deploy linguistics components with your application package.
This is a lot more flexible than maintaining an Elasticsearch plugin.
Let’s consider an example: a custom stemmer.

In Elasticsearch land you either create a plugin or (if the stemmer is generic enough) you can try to contribute it to Apache Lucene (or Elasticsearch itself), so that it transitively comes with Elasticsearch in the future.
Maintaining Elasticsearch plugins is a pain because it needs to be built for each and every Elasticsearch version, and then a custom installation script is needed in both production and in development setups.
Also, what if you run Elasticsearch as a managed service in the cloud where custom plugins are not supported at all?

In Vespa you can do the implementation directly in your application package.
Nothing special needs to be done for deployment.
No worries (fingers-crossed) for Vespa version changes.
If your component needs to be used in many Vespa applications, your options are:
1. Deploy your component into some maven repository
2. Commit the prebuild bundle file into each application under the `/components` directory.
Yeah, that sounds exactly how you do with regular Java applications, and it is.
Vespa Cloud also has no problems running your application package with a custom stemmer. 

## Summary

With the new Lucene-based Linguistics component Vespa expands its capabilities for lexical search by reaching into the vast Apache Lucene ecosystem.
Also, it is worth mentioning that people experienced with other Lucene-based search engines such as Elasticsearch or Solr, should feel right at home pretty quickly.
The fact that the toolset and the skill-set are largely transferable lowers the barrier of adopting Vespa.
Moreover, given that the underlying text analysis technology is the same makes migration of the text analysis process to Vespa mostly a mechanical translation task.
Give it a try!

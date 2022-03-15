---
layout: post
title: "How to use Postman with Vespa APIs"
date: '2021-03-16'
tags: []
author: kkraune
image: assets/2021-03-16-interface-with-vespa-apis-using-postman/json.png
excerpt: >
    Interfacing with secure Vespa APIs is easy with Postman.
    Use Postman collections to template read and write operations to Vespa.
---

In this blogpost, you will learn how to use [Postman](https://www.postman.com/downloads/)
to increase productivity when working with mTLS-secured Vespa APIs.

Working with secured JSON APIs is not necessarily _difficult_, it is just cumbersome - examples:

    $ curl --cert public-cert.pem --key private-key.pem \
    "$ENDPOINT/search/?ranking=rank_albums&yql=select%20%2A%20from%20sources%20%2A%20where%20sddocname%20contains%20%22music%22%3B"

    $ curl --cert public-cert.pem --key private-key.pem \
    -H "Content-Type:application/json" --data-binary @my-new-doc.json \
    $ENDPOINT/document/v1/mynamespace/music/docid/1

The first does a Vespa YQL query, the second inserts a new document from a JSON file.
When developing applications, you are constantly modifying queries, schemas and JSON objects,
and checking JSON responses - some issues:

* Query encoding
* JSON pretty-print
* Modifying JSON blobs to add, update and delete documents
* Providing credentials like cert/key pairs
* Managing endpoint-URLs to multiple instances

And even if you managed to create an efficient environment for yourself to handle this,
sharing the environment can be hard - developers have their own way.



## Postman workspace
We have looked into using Postman to alleviate some of these issues,
and in this blogpost you will find some tips and tricks that we use ourselves.

Get started using the open API to Vespa Documentation Search -
import a Postman Collection:

![settings](/assets/2021-03-16-interface-with-vespa-apis-using-postman/collection.png)

Paste this as _Raw text_: 

```
{
	"info": {
		"_postman_id": "063984cc-f2eb-4b44-8b39-df66b8f4e37c",
		"name": "doc-search.vespa.oath.cloud",
		"schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
	},
	"item": [
		{
			"name": "query all docs yql userquery",
			"request": {
				"method": "GET",
				"header": [],
				"url": {
					"raw": "https://doc-search.vespa.oath.cloud/search/?yql=select * from doc where userInput(@input)%3B&input=vespa ranking is great",
					"protocol": "https",
					"host": [
						"doc-search",
						"vespa",
						"oath",
						"cloud"
					],
					"path": [
						"search",
						""
					],
					"query": [
						{
							"key": "yql",
							"value": "select * from doc where userInput(@input)%3B"
						},
						{
							"key": "input",
							"value": "vespa ranking is great"
						}
					]
				}
			},
			"response": []
		},
		{
			"name": "document/v1 GET",
			"request": {
				"method": "GET",
				"header": [],
				"url": {
					"raw": "https://doc-search.vespa.oath.cloud/document/v1/open/doc/docid/open%2Fen%2Freference%2Fquery-api-reference.html",
					"protocol": "https",
					"host": [
						"doc-search",
						"vespa",
						"oath",
						"cloud"
					],
					"path": [
						"document",
						"v1",
						"open",
						"doc",
						"docid",
						"open%2Fen%2Freference%2Fquery-api-reference.html"
					]
				}
			},
			"response": []
		}
	]
}
```

Run the queries to test Vespa's _/search/_ and _/document/v1/_ interfaces!



### Credentials
So far, we have only tested open interfaces that easily display in browsers, find the query links at
[vespa-documentation-search](https://github.com/vespa-cloud/vespa-documentation-search).

[Vespa Cloud](https://cloud.vespa.ai/) interfaces,
as well as most other services, are protected -
one must use credentials to access the interfaces.
Vespa Cloud as well as [Vespa.ai](https://vespa.ai/) uses mTLS cert/key pairs as credentials.

Using Postman, install the pair in Settings, per endpoint - click _Settings_:

![nav](/assets/2021-03-16-interface-with-vespa-apis-using-postman/navigate-to-settings.png)

Click _Certificates_ and _Add Certificate_:

![settings](/assets/2021-03-16-interface-with-vespa-apis-using-postman/settings.png)

Put the Vespa endpoint in the _Host_ input box, do not set port - 
put the `public-cert.pem` file in CRT, `private-key.pem` in KEY.

With this, these credentials are used when the endpoint is used in Postman Collections.
Now you can _duplicate_ the imported Collection and replace the endpoint to the secured one.
Test that you can access the secured endpoint by running a query.

Pro Tip: It is also possible to install the certificate/key-pair
[in a browser](https://cloud.vespa.ai/en/security-model.html#using-a-browser)
to use interfaces without Postman, too.



## /document/v1
Although the above is useful to run queries (in a browser or using Postman),
a bigger value comes from being able to POST/PUT/DELETE requests to a Vespa instance.
This lets you manipulate the document corpus when developing applications,
easily creating, modifying and deleting documents.

A [document/v1](https://docs.vespa.ai/en/document-v1-api-guide.html) GET for
`id:open:doc::open/en/reference/query-api-reference.html` is
[https://doc-search.vespa.oath.cloud/document/v1/open/doc/docid/open%2Fen%2Freference%2Fquery-api-reference.html](https://doc-search.vespa.oath.cloud/document/v1/open/doc/docid/open%2Fen%2Freference%2Fquery-api-reference.html).

It is easy to create a PUT to update this document - _duplicate_ the GET request and change it to a PUT.
Add raw JSON:

![settings](/assets/2021-03-16-interface-with-vespa-apis-using-postman/put.png)

Send the request from Postman to update the document.



## Sharing
With time, you will have a portfolio of Collections with requests to various endpoints.
These are endpoints on localhost for Docker instances, endpoint in _Dev_ zones in Vespa Cloud,
_Prod_ endpoints, as well as other self-hosted Vespa instances.

All of this is stored in your Postman account,
nothing is lost when working from another machine, just log in to share with yourself.
Be the hero of your team by creating a Team in Postman and share your workspace there, for everybody's benefit.
Now you can focus on your real work on data and schemas without the issues at the start of this post!

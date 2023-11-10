--- 
layout: post
title: "Anonymized endpoints and token authentication in Vespa Cloud"
author: mortent mpolden
date: '2023-11-09'
image: assets/2023-11-09-announce-tokens-and-anonymous-endpoints/markus-spiske-6pflEeSzGUo-unsplash.jpg
image_credit: 'Photo by <a href="https://unsplash.com/@markusspiske?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Markus Spiske</a> on <a href="https://unsplash.com/photos/text-6pflEeSzGUo?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Unsplash</a>
'
skipimage: true
tags: []
excerpt: "In this post we will explain the new endpoint format and also introduce a new token authentication method for Vespa Cloud data plane."
---

When you deploy a Vespa application on [Vespa Cloud](https://cloud.vespa.ai/) your application is assigned an [endpoint](https://cloud.vespa.ai/en/reference/routing) for each container cluster declared in your [application package](https://cloud.vespa.ai/en/reference/application-package). This is the endpoint you communicate with when you query or feed documents to your application.

Since the launch of Vespa Cloud these endpoints have included many dimensions identifying your exact cluster, on the following format `{service}.{instance}.{application}.{tenant}.{zone}.z.vespa-app.cloud`. This format allows easy identification of a given endpoint.

However, while this format makes it easy to identify where an endpoint points, it also reveals details of the application that you might want to keep confidential. This is why we are introducing _anonymized endpoints_ in Vespa Cloud. Anonymized endpoints are created on-demand when you deploy your application and have the format `{generated-id}.{generated-id}.{scope}.vespa-app.cloud`. As with existing endpoints, details of anonymized endpoints and where they point are shown in the Vespa Cloud Console for your application.

Anonymized endpoints are the now the default for all new applications in Vespa Cloud. They have also been enabled for existing applications but with backward compatibility. This means that endpoints on the old format continue to work for now but are marked as deprecated in the Vespa Cloud console. We will continue to support the previous format for existing applications, but we encourage using the new endpoints.

In addition to making your endpoint details confidential, this new endpoint format allows Vespa Cloud to optimize certificate issuing. It allows for much faster deployments of new applications as they no longer have to wait for a new certificate to be published.

No action is needed to enable this feature. You can find the new anonymized endpoints in the Vespa Console for your application or by running the [Vespa CLI](https://cloud.vespa.ai/en/getting-started) command `vespa status`.

# Data plane Token authentication

In addition to anonymized endpoints, we are introducing support for data plane authenticating using access tokens. Token authentication is intended for cases where [mTLS authentication](https://cloud.vespa.ai/en/security/guide) is unavailable or impractical. For example, edge runtimes like [Vercel edge runtime](https://vercel.com/docs/functions/edge-functions/edge-runtime) are built on the [V8 Javascript engine](https://v8.dev/) that does not support mTLS authentication.  Access tokens are created and defined in the Vespa Cloud console and referenced in the application package. See instructions for creating and referencing tokens in the application package in the [security guide](https://cloud.vespa.ai/en/security/guide#configure-tokens).

Note it’s still required to define a data plane certificate for mTLS authentication; mTLS is still the preferred authentication method for data plane access, and applications configuring token-based authentication will have two distinct endpoints. 

![alt_text](/assets/2023-11-09-announce-tokens-and-anonymous-endpoints/endpoints.png)

Application endpoints in Vespa Console - Deprecated legacy mTLS endpoint name and two anonymized endpoints, one with mTLS support and the other with token authentication. Using token-based authentication on the mTLS endpoint is not supported. 

## Using data plane authentication tokens 

Using the token endpoint from the above screenshot, `https://ed82e42a.eeafe078.z.vespa-app.cloud/`, we can authenticate against it by 
adding a standard `Authorization` HTTP header to the data plane requests. For example as demonstrated below using [curl](https://curl.se/): 

```shell
curl -H "Authorization: Bearer vespa_cloud_...." https://ed82e42a.eeafe078.z.vespa-app.cloud/
```

### PyVespa 

Using the latest release of [pyvespa](https://pyvespa.readthedocs.io/en/latest/), you can interact with token endpoints by setting an environment variable named VESPA_CLOUD_SECRET_TOKEN. If this environment variable is present,  pyvespa will read this and use it when interacting with the token endpoint. 

```python
import os
os.environ['VESPA_CLOUD_SECRET_TOKEN'] = "vespa_cloud_...."
from vespa.application import Vespa
vespa = Vespa(url="https://ed82e42a.eeafe078.z.vespa-app.cloud")
```

In this case, pyvespa will read the environment variable VESPA_CLOUD_SECRET_TOKEN and use that when interacting with the data plane endpoint of your application. There are no changes concerning control-plane authentication, which requires a valid developer/API key. 

We do not plan to add token-based authentication to other Vespa data plane tools like [vespa-cli](https://docs.vespa.ai/en/vespa-cli.html) or [vespa-feed-client](https://docs.vespa.ai/en/vespa-feed-client.html), as these are not designed for lightweight edge runtimes. 

### Edge Runtimes

This is a minimalistic example of using [Cloudflare worker, ](https://developers.cloudflare.com/workers/)where we have stored the secret Vespa Cloud token using [Cloudflare worker functionality for storing secrets](https://developers.cloudflare.com/workers/configuration/secrets/). Note that Cloudflare workers also support [mTLS](https://cloud.vespa.ai/en/security/cloudflare-workers). 

```javascript
export default {
    async fetch(request, env, ctx) {
        const secret_token = env.vespa_cloud_secret_key
        return fetch('https://ed82e42a.eeafe078.z.vespa-app.cloud/', 
                     {headers:{'Authorization': `Bearer ${secret_token}`}})
    },
};

```
Consult your preferred edge runtime provider documentation on how to store and access secrets. 

## Security recommendations

It may be easier to use a token for authentication, but we still recommend using mTLS wherever possible. Before using a token for your application, consider the following recommendations.

### Token expiration

While the cryptographic properties of tokens are comparable to certificates, it is recommended that tokens have a shorter expiration. Tokens are part of the request headers and not used to set up the connection. This means they are more likely to be included in e.g. log outputs. The default token expiration in Vespa Cloud is 30 days, but it is possible to create tokens with shorter expiration.

### Token secret storage

The token value should be treated as a secret, and never be included in source code. Make sure to use a secure way of accessing the tokens and in such a way that they are not exposed in any log output.

## Summary

Keeping your data safe is a number one priority for us. With these changes, we continue to improve the developer friendliness of Vespa Cloud while maintaining the highest level of security. With anonymized endpoints, we improve deployment time for new applications by several minutes, avoiding waiting for certificate issuing. Furthermore, anonymized endpoints eliminate disclosing tenant and application details in certificates and DNS entries. 

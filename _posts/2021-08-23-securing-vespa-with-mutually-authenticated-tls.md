---
layout: post 
title: "Securing Vespa with mutually authenticated TLS (mTLS)"
date: '2021-08-23' 
tags: []
image: assets/2021-08-23-securing-vespa-with-mutually-authenticated-tls/jason-dent-3wPJxh-piRw-unsplash.jpg
author: bjorncs mortent vekterli 
skipimage: true

excerpt: Learn how to secure both the application container and the Vespa internal communication of your Vespa application. 
---
![Decorative image](/assets/2021-08-23-securing-vespa-with-mutually-authenticated-tls/jason-dent-3wPJxh-piRw-unsplash.jpg)
<p class="image-credit">
 Photo by <a href="https://unsplash.com/@jdent?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">
 Jason Dent</a> on <a href="https://unsplash.com?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
</p>

Open source Vespa has always supported [securing container endpoints](https://docs.vespa.ai/en/jdisc/http-server-and-filters.html#ssl) with mutually
authenticated Transport Layer Security (*mTLS*). Recently mTLS support was extended to also include all cluster-internal
communication.

This blog post will cover how to enable mTLS for a Vespa installation. See the
[Vespa mTLS documentation](https://docs.vespa.ai/en/mtls.html) for detailed information. A newly published sample application showing
the configuration is available
at [secure-vespa-with-mtls](https://github.com/vespa-engine/sample-apps/tree/master/secure-vespa-with-mtls)
and will be used as an example throughout this post.

[Vespa Cloud](https://cloud.vespa.ai/) and Verizon Media have been running Vespa with mTLS across the entire application stack for several years.
We are very happy to announce that this feature is now fully available in Open Source Vespa. 

If you are a Vespa Cloud customer, 
[mTLS is automatically configured without any action required on your part](https://cloud.vespa.ai/en/security-model.html).

## Why mTLS
Securing the container endpoints with mTLS ensures that only authenticated clients can access the endpoints, 
and the clients know they are connecting to a trusted source. Similarly, by securing the cluster with mTLS each service will
authenticate itself to the other services while at the same time they ensure they are connecting to trusted sources. This 
greatly improves the overall security of the application cluster by preventing access from unauthorized clients.

## mTLS for Vespa
Vespa offers two separate planes of TLS connectivity:
* **HTTP(S) application container endpoints**. This is the edge of your Vespa installation where search queries 
  and feed requests are handled.
* **Vespa-internal communication**. This is all communication between processes running on the nodes in
  your Vespa installation. This includes clients connecting directly to backend services instead of going through the application
  container APIs. Only mTLS can be configured for these protocols.

## Public Key Infrastructure (PKI)
Since there are two planes to be secured, it is encouraged to have separate Certificate Authority (*CA*) signing entities for the two. In the sample
application there are two self-signed CAs to simulate this. By default Vespa also enforces [certificate hostname/IP verification](https://datatracker.ietf.org/doc/html/rfc2818#section-3). It
is therefore necessary to include the hostnames and IPs of the hosts in the certificates. While it is
possible to turn this feature off, it is highly encouraged to keep the default setting.

It is encouraged to have short-lived certificates. Vespa Cloud refreshes cluster internal certificates daily.
Vespa services will periodically reload the key/certificate files to handle changes.
The new version of the files will be used without any serving impact.

## Vespa-internal communication
On any node running Vespa, mTLS is controlled via the environment variable `VESPA_TLS_CONFIG_FILE` pointing to 
a configuration file. See [TLS configuration file reference](https://docs.vespa.ai/en/reference/mtls.html#configuration-file)
for details on the syntax.

The sample application uses a minimal configuration containing the private key, the certificate and the Certificate Authority (CA) certificate:
```json
{
  "files": {
    "private-key": "/var/tls/host.key",
    "ca-certificates": "/var/tls/ca-vespa.pem",
    "certificates": "/var/tls/host.pem"
  }
}
```

This configuration will be used for all services on all ports. This will also be picked up by any CLI tool used on the
hosts (assuming the user has access to the key material).

## Application container endpoints
Application container TLS for HTTPS is configured in `services.xml`. For details see 
[TLS in Configuring Http Servers and Filters](https://docs.vespa.ai/en/jdisc/http-server-and-filters.html#ssl).
The sample application contains the following configuration inside the `<container>` tag:
```xml
<http>
  <server id="default" port="8080" />
  <server id="ingress" port="8443">
    <ssl>
      <private-key-file>/var/tls/host.key</private-key-file>
      <certificate-file>/var/tls/host.pem</certificate-file>
      <ca-certificates-file>/var/tls/ca-client.pem</ca-certificates-file>
      <client-authentication>need</client-authentication>
    </ssl>
  </server>
</http>
```

This configuration will set up port 8080 to use the TLS configuration provided by the `VESPA_TLS_CONFIG_FILE`
environment variable (see [Vespa-internal communication](#vespa-internal-communication)). Port 8443 will present the
same certificate, but will require all clients to authenticate with a certificate signed by a separate client CA.

## Verifying TLS configuration
In the sample application the Vespa configserver port 19071 is mapped to the host network on the same port. 

To access the configserver you need to present a client certificate valid for *Vespa-internal communication*. We'll first
see what happens if we do not present a certificate.
```shell
$ curl --cacert pki/vespa/ca-vespa.pem --head https://localhost:19071/ApplicationStatus
curl: (35) error:1401E412:SSL routines:CONNECT_CR_FINISHED:sslv3 alert bad certificate
```

Note that the curl command in this example includes a CA certificate. Otherwise the handshake will fail on the client
not trusting the server’s certificate.

Presenting a trusted client certificate grants access to the config server:
```shell
$ curl --key pki/vespa/host.key --cert pki/vespa/host.pem --cacert pki/vespa/ca-vespa.pem --head https://localhost:19071/ApplicationStatus
HTTP/2 200
date: Thu, 19 Aug 2021 11:34:10 GMT
content-type: application/json
content-length: 12732
```

In the sample application the application container port 8443 is mapped to the host network on the same port. Access to
the application container is not granted without presenting a client certificate valid for the *application container
HTTPS endpoints*.
```shell
$ curl --cacert pki/vespa/ca-vespa.pem --head https://localhost:8443/search/?query=michael
curl: (35) error:1401E412:SSL routines:CONNECT_CR_FINISHED:sslv3 alert bad certificate
```

Providing the application container client certificate gives us access:
```shell
$ curl --key pki/client/client.key --cert pki/client/client.pem --cacert pki/vespa/ca-vespa.pem --head https://localhost:8443/search/?query=michael
HTTP/2 200
date: Thu, 19 Aug 2021 11:34:36 GMT
content-type: application/json;charset=utf-8
content-length: 380
```

## Conclusion
Enabling mTLS is crucial to securing your Vespa installation.
In this blog post we have showcased the new Vespa mTLS sample application,
which demonstrates how to enable mutually authenticated TLS for all of Vespa,
ranging from internal protocols to the HTTPS application container edge.

To configure Vespa with mTLS you need version 7.441.3 or newer installed.
See the [documentation](https://docs.vespa.ai/en/mtls.html) to get started.

---
layout: post
title:  "Local dev environment for Concourse CI"
date:   2021-04-25 09:09:52 -0400
categories: docker concourse concourse-di
---

Over the last couple of days, I've been writing a [custom Concourse resource](https://github.com/mamercad/concourse-awx-resource), and I thought I'd take a few to walk through how I set up my local development environment. If you're not familiar with [Concourse CI](https://concourse-ci.org/), and you're doing some sort of CI/CD, give it a look. For me, it's been quite refreshing. At `$lastjob`, we were a [Jenkins](https://www.jenkins.io/) shop, and, I'm not sure I miss it all that much `:smile:`. When it comes down to usage, I'll take declarative YAML over imperative Groovy every day of the week, including Sunday.

Alright, let's roll. Concourse is built with containers in mind, so, we'll need something like [Docker Desktop](https://www.docker.com/products/docker-desktop). The container runtime shouldn't matter all that much, I just happened to be using my Mac at the time. When I first started writing the Concourse resource, I was pushing to [quay.io](quay.io), which is fine, but, when you're trying to iterate quickly, becomes a bottleneck in a hurry. I'd never written a Concourse resource in the past, so, it took me lots of tries to get things working. There's nothing fast about pushing and pulling ~ gigabyte between a 5-year-old laptop and Quay over and over again. It didn't take me long to throw that out and set everything up locally.

Setting up Concourse locally is relatively painless, [they provide a compose file](https://github.com/concourse/concourse/blob/master/docker-compose.yml). The only change (addition) I've made is adding a local Docker registry to keep my images pushing and pulling local.

```yaml
# existing Concourse services here
  registry:
    image: registry:2
    ports: ["5000:5000"]
    volumes:
      - ${PWD}/server.crt:/server.crt
      - ${PWD}/server.key:/server.key
    environment:
      REGISTRY_HTTP_ADDR: 0.0.0.0:5000
      REGISTRY_HTTP_TLS_CERTIFICATE: server.crt
      REGISTRY_HTTP_TLS_KEY: server.key
```

Here's a one-liner for generating "snake oil" crypto:

```bash
❯ openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
    -subj "/C=${COUNTRY}/ST=${STATE}/L=${CITY}/O=${ORG})/CN=${FQDN}" \
    -keyout server.key -out server.crt
```

So, when it comes to tagging your images, they'd look something like this `registry:5000/my-image-name:0.0.1`. Note that `registry` lines up with the service name (the existing Concourse services in the "pod" can resolve this name), the `5000` is obviously the chosen port, `my-image-name` is an arbitrary image name, and `0.0.1` is an arbitrary tag. Now, when you `docker push ...` you'll be pushing to the Docker registry running locally.

Closing the loop, we'll need to also pull from our local Docker registry, here's an example of how our `resource_type` would look:

```yaml
resource_types:
  - name: our-example-image
    type: docker-image
    source:
      repository: registry:5000/my-image-name
      version: 0.0.1
```

Hopefully this'll help speed things up for you as they did for me!

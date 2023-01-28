---
layout: post
title: Just 1Password things
date: 2023-01-23 06:46:33 -0500
categories: 1password 1p connect kubernetes secrets
---

It took me a while to get [Connect server](https://developer.1password.com/docs/connect) going with Kubernetes, here are my notes.
I haven't gone very deep on this, I'm just starting with [1Password](https://1password.com/) in earnest (beyond the simple use cases).

The first step is to create the connect server; I'm guessing that this is basically an API gateway to your stuff in their cloud.

```shell
❯ op connect server create Kubernetes --vaults Kubernetes --cache
Set up a Connect server.
UUID: REDACTED
Credentials file: /path/to/where/you/ran/this/1password-credentials.json
```

If you want to see your servers:

```shell
❯ op connect server list
ID                            NAME          STATE
REDACTED                      Kubernetes    ACTIVE
```

The next step is to create an access token for Kubernetes, I'm intentially giving it a short expiration for this example.

```shell
❯ export CONNECT_TOKEN="$(op connect token create Kubernetes --server Kubernetes --vaults Kubernetes,rw --expires-in=24h)"
```

Next, set up the [Helm](https://helm.sh/) things:

```shell
❯ helm repo add 1password https://1password.github.io/connect-helm-charts/
❯ helm repo update
```

Lastly, deploy Connect and its operator, I'm keeping everything in the `1password` namespace for now.
Be mindful of the path to `1password-credentials.json`.
The end result of all of this is that you get syncing (and caching) of your 1Password secrets to your Kubernetes secrets.

```shell
❯ helm install connect 1password/connect \
  --namespace "1password" --create-namespace \
  --set-file connect.credentials="1password-credentials.json" \
  --set operator.create="true" \
  --set operator.token.value="${CONNECT_TOKEN}" \
  --set operator.watchNamespace="{1password}"
```

I've created a test secret in 1Password:

```shell
❯ op item get --vault Kubernetes test1
ID:          REDACTED
Title:       test1
Vault:       Kubernetes (REDACTED)
Created:     2 hours ago
Updated:     2 hours ago by Mark Mercado
Favorite:    false
Version:     1
Category:    LOGIN
Fields:
  username:    foo
  password:    bar
```

Let's define this secret in Kubernetes, note the `itemPath` structure (the `vaults` and `item` path segments are fixed).
Remember that I've got the operator configured to only watch the `1password` namespace right now.

```yaml
❯ cat secrets.yaml
apiVersion: onepassword.com/v1
kind: OnePasswordItem
metadata:
  name: test1
  namespace: 1password
spec:
  itemPath: vaults/Kubernetes/items/test1
```

Go ahead an deploy this manifest with `kubectl apply -f secrets.yaml`.
You should see something like this:

```shell
❯ kubectl -n 1password get onepassworditems test1
NAME    AGE
test1   10s
```

And then the corresponding secret:

```shell
❯ kubectl -n 1password get secret test1
NAME    TYPE     DATA   AGE
test1   Opaque   2      45s
```

And to make sure it's working (recall the secret has two fields (above), `username` is `foo` and `password` is `bar`:

```shell
❯ kubectl -n 1password get secret test1 -o json | jq .data
{
  "password": "YmFy",
  "username": "Zm9v"
}

❯ echo Zm9v | base64 -d
foo

❯ echo YmFy | base64 -d
bar
```

Sweet, looks good.

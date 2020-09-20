---
layout: post
title:  "GitHub Deploy Keys"
date:   2020-09-20 05:55:13 -0400
categories: github deploy deployment keys ssh
---

Just dropping a quick entry about GitHub and [deploy keys](https://docs.github.com/en/developers/overview/managing-deploy-keys). In particular, working around the "you can't reuse them" limitation:

> You can launch projects from a GitHub repository to your server by using a deploy key, which is an SSH key that grants access to a single repository.

I ran across this in my homelab, where I'm currently using GitHub webhooks to deploy a couple of "websites" (quotes, because, they're not really useful or anything, just domains that I play around with). Anyhow, it's a very simple GitOps workflow: the content for the websites is stored in its own git repository, and whenever there's a push, the web server hosting the content does a pull. Simple enough. In order to get around the "you can't reuse keys", I'm doing `${HOME}/.ssh/config` tricks that look something like this:

```bash
Host github.com-site1
  HostName github.com
  User git
  IdentityFile ~/.ssh/key-site1

Host github.com-site2
  HostName github.com
  User git
  IdentityFile ~/.ssh/key-site2
```

In the webroot for the first site, the remote looks like this:

```bash
$ git remote -v
origin  git@github.com-site1:mamercad/site1.git (fetch)
origin  git@github.com-site1:mamercad/site1.git (push)
```

For the second site, just replace `site1` in what's about with `site2`, I'm sure you can see the pattern.

Here's a quick-and-dirty PHP snippet that you could (caveat emptor) use as the endpoint of the GH webook which pulls `main`:

```php
$ head index.php
<?php
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
  $payload = json_decode(file_get_contents('php://input'), true);
  if (isset($payload['ref']) && $payload['ref'] == 'refs/heads/main') {
    exec("git pull origin main");
  }
}
?>
```

That's about it!

---
layout: post
title:  "SSH Keys and LastPass"
date:   2020-09-02 05:13:58 -0400
categories: ssh lastpass
---

I'm regularly finding myself working towards minimalism, in particular, when it comes to tooling.
It's very normal to have many hundreds of secrets to use and manage on a regular basis.
Arguably, the best tool we have for the job right now are commonly referred to as "password managers".
There are lots of them out there: [LastPass](https://mamercad.github.io), [1Password](https://1password.com), [pass](https://www.passwordstore.org), and more.
Right now, for better or worse, I use LastPass.

Should you find yourself in tech, you can probably triple the number of secrets you'll need to regularly manage.
And no, I'm not saying that a person should store their _work_ secrets in their _personal_ password manager -- unless the secret in question is in fact personal, e.g., your work SSH key pair.
An example of what *not* to store in your personal vault, as far as work is concerned, would be a shared `root` password (those should only live in whatever vault your workplace provides).

Since I'm already using a password manager for secrets, it seems natural to store my SSH key pair there as well.
This probably isn't a new idea, but, I'll show you how I happen to do it so that it's a bit less painful.
As I've mentioned, I use LastPass.
In particular, for this stuff, we'll need the CLI version which you can find [here](https://github.com/lastpass/lastpass-cli).
With Homebrew, it's as easy as `brew install lastpass-cli`.

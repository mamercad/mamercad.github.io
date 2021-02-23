---
layout: post
title:  "Ubiquiti UniFi's Cloud Key, Let's Encrypt and Namecheap"
date:   2020-10-21 09:33:07 -0400
categories: ubiquiti unifi cloudkey letsencrypt namecheap
---

Just a quick writeup on doing real TLS on a [Ubiquiti UniFi](https://www.ui.com) [Cloud Key](https://www.ui.com/unifi/unifi-cloud-key/) with [Let's Encrypt](https://letsencrypt.org) and [Namecheap](https://www.namecheap.com).
Last night, my Cloud Key was acting up, so I took the time to do what I've been putting off for years out of sheer laziness.
Not that doing TLS is overly complicated, but, it's one of those "do I really care about this" situations.
Since I was already spending time rescuing the Cloud Key, I thought, might as well do the crypto as well.
You'll have to have an API key for Namecheap, as I'm doing `dns-01` ACME validation in these steps.

After SSH'ing into your Cloud Key, the steps are:

```bash
root@UniFi-CloudKey:~# curl https://get.acme.sh | sh
root@UniFi-CloudKey:~# cd ~/.acme.sh
root@UniFi-CloudKey:~/.acme.sh# export NAMECHEAP_API_KEY=<your.namecheap.api.key>
root@UniFi-CloudKey:~/.acme.sh# export NAMECHEAP_USERNAME=<your.namecheap.user.name>
root@UniFi-CloudKey:~/.acme.sh# export NAMECHEAP_SOURCEIP=<your.namecheap.api.ip>
root@UniFi-CloudKey:~/.acme.sh# ./acme.sh --issue --dns dns_namecheap -d <your.domain.name>
root@UniFi-CloudKey:~/.acme.sh# ./acme.sh --deploy -d <your.domain.name> --deploy-hook unifi
```

Note that the utility is nice enough to handle automatic auto-renewal as well:

```bash
root@UniFi-CloudKey:~# crontab -l
3 0 * * * "/root/.acme.sh"/acme.sh --cron --home "/root/.acme.sh" > /dev/null
```

And yes, the fact that the Cloud Key doesn't do a decent job of using a non-root user has bothered me from day one.
Some day, I'll figure out a workaround, or, this might be a nonissue with the second generation key (I have the first).
If I recall correctly, `~root/.ssh` isn't persistent, or something along those lines.
Anyhow, like I said, I haven't dug too hard on it to actually know/remember right now.

One thing to note, the deploy hook only takes care of the crypto for `8443/tcp` (the Java program driving the Cloud Key UI).
It's not a huge deal since `443/tcp` doesn't get too much play after you're up an running, but, still annoying.
Perhaps I'll fix this down the road.

That should be it, happy green lock to you!

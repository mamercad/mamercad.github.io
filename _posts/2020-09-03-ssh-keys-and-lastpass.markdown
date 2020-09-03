---
layout: post
title:  "SSH Keys and LastPass"
date:   2020-09-02 05:13:58 -0400
categories: ssh lastpass
---

I'm regularly finding myself working towards minimalism, in particular, when it comes to tooling.
It's quite a common problem nowadays to have many hundreds of secrets to use and manage (cough, rotate, cough!) on a regular basis.
Arguably, the best tools we have for the job right now are commonly referred to as "password managers" or "secret vaults".
There are lots of them out there: [LastPass](https://mamercad.github.io), [1Password](https://1password.com), [pass](https://www.passwordstore.org), and more.
Right now, for better or worse, I happen use LastPass.

Should you find yourself in tech, you can probably triple the number of secrets you'll need to regularly manage.
And no, I'm not saying that a person should store their _work_ secrets in their _personal_ password manager -- unless the secret in question is in fact personal, e.g., your work SSH key pair.
An example of what *not* to store in your personal vault, as far as work is concerned, would be a shared `root` password (those should only live in whatever vault your workplace provides).

Since I'm already using a password manager for secrets, it seems natural to store my SSH key pair there as well (back to that minimalism thing).
This probably isn't a new idea, but, I'll show you how I happen to do it so that it's a bit less cumbersome.
As I've mentioned, I use LastPass.
In particular, for this stuff, we'll need the CLI version which you can find [here](https://github.com/lastpass/lastpass-cli) (technically, I suppose you could do it with the GUI application if you wanted to).
With Homebrew, it's as easy as `brew install lastpass-cli`.

For completeness, I'll generate a new key pair, so we can do the whole process, end-to-end.
Plus, this is a throwaway exercise.

### Generate an SSH key pair (optional)

```bash
❯ ssh-keygen -t rsa -b 4096 -C "Demo/ssh" -N "hunter2" -f demo.key
Generating public/private rsa key pair.
Your identification has been saved in demo.key.
Your public key has been saved in demo.key.pub.
The key fingerprint is:
SHA256:A04anciW2RmsQ/okvKfkiWyGAe20LBYJ7exPbCATZCs Demo/ssh
The key's randomart image is:
+---[RSA 4096]----+
|.+   ..          |
|+ o..*.+         |
|EB.oB.B          |
|=oX.+= .         |
|.B.O... S        |
|o.B *    .       |
|+* B             |
|o++ .            |
|o                |
+----[SHA256]-----+
```

This gives us our new key pair.

```bash
❯ file demo*
demo.key:     OpenSSH private key
demo.key.pub: OpenSSH RSA public key
```

### Store the pieces

```bash
❯ printf "Private Key: %s\nPublic Key: %s\nPassphrase: %s\n" \
  "$(cat demo.key)" "$(cat demo.key.pub)" "$(echo hunter2)" \
    | lpass add --non-interactive --sync=now --note-type=ssh-key "Demo/ssh"
```

### Retrieve the pieces

Note that in the interest of space, I'm abbreviating the output for the keys with pipes to `head` and `cut`.
In practice, we could now easily lay these down locally by piping to `tee ~/.ssh/demo.key` or something along those lines.

```bash
❯ lpass show "Demo/ssh" --field="Private Key" | head -3
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAACmFlczI1Ni1jdHIAAAAGYmNyeXB0AAAAGAAAABCvT9I7l0
1IUnqpGX4WrspWAAAAEAAAAAEAAAIXAAAAB3NzaC1yc2EAAAADAQABAAACAQDJxL6OCGHK
```

```bash
❯ lpass show "Demo/ssh" --field="Public Key" | cut -c1-70
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDJxL6OCGHKazrKC8iFys/4FwhxMtHK7b
```

```bash
❯ lpass show "Demo/ssh" --field="Passphrase"
hunter2
```

There are other fields in available, and I'll leave this as an exercise for the reader to hack around with.

---
layout: post
title:  "Pi-hole on KVM/QEMU"
date:   2020-09-02 05:13:58 -0400
categories: pi-hole pihole kvm qemu
---

I'm going to write about this, not because it's overly complicated, but mostly because I always end up (re)Googling all of these things, regularly. The older you get, the less you tend to waste time with rote memorization, seemingly. Most, if not all, of the math profs I had reinforced this -- know the concepts, you can always look up the details. Frankly, I'm tired of looking these things up, so, here goes.

One of the first things that always burns me is getting a list of all of the "OS variants". Typically you can guess them, but, it'd be nice to look at them. If you search for "virt-install os-variant", or something like that, you'll regularly end up with `virt-install --os-variant list`. Unfortunately, this doesn't work for me, at least on CentOS 7. Instead, I had to use `osinfo-query os`. Hit [me](mailto:mamercad@gmail.com) up with why this is if you happen to know, please.
I quickly checked Ubuntu 20.04 and I get this:

```bash
ubuntu18.04$ sudo virt-install --os-variant list
ERROR    Unknown OS name 'list'. See `osinfo-query os` for valid values.
```

CentOS 7.7 unhelpfully gives this:

```bash
centos7.7$ sudo virt-install --os-variant list
ERROR
--name is required
--memory amount in MiB is required
--disk storage must be specified (override with --disk none)
An install method must be specified
(--location URL, --cdrom CD/ISO, --pxe, --import, --boot hd|cdrom|...)
```

So, I guess that's the current way of doing this. Anyhow, the plan is, create a guest to run Pi-hole, so, let's get to it. And before you wonder, yes, I happen to actually have Raspberry Pis for this, but I need to schedule some maintenance, heh.

```bash
centos7.7$ sudo virt-install \
  --name pihole1 \
  --ram 1024 \
  --disk path=/var/lib/libvirt/images/pihole1.qcow2,size=10 \
  --vcpus 1 \
  --os-type linux \
  --os-variant ubuntu18.04 \
  --network bridge=br0 \
  --graphics none \
  --console pty,target_type=serial \
  --location 'http://archive.ubuntu.com/ubuntu/dists/bionic/main/installer-amd64/' \
  --extra-args 'console=ttyS0,115200n8 serial'
```

With some luck, after providing a few inputs and a bit of time, we should have an Ubuntu guest. Worth pointing out is that I'm not using a block device for the disk (I don't care), and I'm putting it directly on my network (the bridge). Maybe I'll write up CentOS's [Kickstart](https://docs.centos.org/en-US/centos/install-guide/Kickstart2/) or Ubuntu's [Preseed](https://help.ubuntu.com/lts/installation-guide/amd64/apb.html) to automate the installation in the near future.

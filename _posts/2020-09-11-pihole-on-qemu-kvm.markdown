---
layout: post
title:  "Pi-hole on KVM/QEMU"
date:   2020-09-02 05:13:58 -0400
categories: pi-hole pihole kvm qemu
---

I'm going to write about this, not because it's overly complicated, but mostly because I always end up (re)Googling all of these things, regularly. The older you get, the less you tend to waste time with rote memorization, seemingly. Most, if not all, of the math profs I had reinforced this -- know the concepts, you can always look up the details. Frankly, I'm tired of looking these things up, so, here goes. If you haven't heard of Pi-hole, take a [look](https://pi-hole.net).

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

After getting logged in, installation of the Pi-hole software looks something like this:

```bash
mark@pihole1:~$ wget -c -O basic-install.sh https://install.pi-hole.net
--2020-09-10 19:27:41--  https://install.pi-hole.net/
Resolving install.pi-hole.net (install.pi-hole.net)... 167.71.111.190
Connecting to install.pi-hole.net (install.pi-hole.net)|167.71.111.190|:443... connected.
HTTP request sent, awaiting response... 302 Found
Location: https://raw.githubusercontent.com/pi-hole/pi-hole/master/automated%20install/basic-install.sh [following]
--2020-09-10 19:27:42--  https://raw.githubusercontent.com/pi-hole/pi-hole/master/automated%20install/basic-install.sh
Resolving raw.githubusercontent.com (raw.githubusercontent.com)... 151.101.64.133, 151.101.128.133, 151.101.0.133, ...
Connecting to raw.githubusercontent.com (raw.githubusercontent.com)|151.101.64.133|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 121718 (119K) [text/plain]
Saving to: ‘basic-install.sh’

basic-install.sh          100%[====================================>] 118.87K  --.-KB/s    in 0.04s

2020-09-10 19:27:43 (2.85 MB/s) - ‘basic-install.sh’ saved [121718/121718]
```

```bash
mark@pihole1:~$ sudo bash basic-install.sh
[sudo] password for mark:

  [✓] Root user check

        .;;,.
        .ccccc:,.
         :cccclll:.      ..,,
          :ccccclll.   ;ooodc
           'ccll:;ll .oooodc
             .;cll.;;looo:.
                 .. ','.
                .',,,,,,'.
              .',,,,,,,,,,.
            .',,,,,,,,,,,,....
          ....''',,,,,,,'.......
        .........  ....  .........
        ..........      ..........
        ..........      ..........
        .........  ....  .........
          ........,,,,,,,'......
            ....',,,,,,,,,,,,.
               .',,,,,,,,,'.
                .',,,,,,'.
                  ..'''.

  [i] Update local cache of available packages...

...
lots of output, time passes
...

  [i] Restarting services...
  [✓] Enabling pihole-FTL service to start on reboot...
  [✓] Restarting pihole-FTL service...
  [i] Creating new gravity database
  [i] Migrating content of /etc/pihole/adlists.list into new database
  [✓] Deleting existing list cache
  [✗] DNS resolution is currently unavailable
  [✗] DNS resolution is not available
mark@pihole1:~$
```

It'd be nice if "they" provided some sort of hash of `basic-install.sh`, but, it is what it is. Ironically, all it'd take is a DNS compromise and I'd be running some random script as root. Should probably file an issue to see if they can build this into their release process -- [here's](https://github.com/pi-hole/pi-hole) the repository. I don't expose my Pi-hole to the internet, so, I typically turn off the "admin" password like this:

```bash
mark@pihole1:~$ pihole -a -p
[sudo] password for mark:
Enter New Password (Blank for no password):
  [✓] Password Removed
```

Once you're done with this, if you're going to actually use this virtual machine, you'll probably want it to start automatically if and when the hypervisor reboots (you patch and reboot fairly regularly, right?) -- in this example, `sudo virsh autostart --pihole1` should do the trick.

Other than maybe a little bit of additional configuration, you're probably ready to go. Naturally, do a few test `dig`s against it to make sure it resolves things correctly before cutting over your whole network to it:

```bash
❯ dig @pihole1 +short reddit.com
151.101.193.140
151.101.129.140
151.101.65.140
151.101.1.140
```

Other things to consider are whether or not you want the Pi-hole to handle DHCP for you (I have something else for this), perhaps changing upstream DNS providers (I generally use either OpenDNS or Google Public DNS, or both). I have *actual* Raspberry Pis running this as well, and picked up some of [these](https://www.amazon.com/STARTO-Raspberry-320x480-Resolution-Display/dp/B07S695VQM/ref=sr_1_4?dchild=1&keywords=pitft+3.5&qid=1599820165&sr=8-4) small displays. I configure them to automatically login as the `pi` user (easily done by plinking around `raspi-config`) and launch [PADD](https://github.com/pi-hole/PADD), which gives a nice little HUD.

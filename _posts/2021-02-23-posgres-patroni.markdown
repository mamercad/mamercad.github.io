---
layout: post
title:  "PostgreSQL 10 and Patroni on Ubuntu 18.04"
date:   2021-02-23 07:55:00 -0500
categories: postgresql postgres database patroni ubuntu bionic digitalocean droplet
---

The following article continues on the previous by introducing [Patroni](https://patroni.readthedocs.io/).
The project source is located [here](https://patroni.readthedocs.io/).
Patroni will add a layer on top of our Postgres cluster enabling high availability (automatic failover, failback, etc).
I'll be using the same three nodes that I used in the last article.
In order to do its works, Patroni needs what it refers to as a DCS (dynamic configuration store).
Choices for the DCS can be Consul, etcd, etcd3, Zookeeper, or my personal favorite, Raft.
The reason that I'm fond of Raft (not that I don't like the others), is that Raft works "out of the box".
Meaning, we don't have to have an existing, or set up any new deployments as we would with the other DCSs.

Let's get to it.
Patroni is a Python project, so, let's get things installed.
Go ahead and do the following on all of your nodes:

```bash
root@db1:~# apt install -y python3 python3-dev python3-pip python3-venv python3-psycopg2
<lots of output>
```

Now, let's create a directory for Patroni's virtualenv, the virtualenv, and install Patroni with Raft support.
Same story, do it on all the nodes:

```bash
root@db1:~# mkdir -p /opt/patroni
root@db1:~# python3 -m venv /opt/patroni
root@db1:~# source /opt/patroni/bin/activate
(patroni) root@db1:~# pip3 install patroni[raft]
(patroni) root@db1:~# pip3 install psycopg2-binary
<lots of output>
```

If everything went alright, you should see stuff like this:

```bash
(patroni) root@db1:~# ls /opt/patroni/bin/patroni*
/opt/patroni/bin/patroni                  /opt/patroni/bin/patroni_wale_restore
/opt/patroni/bin/patroni_aws              /opt/patroni/bin/patronictl
/opt/patroni/bin/patroni_raft_controller
```

Now, let's do a bit of housekeeping.
I prefer to let `postgres` own all the Patroni-related bits.
And, let's create a spot for the Patroni configuration file.

```bash
(patroni) root@db1:~# mkdir -p /etc/patroni; touch /etc/patroni/patroni.yml
(patroni) root@db1:~# chown -R postgres:postgres /opt/patroni /etc/patroni
```

We could create a Postgres role for Patroni, but I'm just going to use the `postgres` role for simplicity.
Let's make sure we have a working password for it.
On the primary, do something like this:

```bash
postgres=# alter user postgres encrypted password 'hunter2';
ALTER ROLE
```

Let's make sure and update the host-based authentication file as well:

```bash
(patroni) postgres@db1:~$ tail -11 /etc/postgresql/10/main/pg_hba.conf
host    replication    replication    167.172.155.245/32      md5
host    replication    replication    161.35.13.16/32         md5
host    replication    replication    161.35.62.178/32        md5

host    all            postgres       167.172.155.245/32      md5
host    all            postgres       161.35.13.16/32         md5
host    all            postgres       161.35.62.178/32        md5

host    postgres       postgres       167.172.155.245/32      md5
host    postgres       postgres       161.35.13.16/32         md5
host    postgres       postgres       161.35.62.178/32        md5
```

After dropping the Patroni configuration files in place, we can start the leader, and then the followers:

```
(patroni) root@db1:~# su - postgres
postgres@db1:~$ source /opt/patroni/bin/activate
(patroni) postgres@db1:~$ patroni /etc/patroni/patroni.yml
2021-02-23 13:27:17,513 INFO: waiting on raft
...
```

After a short while, Raft should find consensus and we'll have something that looks like this:

```
(patroni) postgres@db1:~$ patronictl -c /etc/patroni/patroni.yml topology
+ Cluster: postgres (6932292960270556209) -----+----+-----------+
| Member | Host            | Role    | State   | TL | Lag in MB |
+--------+-----------------+---------+---------+----+-----------+
| db2    | 161.35.13.16    | Leader  | running |  9 |           |
| + db1  | 167.172.155.245 | Replica | running |  9 |         0 |
| + db3  | 161.35.62.178   | Replica | running |  9 |         0 |
+--------+-----------------+---------+---------+----+-----------+
```

This isn't finished (what ever is?); I found this in my `_drafts` and am going to `:shipit:` as is.

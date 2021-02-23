---
layout: post
title:  "PostgreSQL 10 Streaming Replication on Ubuntu 18.04"
date:   2021-02-22 22:00:00 -0500
categories: postgresql postgres database streaming replication ubuntu bionic digitalocean droplet
---

The following article will walk through setting up PostgreSQL 10 on Ubuntu 18.04.
We'll set up three nodes, one leader and a pair of followers (replica).
For the nodes, I'll just spin up some [Droplets](https://www.digitalocean.com/products/droplets/) on [DigitalOcean](https://www.digitalocean.com).
For the purposes of this article, I'll leave configuration management out and we'll do it by hand.

Let's spin up some Droplets:

```bash
❯ for i in 1 2 3; do
    doctl compute droplet create \
    --image ubuntu-18-04-x64 --size s-2vcpu-4gb \
    --region nyc1 db${i} --ssh-keys <my-ssh-key-id>
  done
```

After a few minutes, we'll be ready to go:

```bash
❯ doctl compute droplet list | awk '{print $2" "$3}'
  Name Public
  db1 167.172.155.245
  db2 161.35.13.16
  db3 161.35.62.178
```

Get a root shell and update the APT cache on all of them with `apt update`.

On the primary, `db1`, go ahead and `apt install -y postgresql-10`.
After a few minutes or so, you should have a "cluster" named `main` running version `10`.
You can see this with:

```bash
root@db1:~# pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
10  main    5432 online postgres /var/lib/postgresql/10/main /var/log/postgresql/postgresql-10-main.log
```

There are `systemd` unit files as well for the service:

```bash
root@db1:~# systemctl list-units | grep postgres | grep service
postgresql.service                                                 loaded active exited    PostgreSQL RDBMS
postgresql@10-main.service                                         loaded active running   PostgreSQL Cluster 10-main
```

Now, you should be able to poke around inside as the `postgres` user like so:

```bash
root@db1:~# su - postgres -c psql
psql (10.15 (Ubuntu 10.15-0ubuntu0.18.04.1))
Type "help" for help.

postgres=# \l
                              List of databases
   Name    |  Owner   | Encoding | Collate |  Ctype  |   Access privileges
-----------+----------+----------+---------+---------+-----------------------
 postgres  | postgres | UTF8     | C.UTF-8 | C.UTF-8 |
 template0 | postgres | UTF8     | C.UTF-8 | C.UTF-8 | =c/postgres          +
           |          |          |         |         | postgres=CTc/postgres
 template1 | postgres | UTF8     | C.UTF-8 | C.UTF-8 | =c/postgres          +
           |          |          |         |         | postgres=CTc/postgres
(3 rows)
```

Cool, let's get Postgres installed on the other two nodes with `apt install -y postgresql-10` as well.
Since they're going to be followers (replica) nodes, we'll nuke the database files afterwards.
While the other two nodes are installing Postgres, we can fixup a few settings on the primary.

Out of the box, Postgres only listens on loopback, so, let's set the `listen_addresses` parameter in the main Postgres configuration file to `*`, which means "listen on all interfaces".
To get their initial backups, as well as subsequent streaming replication, the followers need to connect to the Postgres daemon on the leader.
On Bionic, the main configuration file for Postgres is located at `/etc/postgresql/10/main/postgresql.conf`.

Here's the before (notice the `127.0.0.1:5432`):

```bash
root@db1:~# ss -nltp | grep 5432
LISTEN   0         128               127.0.0.1:5432             0.0.0.0:*        users:(("postgres",pid=3322,fd=7))
```

After fixing up the configuration file like so:

```bash
root@db1:~# ss -nltp | grep 5432
LISTEN   0         128               127.0.0.1:5432             0.0.0.0:*        users:(("postgres",pid=3322,fd=7))
```

Let's restart and check again:

```bash
root@db1:~# systemctl restart postgresql; ss -nltp | grep 5432
LISTEN   0         128                 0.0.0.0:5432             0.0.0.0:*        users:(("postgres",pid=15712,fd=7))
LISTEN   0         128                    [::]:5432                [::]:*        users:(("postgres",pid=15712,fd=8))
```

Cool, the followers should at least be able to talk to our leader at this point.

Next, let's create a role in Postgres to be used for replication:

```bash
root@db1:~# su - postgres -c psql
psql (10.15 (Ubuntu 10.15-0ubuntu0.18.04.1))
Type "help" for help.

postgres=# create role replication login replication encrypted password 'hunter2';
CREATE ROLE
```

Next, we need to add a few of rules to Postgres' hba (host-based authentication) file as such:

```
root@db1:~# tail -4 /etc/postgresql/10/main/pg_hba.conf
host  all          replication  161.35.13.16/32   md5
host  all          replication  161.35.62.178/32  md5
host  replication  replication  161.35.13.16/32   md5
host  replication  replication  161.35.62.178/32  md5
```

This is a whitespace-delimited file, the first column represents the type of authentication.
The second column is the database which can be accessed.
The third column is the user/role (notice it matches the role we created).
The fourth column is the address (these are the IP addresses of my follower Droplets).
The last column is the type of authentication.
There's lots of good information in the comments of `/etc/postgresql/10/main/pg_hba.conf`, please check it out.

Cool, let's try connecting to our leader from one of the followers:

```bash
root@db2:~# psql -U replication -h 167.172.155.245 -p 5432 -W postgres
Password for user replication:
psql: FATAL:  no pg_hba.conf entry for host "161.35.13.16", user "replication", database "postgres", SSL on
FATAL:  no pg_hba.conf entry for host "161.35.13.16", user "replication", database "postgres", SSL of
```

Ah, we need to reload.
We can do this as we did before, with `systemctl restart postgresql`.
Or, we can do `pg_ctlcluster 10 main reload`.
Or, we can do it like this:

```bash
postgres=# select pg_reload_conf();
 pg_reload_conf
----------------
 t
(1 row)
```

After reloading Postgres, we should be able to get in:

```
root@db2:~# psql -U replication -h 167.172.155.245 -p 5432 -W postgres
Password for user replication:
psql (10.15 (Ubuntu 10.15-0ubuntu0.18.04.1))
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
Type "help" for help.

postgres=>
```

Might as well make sure we can do it from the other follower:

```bash
root@db3:~# psql -U replication -h 167.172.155.245 -p 5432 -W postgres
Password for user replication:
psql (10.15 (Ubuntu 10.15-0ubuntu0.18.04.1))
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
Type "help" for help.

postgres=>
```

Cool, we have network connectivity, and, application-level connectivity.

Alright, let's stop the database and nuke the data directory on the first *follower*.
We could use `pg_dropcluster 10 main`, but, that'd get rid of the configuration files, and we'd have to recreate them.
Doing it this way is fast and easy, we're basically leaving "all but the data" around, and this is exactly what we want for a follower (we'll stream a backup from the primary shortly).
Don't forget to stop Postgres first so that files aren't in use.

```bash
root@db2:~# systemctl stop postgresql; rm -fr /var/lib/postgresql/10/main/*
root@db2:~# pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
10  main    5432 down   postgres /var/lib/postgresql/10/main /var/log/postgresql/postgresql-10-main.log
```

Alright, let's create a replication slot on the primary:

```bash
postgres=# select * from pg_create_physical_replication_slot('db2');
 slot_name | lsn
-----------+-----
 db2       |
(1 row)
```

Let's make sure a few WAL (write-ahead log) and replication directives are set on the primary:

```bash
wal_level = replica
archive_mode = on
max_wal_senders = 10
wal_keep_segments = 32
max_replication_slots = 10
hot_standby = on
hot_standby_feedback = on
```

If you needed to set/change any of these, don't forget to restart/reload Postgres.
Also, this is by no means "ready for production", it's just a PoC.
Specifically, note that I'm setting `archive_mode`, but, I'm not mentioning `archive_command`.
I'm going to do that annoying "this exercise is left for the reader".
As an example, you *could* archive your WALs with `rsync` to a shared location, you could use NFS, you could archive them in [Spaces](https://www.digitalocean.com/products/spaces/), etc.

Cool, let's stream a backup now from the primary onto the first follower (make sure you're the `postgres` user):

```bash
postgres@db2:~$ pg_basebackup -h 167.172.155.245 -p 5432 -U replication -D /var/lib/postgresql/10/main --progress -W --slot db2 --wal-method=stream --write-recovery-conf
Password:
23663/23663 kB (100%), 1/1 tablespace

postgres@db2:~$ pg_ctlcluster 10 main start
Warning: the cluster will not be running as a systemd service. Consider using systemctl:
  sudo systemctl start postgresql@10-main

postgres@db2:~$ pg_lsclusters
Ver Cluster Port Status          Owner    Data directory              Log file
10  main    5432 online,recovery postgres /var/lib/postgresql/10/main /var/log/postgresql/postgresql-10-main.log
```

Cool, notice that in addition to `online` there's also a status of type `recovery`.

So, check this out:

```bash
postgres@db2:~$ psql
psql (10.15 (Ubuntu 10.15-0ubuntu0.18.04.1))
Type "help" for help.

postgres=# create database foo;
ERROR:  cannot execute CREATE DATABASE in a read-only transaction
```

Ahhh, we have a read-only replica, and that's exactly what we want.

Now, let's do the same statement on the primary and make sure it propagates:

```bash
postgres=# create database foo;
CREATE DATABASE
```

Cool, now, check the follower:

```bash
postgres=# \l
                              List of databases
   Name    |  Owner   | Encoding | Collate |  Ctype  |   Access privileges
-----------+----------+----------+---------+---------+-----------------------
 foo       | postgres | UTF8     | C.UTF-8 | C.UTF-8 |
 postgres  | postgres | UTF8     | C.UTF-8 | C.UTF-8 |
 template0 | postgres | UTF8     | C.UTF-8 | C.UTF-8 | =c/postgres          +
           |          |          |         |         | postgres=CTc/postgres
 template1 | postgres | UTF8     | C.UTF-8 | C.UTF-8 | =c/postgres          +
           |          |          |         |         | postgres=CTc/postgres
(4 rows)
```

Cool, the `foo` database is automatically replicated to our follower.
Lastly, we need to add our second follower to the cluster.
The steps will be the same as we've done for our first follower (don't forget to create a new replication slot).

```bash
postgres=# select * from pg_create_physical_replication_slot('db3');
 slot_name | lsn
-----------+-----
 db3       |
(1 row)
```

```bash
postgres@db3:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
10  main    5432 online postgres /var/lib/postgresql/10/main /var/log/postgresql/postgresql-10-main.log

postgres@db3:~$ pg_ctlcluster 10 main stop
Warning: stopping the cluster using pg_ctlcluster will mark the systemd unit as failed. Consider using systemctl:
  sudo systemctl stop postgresql@10-main

postgres@db3:~$ rm -fr /var/lib/postgresql/10/main/*

pg_basebackup: removing contents of data directory "/var/lib/postgresql/10/main"

postgres@db3:~$ pg_basebackup -h 167.172.155.245 -p 5432 -U replication -D /var/lib/postgresql/10/main --progress -W --slot db3 --wal-method=stream --write-recovery-conf
Password:
31291/31291 kB (100%), 1/1 tablespace

postgres@db3:~$ grep ^hot_standby /etc/postgresql/10/main/postgresql.conf
hot_standby = on

postgres@db3:~$ pg_ctlcluster 10 main start
Warning: the cluster will not be running as a systemd service. Consider using systemctl:
  sudo systemctl start postgresql@10-main

postgres@db3:~$ pg_lsclusters
Ver Cluster Port Status          Owner    Data directory              Log file
10  main    5432 online,recovery postgres /var/lib/postgresql/10/main /var/log/postgresql/postgresql-10-main.log

postgres@db3:~$ psql
psql (10.15 (Ubuntu 10.15-0ubuntu0.18.04.1))
Type "help" for help.

postgres=# \l
                              List of databases
   Name    |  Owner   | Encoding | Collate |  Ctype  |   Access privileges
-----------+----------+----------+---------+---------+-----------------------
 foo       | postgres | UTF8     | C.UTF-8 | C.UTF-8 |
 postgres  | postgres | UTF8     | C.UTF-8 | C.UTF-8 |
 template0 | postgres | UTF8     | C.UTF-8 | C.UTF-8 | =c/postgres          +
           |          |          |         |         | postgres=CTc/postgres
 template1 | postgres | UTF8     | C.UTF-8 | C.UTF-8 | =c/postgres          +
           |          |          |         |         | postgres=CTc/postgres
(4 rows)
```

All done!

On the primary, we can verify things like this (leave of the fields for more good stuff):

```bash
postgres=# select pid,usename,application_name,client_addr,state,sync_state from pg_stat_replication ;
  pid  |   usename   | application_name |  client_addr  |   state   | sync_state
-------+-------------+------------------+---------------+-----------+------------
 16422 | replication | walreceiver      | 161.35.13.16  | streaming | async
 16565 | replication | walreceiver      | 161.35.62.178 | streaming | async
(2 rows)
```

Hopefully, in the next article, I'll show you an easy way of doing failover/back.

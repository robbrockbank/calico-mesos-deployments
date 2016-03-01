<!--- master only -->
> ![warning](images/warning.png) This document applies to the HEAD of the calico-mesos-deployments source tree.
>
> View the calico-mesos-deployments documentation for the latest release [here](https://github.com/projectcalico/calico-mesos-deployments/blob/0.26.0%2B1/README.md).
<!--- else
> You are viewing the calico-mesos-deployments documentation for release **release**.
<!--- end of master only -->

# Manually Deploying a Dockerized Mesos Cluster with Calico

In these instructions, we will run a Mesos Cluster where all cluster services run as Docker containers.  This speeds deployment and will prevent pesky issues like incompatible dependencies.  At the end, we will have a multi host mesos cluster that looks like the following:

Master Host:
 * zookeeper
 * etcd
 * mesos-master
 * marathon (Mesos framework)

Agent Host:
 * mesos-agent
 * calico

>We'll concentrate on getting Mesos and Calico up and running as quickly as possible.  This means leaving out the details of how to configure highly-available services.  Instead, we'll install Zookeeper, etcd, and the Mesos Master on the same "master" node.

# Prerequisites
## Centos
These instructions are designed to run on CentOS/Red Hat Enterprise Linux 7 but, other than the initial commands to configure Docker, should work on any Linux distribution that supports Docker 1.7+ and `systemd`.

>If your distribution does not support `systemd`, you will need to create initialization files for each of the services.  These should be straightforward based on the included `.service` files, but talk to us on the [Calico Users' Slack](https://calicousers-slackin.herokuapp.com/) if you want some assistance.  If you write init files for a new system, share the love!  PRs are welcome :)

Some of the docker containers started in this guide will need permission to modify the host's networking. SELinux blocks this by default, so edit `/etc/selinux/config` to set it to permissive on boot:

    SELINUX=permissive

Disable it for your current session with the following command:

    setenforce permissive

## Docker
Since this is a dockerized deployment, you will need Docker installed on every Master and Agent in your cluster.
[Follow Docker's Centos installation guide](https://docs.docker.com/engine/installation/centos/) for information on how to get Docker installed.

## FQDN
These instructions assume each host can reach other hosts using their fully qualified domain names (FQDN).  To check the FQDN on a host use

    hostname -f

Then attempt to ping that name from other servers.

Also important are that Calico and Mesos have the same view of the (non-fully-qualified) hostname.  In particular, the value returned by

    hostname

must be unique for each node in your cluster.  Both Calico and Mesos use this value to identify the host.

## SSL
The Marathon build we'll be using requires SSL enabled in Mesos on each Master and Slave in order to pull docker images from dockerhub. The systemd services we'll be using in this guide are already configured to search for the appropriate SSL keys in `/certs`. Run the following commands on each Master and slave to place those certs:

      sudo mkdir /keys
      sudo openssl genrsa -f4  -out /keys/key.pem 4096
      sudo openssl req -new -batch -x509  -days 365 -key /keys/key.pem -out /keys/cert.pem

# Getting Started
## Master Host
### 1. Download Unit Files
We'll be using the systemd files in this repo, so grab the tar:

    curl -O https://github.com/projectcalico/calico-mesos-deployments/archive/master.tar.gz
    tar -xvf calico-mesos-deployments-master.tar.gz
    cd calico-mesos-deployments-master/units/

### 2. Zookeeper
The zookeeper service is configured to bind to port 2181 on the host. If you have a firewall enabled, open this port. If you are using firewalld, run the following commands:

    sudo firewall-cmd --zone=public --add-port=2181/tcp --permanent
    sudo systemctl restart firewalld

Next, download and start the Zookeeper image, as well as the systemd service which will ensure Zookeeper is kept running:

    docker pull jplock/zookeeper:3.4.5
    sudo cp zookeeper.service /usr/lib/systemd/system/
    sudo systemctl enable zookeeper.service
    sudo systemctl start zookeeper.service

Check that the Zookeeper docker container is running with docker and systemd:

    docker ps | grep zookeeper
    sudo systemctl status zookeeper

### 3. Mesos Master
The mesos-master service is configured to bind to port 5050 on the host. If you have a firewall enabled, open this port. If you are using firewalld, run the following commands:

    sudo firewall-cmd --zone=public --add-port=5050/tcp --permanent
    sudo systemctl restart firewalld

Before running the Mesos-Master process, we'll set the IP address of the Master to connect to the Mesos cluster.  Run the following command, replacing `<MASTER_IP>` with the Master's IP address.

    sudo sh -c 'echo IP=<MASTER_IP> > /etc/sysconfig/mesos-master'

Then create and enable the `mesos-master` unit, which starts a Docker container running Mesos-Master:

    docker pull calico/mesos-calico
    sudo cp mesos-master.service /usr/lib/systemd/system/
    sudo systemctl enable mesos-master.service
    sudo systemctl start mesos-master.service

Check that the Mesos Master docker container is running with docker and systemd:

    docker ps | grep mesos-master
    sudo systemctl status mesos-master

### 4. Etcd
The etcd service is configured to bind to port 2379 and 4001 on the host. If you have a firewall enabled, open these ports. If you are using firewalld, run the following commands:

    sudo firewall-cmd --zone=public --add-port=2379/tcp --permanent
    sudo firewall-cmd --zone=public --add-port=4001/tcp --permanent
    sudo systemctl restart firewalld

etcd needs your fully qualified domain name to start correctly.  The included unit file looks for this value in `/etc/sysconfig/etcd`.

    sudo sh -c 'echo FQDN=`hostname -f` > /etc/sysconfig/etcd'
    docker pull quay.io/coreos/etcd:v2.2.0
    sudo cp etcd.service /usr/lib/systemd/system/
    sudo systemctl enable etcd.service
    sudo systemctl start etcd.service

Check that the etcd docker container is running with docker and systemd:

    docker ps | grep etcd
    sudo systemctl status etcd

### 5. Marathon
The Marathon service is configured to bind to port 8080 on the host. If you have a firewall enabled, open this port. If you are using firewalld, run the following commands:

    sudo firewall-cmd --zone=public --add-port=8080/tcp --permanent
    sudo systemctl restart firewalld

Next, start Marathon:

    docker pull mesosphere/marathon:v0.14.0
    sudo cp marathon.service /usr/lib/systemd/system/
    sudo systemctl enable marathon.service
    sudo systemctl start marathon.service

Check that the Marathon docker container is running with docker and systemd:

    docker ps | grep marathon
    sudo systemctl status marathon

## Agent Host
### 1. Download Unit Files
We'll be using the systemd files in this repo, so grab the tar:

    curl -O https://github.com/projectcalico/calico-mesos-deployments/archive/master.tar.gz
    tar -xvf calico-mesos-deployments-master.tar.gz
    cd calico-mesos-deployments-master/units/

### 2. Calico
The Calico service is configured to bind to port 179 on the host. If you have a firewall enabled, open this port. If you are using firewalld, run the following commands:

    sudo firewall-cmd --zone=public --add-port=179/tcp --permanent
    sudo systemctl restart firewalld

`calicoctl` is a small CLI tool to control your Calico network.  It's used to start Calico services on your compute host, as well as inspect and modify Calico configuration.

    curl -L -O https://github.com/projectcalico/calico-containers/releases/download/v0.17.0/calicoctl
    chmod +x calicoctl
    sudo mv calicoctl /usr/bin/

You can learn more about `calicoctl` by running `calicoctl --help`.

You'll need to configure Calico with the correct location of the etcd service.  In the following line, replace `<MASTER_IP>` with the IP address of the Master node.

    sudo sh -c 'echo ETCD_AUTHORITY=<MASTER_IP>:4001 > /etc/sysconfig/calico'

Then, enable the Calico service via `systemd`

    docker pull calico/node:v0.17.0
    sudo cp calico.service /usr/lib/systemd/system/
    sudo systemctl enable calico.service
    sudo systemctl start calico.service

Verify Calico is running

    sudo systemctl status calico
    docker ps | grep calico-node
    calicoctl status

### 3. Mesos-Agent
The Mesos-Agent service is configured to bind to port 5051 on the host. If you have a firewall enabled, open this port. If you are using firewalld, run the following commands:

    sudo firewall-cmd --zone=public --add-port=5051/tcp --permanent
    sudo systemctl restart firewalld

Use the following commands to tell the Mesos Agent where to find Zookeeper.  The Mesos Agent uses Zookeeper to keep track of the current Mesos Master.  We installed it on the same host as the Mesos Master earlier, so substitute the name or IP of that host for `<ZOOKEEPER_IP>`:

    sudo sh -c 'echo ZK=<ZOKEEPER_IP> > /etc/sysconfig/mesos-agent'

You also need to specify the IP address of the Agent to connect to the Mesos cluster.  Run the following command, replacing `<AGENT_IP>` with the Agent's IP address.

    sudo sh -c 'echo IP=<AGENT_IP> >> /etc/sysconfig/mesos-agent'

Then, enable the Mesos Agent service

    docker pull calico/mesos-calico
    sudo cp mesos-agent.service /usr/lib/systemd/system/
    sudo systemctl enable mesos-agent.service
    sudo systemctl start mesos-agent.service

Check that the Mesos Agent docker container is running with docker and systemd:

    docker ps | grep mesos-agent
    sudo systemctl status mesos-agent

## Next steps
See [Our Guide on Using Calico-Mesos](UsingCalicoMesos.md) for info on how to test your cluster and start launching tasks networked with Calico.

[calico]: http://projectcalico.org
[mesos]: https://mesos.apache.org/
[net-modules]: https://github.com/mesosphere/net-modules

# Deploying a Vagrant Dockerized Mesos Cluster with Calico
This guide will start a running Mesos cluster with Calico Networking using a simple `vagrant up`. Note: This guide serves as a quick demo, but is not recommended for production use as it creates a Mesos Master and Agent on the same hypervisor.

If you are looking for a guide to set up a POC in your lab, see the [Manual Dockerized Deployment guide](DockerizedDeployment.md).

This guide will start two VMs on your hypervisor with the following layout:
### Master
 * **OS**: `Centos`
 * **Hostname**: `calico-01`
 * **IP**: `172.18.8.101`
 * **Docker Containers**:
	 * `mesos-master` - (`calico/mesos-calico`)
	 * `etcd` - (`quay.io/coreos/etcd`)
	 * `zookeeper` - (`jplock/zookeeper`)
	 * `marathon` - (`mesosphere/marathon`)

### Agent
 * **OS**: `Centos`
 * **Hostname**: `calico-02`
 * **IP**: `172.18.8.102`
 * **Docker Containers**:
	 * `mesos-agent` - (`calico/mesos-calico`)
	 * `calico-node` - (`calico/node`)

## Prerequisites

This guide requires a hypervisor with the following specs:

 * [VirtualBox][virtualbox] to host the Mesos master and slave virtual machines
 * [Vagrant][vagrant] to run the script that provisions the Virtual Machines
 * 4+ GB memory
 * 2+ CPU
 * ~16GB available storage space


## Getting Started
1. You must run the vagrant script from its location in the repo as it adds the unit files in its path to each host. First, download it:
```
curl -O https://github.com/projectcalico/calico-mesos-deployments/archive/0.27.0%2B1.tar.gz
tar -xvf calico-mesos-deployments-0.27.0%2B1.tar.gz
cd calico-mesos-deployments-0.27.0-1
```

2. Then launch the Vagrant demo:
```
vagrant up
```

>Note: the script may take up to 30 minutes to complete as it creates the two virtual machines and pulls the docker relevant container images for each.

You can log into each machine by running:
```
vagrant ssh <HOSTNAME>
```

### Adding More Agents
You can modify the script to use multiple agents. To do this, modify the `num_instances` variable
in the `Vagrantfile` to be greater than `2`.  The first instance created is the master instance, every 
additional instance will be an agent instance.

Every agent instance will take similar form to the agent instance above:

 * **OS**: `Centos`
 * **Hostname**: `calico-0X`
 * **IP**: `172.18.8.10X`
 * **Docker Containers**:
	 * `mesos-agent` - `calico/mesos-calico`
	 * `calico-node` - `calico/node`

where `X` is the instance number.
 
Each agent instance will require additional storage and memory resources.

## Next steps
See [Our Guide on Using Calico-Mesos](UsingCalicoMesos.md) for info on how to test your cluster and start launching tasks networked with Calico.

[virtualbox]: https://www.virtualbox.org/
[vagrant]: https://www.vagrantup.com/
[![Analytics](https://ga-beacon.appspot.com/UA-52125893-3/calico-containers/docs/mesos/DockerizedVagrant.md?pixel)](https://github.com/igrigorik/ga-beacon)

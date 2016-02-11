# Calico-Mesos Deployments
**Mesos Packages with Calico**

- For information on Calico, see [projectcalico.org](http://projectcalico.org)
- For more information on Calico's Mesos integraiton, see [github.com/projectcalico/calico-mesos][calico-mesos]
- Still have questions? Contact us on the #Mesos channel of [Calico's Slack][calico-slack].

### Mesos Version Compatability
Calico support is actively being developed. Use the following information to ensure you choose the right version:
- **Mesos 0.27:** Recommended. Adds calico Networking for Docker Images (via unified containerizer)
- **Mesos 0.26:** Supported. Calico supported Networking of Mesos Tasks
- **Mesos 0.25:** Deprecated. Calico works with Mesos 0.25, but we recommend against using it as there aren't any Frameworks (including Marathon) which support the Networkinfo specs from 0.25 (which were modified for 0.26)
- **Mesos 0.24:** Unsupported. Calico works as a proof of concept, but is no longer supported.

# Getting Started
We offer several ways to get going. Choose the option below that best matches your needs.

## a.) [Dockerized Demo with Vagrant](docs/DockerizedVagrant.md)
**Automatic Install through Vagrant to start a working demo cluster, fast.**

See what a running Mesos cluster with Calico looks like with just a simple `vagrant up` by following the Vagrant Dockerized Mesos Guide. Note: This guide serves as a quick demo, but is not recommended for production use as it creates a Mesos Master and Agent on the same hypervisor.

## b.) [Manual Dockerized Deployment (Recommended)](docs/DockerizedDeployment.md)
**Manual install of dockerized services for easier updates**

For a better understanding of the components in a Mesos cluster with Calico, and the ability to easily customize and update them, follow the [Dockerized Mesos Guide](docs/DockerizedDeployment.md). This deployment is similar to the Vagrant Dockerized demo, but is manually deployed across multiple hosts to simulate a full Mesos Cluster in your data center. The components have been dockerized to allow for easier delivery of updates to Mesos, Netmodules, and calico-mesosand debugging.

**We highly recommend using this deployment as it is the fastest way to receive frequent updates to Netmodules and Calico**

## c.) [RPM Installation](docs/RpmInstallCalicoMesos.md)
If running Mesos services in docker containers doesn't suit your needs, the Calico-Mesos RPM Installation Guide serves as the next fastest way to get up and running by installing Mesos and Netmodules directly onto your system. 

### d.) [Manual Compilation and Installation](docs/ManualInstallCalicoMesos.md)
For an in-depth walkthrough of the full compilation and installation of Mesos, netmodules, and calico, see the Calico-Mesos Manual Install Guide.

# [Next Steps: Launching Tasks](docs/UsingCalicoMesos.md)

[calico-mesos]: https://github.com/projectcalico/calico-mesos/
[calico-slack]: https://calicousers-slackin.herokuapp.com/
[![Analytics](https://ga-beacon.appspot.com/UA-52125893-3/calico-containers/docs/mesos/README.md?pixel)](https://github.com/igrigorik/ga-beacon)

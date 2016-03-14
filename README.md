# Calico-Mesos Deployments
This repo provides RPMs for installing Calico Networking for your Mesos Cluster, documentation on how to get up and running, and how to launch calico networked tasks.

<!--- master only -->
> ![warning](docs/images/warning.png) This document applies to the HEAD of the calico-mesos-deployments source tree.
>
> View the calico-mesos-deployments documentation for the latest release [here](https://github.com/projectcalico/calico-mesos-deployments/blob/0.27.0%2B2/README.md).
<!--- else
> You are viewing the calico-mesos-deployments documentation for release **release**.
<!--- end of master only -->

We recommend browsing the docs for the [latest release](https://github.com/projectcalico/calico-mesos-deployments/releases/latest).

- For information on Calico, see [projectcalico.org](http://projectcalico.org)
- For more information on Calico's Mesos integraiton, see [github.com/projectcalico/calico-mesos][calico-mesos]
- Still have questions? Contact us on the #Mesos channel of [Calico's Slack][calico-slack].

## Demo
- [Automatic Vagrant Install For a Running Demo Cluster, Fast](docs/DockerizedVagrant.md): Following this guide to see what a running Mesos cluster with Calico looks with a simple `vagrant up` 

## Install Calico with the Docker Containerizer
Calico is capable of networking Docker tasks launched via the Docker Containerizer by networking them with the calico libnetwork plugin. This networking solution is compatible with official Mesos RPMs and can be added to your existing mesos cluster.
- The [Install Calico for Docker Containerizer](docs/CalicoWithTheDockerContainerizer.md) guide details how to configure docker and calico in your cluster.

## Install Calico with the Mesos/Unified Containerizer
Calico works as a net-modules compatible networking plugin for mesos, able to natively network standard Mesos Tasks launched via the Mesos Containerizer. Currently, this requires a version of Mesos built with unbundled 3rd party dependencies. The following two guides provide information on building and installing a compatible Mesos with netmodules, and detail how to add Calico to it:
- [RPM Installation](docs/RpmInstallCalicoMesos.md): These RPMs include a custom build of Mesos bundled with Netmodules. 
- [Manual Compilation and Installation](docs/ManualInstallCalicoMesos.md): For an in-depth walkthrough of the full compilation and installation of Mesos, netmodules, and calico, see the Calico-Mesos Manual Install Guide.


[calico-mesos]: https://github.com/projectcalico/calico-mesos/
[calico-slack]: https://calicousers-slackin.herokuapp.com/
[![Analytics](https://calico-ga-beacon.appspot.com/UA-52125893-3/calico-containers/docs/mesos/README.md?pixel)](https://github.com/igrigorik/ga-beacon)

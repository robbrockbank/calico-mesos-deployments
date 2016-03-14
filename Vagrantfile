# -*- mode: ruby -*-
# vi: set ft=ruby :

# Size of the cluster created by Vagrant
num_instances = 2

# VM Basename
instance_name_prefix="calico-mesos"

# Version of mesos to install from official mesos repo
mesos_version = "0.27.0"

# Calico version (for calicoctl and calico-node)
calico_node_ver = "v0.17.0"
calicoctl_url = "https://github.com/projectcalico/calico-containers/releases/download/#{calico_node_ver}/calicoctl"

mesos_netmodules_rpm_url = "https://github.com/projectcalico/calico-mesos-deployments/releases/download/0.27.0%2B2/mesos-netmodules-rpms.tar"
calico_mesos_rpm_url = "https://github.com/projectcalico/calico-mesos-deployments/releases/download/0.27.0%2B2/calico-mesos.rpm"

Vagrant.configure("2") do |config|
  config.vm.box = 'centos/7'
  config.ssh.insert_key = false

  # The vagrant centos:7 box has a bug where it automatically tries to sync /home/vagrant/sync using rsync, so disable it:
  # https://github.com/mitchellh/vagrant/issues/6154#issuecomment-135949010
  config.vm.synced_folder ".", "/home/vagrant/sync", disabled: true

  config.vm.provider :virtualbox do |vbox|
    # On VirtualBox, we don't have guest additions or a functional vboxsf
    # in CoreOS, so tell Vagrant that so it can be smarter.
    vbox.functional_vboxsf = false
    vbox.check_guest_additions = false
    vbox.memory = 2048
    vbox.cpus = 2
  end

  config.vm.provider :vsphere do |vsphere, override|
    # The following section sets login credentials for the vagrant-vsphere
    # plugin to allow use of this Vagrant script in vSphere.
    # This is not recommended for demo purposes, only internal testing.
    override.vm.box_url = 'file://dummy.box'
    vsphere.host =                  ENV['VSPHERE_HOSTNAME']
    vsphere.compute_resource_name = ENV['VSPHERE_COMPUTE_RESOURCE_NAME']
    vsphere.template_name =         ENV['VSPHERE_TEMPLATE_NAME']
    vsphere.user =                  ENV['VSPHERE_USER']
    vsphere.password =              ENV['VSPHERE_PASSWORD']
    vsphere.insecure=true
    vsphere.customization_spec_name = 'vagrant-vsphere'
  end

  master_ip = "172.24.197.101"

  # Set up each box
  (1..num_instances).each do |i|
    vm_name = "%s-%02d" % [instance_name_prefix, i]
    config.vm.define vm_name do |host|
      # Provision the FQDN
      host.vm.hostname = vm_name

      # Assign IP and prepend IP/hostname pair to /etc/hosts for correct FQDN IP resolution
      ip = "172.24.197.#{i+100}"
      host.vm.network :private_network, ip: ip

      # Selinux => permissive
      host.vm.provision :shell, inline: "setenforce permissive"

      # Generate certs
      host.vm.provision :shell, inline: "mkdir /keys"
      host.vm.provision :shell, inline: "openssl genrsa -f4  -out /keys/key.pem 4096"
      host.vm.provision :shell, inline: "openssl req -new -batch -x509  -days 365 -key /keys/key.pem -out /keys/cert.pem"

      # Master
      if i == 1
        # Add official Mesos Repos
        host.vm.provision :shell, inline: "rpm -Uvh http://repos.mesosphere.com/el/7/noarch/RPMS/mesosphere-el-repo-7-1.noarch.rpm"
        host.vm.provision :shell, inline: "yum -y install mesos-#{mesos_version} marathon mesosphere-zookeeper etcd"
        
        # Zookeeper
        host.vm.provision :shell, inline: "systemctl start zookeeper"

        # Mesos-Master
        host.vm.provision :shell, inline: "sh -c 'echo #{master_ip} > /etc/mesos-master/hostname'"
        host.vm.provision :shell, inline: "sh -c 'echo #{ip} > /etc/mesos-master/ip'"
        host.vm.provision :shell, inline: "systemctl start mesos-master"

        # Marathon
        host.vm.provision :shell, inline: "systemctl start marathon"

        # etcd
        host.vm.provision :shell, inline: "sh -c 'echo ETCD_LISTEN_CLIENT_URLS=\"http://0.0.0.0:2379\" >> /etc/etcd/etcd.conf'"
        host.vm.provision :shell, inline: "sh -c 'echo ETCD_ADVERTISE_CLIENT_URLS=\"http://#{master_ip}:2379\" >> /etc/etcd/etcd.conf'"        
        host.vm.provision :shell, inline: "systemctl enable etcd.service"
        host.vm.provision :shell, inline: "systemctl start etcd.service"
      end

	  # Agents
      if i > 1
        # Provision with docker, and download the calico-node docker image
        host.vm.provision :docker, images: ["calico/node:#{calico_node_ver}"]
      
        # Install epel packages
        host.vm.provision :shell, inline: "yum install -y epel-release"
        
        # Calico-Mesos RPM
        # Check if user has set CALICO_MESOS_RPM_PATH environment variable 
        if ENV.key?("CALICO_MESOS_RPM_PATH")
          # If so, then copy the file from that location onto the agent.
          # The specified file should be the RPM produced by running `make rpm` 
          # in this (the calico-mesos-deployments). 
          host.vm.provision "file", source: ENV['CALICO_MESOS_RPM_PATH'], destination: "calico-mesos.rpm"
        else
          # If that variable is not set, download the latest release from github.
          host.vm.provision :shell, inline: "curl -L -O #{calico_mesos_rpm_url}"
        end
        host.vm.provision :shell, inline: "yum install -y calico-mesos.rpm"
      
        # Configure calico
        host.vm.provision :shell, inline: "sh -c 'echo MASTER=zk://#{master_ip}:2181/mesos/ > /etc/default/mesos-slave'"
        host.vm.provision :shell, inline: "sh -c 'echo ETCD_AUTHORITY=#{master_ip}:2379 >> /etc/default/mesos-slave'"
        host.vm.provision :shell, inline: "systemctl start calico-mesos.service"

        # Mesos-Netmodules RPMS
        # Check if user has set MESOS_NETMODULES_TAR_PATH environment variable 
        if ENV.key?("MESOS_NETMODULES_TAR_PATH")
          # If so, then copy the file from that location onto the agent.
          # The specified file should be a tar containing a folder named
          # 'mesos-netmodules-rpm'. (This can be produced by running `make rpm`
          # in the net-modules repo.)
          host.vm.provision "file", source: ENV['MESOS_NETMODULES_TAR_PATH'], destination: "mesos-netmodules-rpms.tar"
        else
          # If that variable is not set, download the latest release from github.
          host.vm.provision :shell, inline: "curl -L -O #{mesos_netmodules_rpm_url}"
        end
        # Untar mesos-netmodules-rpms.tar and install its contianing RPMs
        host.vm.provision :shell, inline: "tar -xvf mesos-netmodules-rpms.tar"
        host.vm.provision :shell, inline: "yum install -y mesos-netmodules-rpms/*.rpm"

        # Configure and start mesos-slave
        host.vm.provision :shell, inline: "sh -c 'echo #{ip} > /etc/mesos-slave/ip'"
        host.vm.provision :shell, inline: "sh -c 'echo #{ip} > /etc/mesos-slave/hostname'"
        host.vm.provision :shell, inline: "systemctl start mesos-slave.service"
      end
    end
  end
end

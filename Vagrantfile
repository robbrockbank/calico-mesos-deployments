# -*- mode: ruby -*-
# vi: set ft=ruby :

# Size of the cluster created by Vagrant
num_instances = 3

# VM Basename
instance_name_prefix="calico-mesos"

# Version of mesos to install from official mesos repo
mesos_version = "0.28.0"

# The calicoctl download URL.
calicoctl_url = "http://www.projectcalico.org/builds/calicoctl"

# The version of the calico docker images to install.  This is used to pre-load
# the calico/node and calico/node-libnetwork images which slows down the
# install process, but speeds up the tutorial.
#
# This version should match the version required by calicoctl installed from
# calicoctl_url.
calico_node_ver = "latest"
calico_libnetwork_ver = "latest"

# Define the install script which restarts docker with flags to use a cluster-store
$configure_docker=<<SCRIPT
mkdir -p /etc/systemd/system/docker.service.d/
cat <<EOF > /etc/systemd/system/docker.service.d/docker.conf
[Service]
ExecStart=
ExecStart=/usr/bin/docker daemon -H fd:// --cluster-store=etcd://${1}:2379
EOF
systemctl daemon-reload
systemctl restart docker.service
SCRIPT

# Define the install script which installs a systemd service file which
# launches calico-libnetwork
$start_calico=<<SCRIPT

# Create the /etc/calico directory where we write out some config.
mkdir /etc/calico

# Write out the environment variable file
cat <<EOF > /etc/calico/calico.env
ETCD_AUTHORITY=${1}:2379
ETCD_SCHEME=http
ETCD_CA_FILE=""
ETCD_CERT_FILE=""
ETCD_KEY_FILE=""
EOF

# Write out the Calico systemd file.
cat <<EOF > /usr/lib/systemd/system/calico.service
﻿[Unit]
Description=calico-node
After=docker.service
Requires=docker.service

[Service]
EnvironmentFile=/etc/calico/calico.env
ExecStartPre=-/usr/bin/docker rm -f calico-node
ExecStart=/usr/bin/calicoctl node --detach=false
ExecStop=-/usr/bin/docker stop calico-node

[Install]
WantedBy=multi-user.target
EOF

# Write out the Calico-libnetwork systemd file.
cat <<EOF > /usr/lib/systemd/system/calico-libnetwork.service
﻿[Unit]
Description=calico-libnetwork
After=docker.service
Requires=docker.service

[Service]
EnvironmentFile=/etc/calico/calico.env
ExecStartPre=-/usr/bin/docker rm -f calico-libnetwork
ExecStart=/usr/bin/docker run --privileged --net=host \
 -v /run/docker/plugins:/run/docker/plugins \
 --name=calico-libnetwork \
 -e ETCD_AUTHORITY=${ETCD_AUTHORITY} \
 -e ETCD_SCHEME=${ETCD_SCHEME} \
 -e ETCD_CA_CERT_FILE=${ETCD_CA_CERT_FILE} \
 -e ETCD_CERT_FILE=${ETCD_CERT_FILE} \
 -e ETCD_KEY_FILE=${ETCD_KEY_FILE} \
 calico/node-libnetwork:latest
ExecStop=-/usr/bin/docker stop calico-libnetwork

[Install]
WantedBy=multi-user.target
EOF

# Start both Calico services
systemctl start calico.service
systemctl start calico-libnetwork.service
SCRIPT

$install_mesos_dns=<<SCRIPT
curl -LO https://github.com/mesosphere/mesos-dns/releases/download/v0.5.0/mesos-dns-v0.5.0-linux-amd64
mv mesos-dns-v0.5.0-linux-amd64 /usr/bin/mesos-dns
chmod +x /usr/bin/mesos-dns
mkdir /etc/mesos-dns
cat <<EOF > /etc/mesos-dns/mesos-dns.json
{
  "zk": "zk://${1}:2181/mesos/",
  "masters": ["${1}:5050"],
  "refreshSeconds": 5,
  "ttl": 60,
  "domain": "mesos",
  "port": 53,
  "resolvers": ["8.8.8.8"],
  "timeout": 5,
  "httpon": true,
  "dsnon": true,
  "httpport": 8123,
  "externalon": true,
  "listener": "0.0.0.0",
  "SOAMname": "root.ns1.mesos",
  "SOARname": "ns1.mesos",
  "SOARefresh": 60,
  "SOARetry":   600,
  "SOAExpire":  86400,
  "SOAMinttl": 60,
  "IPSources": ["netinfo", "mesos", "host"]
}
EOF

cat <<EOF > /usr/lib/systemd/system/mesos-dns.service
[Unit]
Description=mesos-dns

[Service]
ExecStart=/usr/bin/mesos-dns -config=/etc/mesos-dns/mesos-dns.json

[Install]
WantedBy=multi-user.target
EOF
systemctl start mesos-dns
SCRIPT


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

      # Add official Mesos Repos and install Mesos.
      host.vm.provision :shell, inline: "sudo rpm -Uvh http://repos.mesosphere.io/el/7/noarch/RPMS/mesosphere-el-repo-7-1.noarch.rpm"
      host.vm.provision :shell, inline: "yum -y install mesos-#{mesos_version}"

      # Master
      if i == 1
        host.vm.provision :shell, inline: "yum -y install marathon-0.14.2 mesosphere-zookeeper etcd"
        
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

        # Mesos-dns
        host.vm.provision :shell, inline: $install_mesos_dns, args: "#{master_ip}"
      end

	  # Agents
      if i > 1
        # Provision with docker, and download the calico-node docker image
          host.vm.provision :docker, images: [
          "calico/node-libnetwork:#{calico_libnetwork_ver}",
          "calico/node:#{calico_node_ver}"
        ]

        # Configure docker to use etcd on master as its datastore
        host.vm.provision :shell, inline: $configure_docker, args: "#{master_ip}"

        # Install calicoctl
        host.vm.provision :shell, inline: "curl -o /usr/bin/calicoctl #{calicoctl_url}", :privileged => true
        host.vm.provision :shell, inline: "chmod +x /usr/bin/calicoctl"

        # Run calico components
        host.vm.provision :shell, inline: $start_calico, args: "#{master_ip}"

        # Configure slave to use mesos dns
        host.vm.provision :shell, inline: "sh -c 'echo DNS1=#{master_ip} >> /etc/sysconfig/network-scripts/ifcfg-eth1'"
        host.vm.provision :shell, inline: "sh -c 'echo PEERDNS=yes >> /etc/sysconfig/network-scripts/ifcfg-eth1'"
        host.vm.provision :shell, inline: "systemctl restart network"

        # Configure and start mesos-slave
        host.vm.provision :shell, inline: "sh -c 'echo #{ip} > /etc/mesos-slave/ip'"
        host.vm.provision :shell, inline: "sh -c 'echo #{ip} > /etc/mesos-slave/hostname'"
        host.vm.provision :shell, inline: "sh -c 'echo mesos,docker > /etc/mesos-slave/containerizers'"
        host.vm.provision :shell, inline: "systemctl start mesos-slave.service"
      end
    end
  end
end

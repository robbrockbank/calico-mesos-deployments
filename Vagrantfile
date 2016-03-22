# -*- mode: ruby -*-
# vi: set ft=ruby :

# Size of the cluster created by Vagrant
num_instances = 3

# VM Basename
instance_name_prefix="calico-mesos"

# Version of mesos to install from official mesos repo
mesos_version = "0.27.0"

# Calico version (for calicoctl and calico-node)
calico_node_ver = "v0.17.0"
calicoctl_url = "https://github.com/projectcalico/calico-containers/releases/download/#{calico_node_ver}/calicoctl"

mesos_netmodules_rpm_url = "https://github.com/projectcalico/calico-mesos-deployments/releases/download/0.27.0%2B2/mesos-netmodules-rpms.tar"
calico_mesos_rpm_url = "https://github.com/projectcalico/calico-mesos-deployments/releases/download/0.27.0%2B2/calico-mesos.rpm"

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
$start_calico_libnetwork=<<SCRIPT
cat <<EOF > /usr/lib/systemd/system/calico-libnetwork.service
[Unit]
Description=calico-libnetwork
After=docker.service
Requires=docker.service

[Service]
ExecStartPre=-/usr/bin/docker rm -f calico-libnetwork
ExecStart=/usr/bin/docker run --privileged --net=host \\
 -v /run/docker/plugins:/run/docker/plugins \\
 --name=calico-libnetwork \\
 -e ETCD_AUTHORITY=${1}:2379 \\
 -e ETCD_SCHEME=http \\
 calico/node-libnetwork:latest
ExecStop=-/usr/bin/docker stop calico-libnetwork

[Install]
WantedBy=multi-user.target
EOF

systemctl start calico-libnetwork.service
SCRIPT

$install_mesos_dns=<<SCRIPT
curl -LO https://github.com/mesosphere/mesos-dns/releases/download/v0.5.0/mesos-dns-v0.5.0-linux-amd64
mv mesos-dns-v0.5.0-linux-amd64 /usr/bin/mesos-dns
chmod +x /usr/bin/mesos-dns
mkdir /etc/mesos-dns
cat <<EOF > /etc/mesos-dns/mesos-dns.json
{
  "zk": "",
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

        # Mesos-dns
        host.vm.provision :shell, inline: $install_mesos_dns, args: "#{master_ip}"
      end

	  # Agents
      if i > 1
        # Provision with docker, and download the calico-node docker image
        host.vm.provision :docker, images: ["calico/node:#{calico_node_ver}"]
      
        # Configure slave to use mesos dns
        host.vm.provision :shell, inline: "sh -c 'echo DNS1=#{master_ip} >> /etc/sysconfig/network-scripts/ifcfg-eth1'"
        host.vm.provision :shell, inline: "sh -c 'echo PEERDNS=yes >> /etc/sysconfig/network-scripts/ifcfg-eth1'"
        host.vm.provision :shell, inline: "systemctl restart network"

        # Install epel packages
        host.vm.provision :shell, inline: "yum install -y epel-release"

        # Configure docker to use etcd on master as its datastore
        host.vm.provision :shell, inline: $configure_docker, args: "#{master_ip}"
        
        # Calico-Mesos RPM
        # Check if user has set CALICO_MESOS_RPM_PATH environment variable 
        if ENV.key?("CALICO_MESOS_RPM_PATH")
          # If so, then copy the file from that location onto the agent.
          # The specified file should be the RPM produced by running `make rpm` 
          # in this repo (calico-mesos-deployments). 
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

        # Run calico libnetwork
        host.vm.provision :shell, inline: $start_calico_libnetwork, args: "#{master_ip}"

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
        # Untar mesos-netmodules-rpms.tar and install its containing RPMs
        host.vm.provision :shell, inline: "tar -xvf mesos-netmodules-rpms.tar"
        host.vm.provision :shell, inline: "yum install -y mesos-netmodules-rpms/*.rpm"

        # Configure and start mesos-slave
        host.vm.provision :shell, inline: "sh -c 'echo #{ip} > /etc/mesos-slave/ip'"
        host.vm.provision :shell, inline: "sh -c 'echo #{ip} > /etc/mesos-slave/hostname'"
        host.vm.provision :shell, inline: "sh -c 'echo mesos,docker > /etc/mesos-slave/containerizers'"
        host.vm.provision :shell, inline: "systemctl start mesos-slave.service"
      end
    end
  end
end

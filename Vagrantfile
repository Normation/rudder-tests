# -*- mode: ruby -*-
# vi: set ft=ruby :

#####################################################################################
# Copyright 2012 Normation SAS
#####################################################################################
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, Version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#####################################################################################


Vagrant.configure("2") do |config|

  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Boot with a GUI so you can see the screen. (Default is headless)
  # config.vm.boot_mode = :gui

  # Share an additional folder to the guest VM. The first argument is
  # an identifier, the second is the path on the guest to mount the
  # folder, and the third is the path on the host to the actual folder.
  # config.vm.share_folder "v-data", "/vagrant_data", "../data"


  # VM declaration
  # name   : VM os name in vagrant
  # box    : Box name
  # url    : URL where to fetch the box
  # server : File to use as server provisionning script (they are in provision folder)
  # node   : File to use as node provisionning script (they are in provision folder)

  #################### SERVER BOXES ###########################

  oracle6 = {
    :name   => "oracle6",
    :url    => "https://storage.us2.oraclecloud.com/v1/istoilis-istoilis/vagrant/oel65-32.box",
    :server => "server_centos6.sh",
  }


  debian6 = {
    :name   => "debian6",
    :url    => "http://dl.dropbox.com/u/937870/VMs/squeeze64.box",
    :server => "server.sh",
  }

  debian7 = {
    :name   => "debian7",
    :url    => "https://dl.dropboxusercontent.com/u/197673519/debian-7.2.0.box",
    :server => "server.sh",
  }

  sles11 = {
    :name   => "sles11",
    :url    => "http://puppetlabs.s3.amazonaws.com/pub/sles11sp1_64.box",
    :server => "server_sles11.sh",
  }

  ubuntu12_10 = {
    :name   => "ubuntu12",
    :url    => "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-12.10_chef-provisionerless.box",
    :server => "server_ubuntu.sh",
  }

  centos6 = {
    :name   => "centos6",
    :url    => "http://developer.nrel.gov/downloads/vagrant-boxes/CentOS-6.3-x86_64-v20130101.box",
    :server => "server_centos6.sh",
  }


  #################### NODE BOXES ###########################

  centos5 = {
    :name   => "centos5",
    :url    => "http://puppet-vagrant-boxes.puppetlabs.com/centos-59-x64-vbox4210-nocm.box",
  }

  ubuntu14_04  = {
    :name   => "ubuntu14",
    :url    => "https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box",
  }
  
  solaris11 = {
    :name   => "solaris11",
    :url    => "http://www.benden.us/vagrant/solaris-11.1.box"
  }

  os = [ oracle6, debian6, debian7, sles11, ubuntu12_10, centos5, centos6, ubuntu14_04, solaris11 ]
  server = { :ip       => "192.168.42.10",
             :hostname => "server"
           }


  os.each { |os|
    # Declare server boxes if server provisionning script is declared
    if os[:server] 
      config.vm.define ("server_"+os[:name]).to_sym do |server_config|
        server_config.vm.box =  os[:name]
        server_config.vm.box_url = os[:url]
        server_config.vm.provider :virtualbox do |vb|
          vb.customize ["modifyvm", :id, "--memory", "1536"]
        end
        server_config.vm.network :forwarded_port, guest: 80, host: 8080
        server_config.vm.network :forwarded_port, guest: 443, host: 8081
        server_config.vm.network :private_network, ip: server[:ip]
        server_config.vm.hostname = server[:hostname]
        server_config.vm.provision :shell, :inline => "/vagrant/scripts/cleanbox; /vagrant/scripts/rudder-setup setup_server 2.11\n"
      end
    end

    (1..10).each { |i|
      n = i.to_s()
      config.vm.define ("node"+n+"_"+os[:name]).to_sym do |node_config|
        node_config.vm.provision :shell, :inline => "/vagrant/scripts/cleanbox; /vagrant/scripts/rudder-setup setup_agent 2.11\n"
        node_config.vm.network :private_network, ip: "192.168.42.1"+n
        node_config.vm.box =  os[:name]
        node_config.vm.box_url = os[:url]
        node_config.vm.provider :virtualbox
        node_config.vm.hostname = "node"+n
      end
    }
  }
end


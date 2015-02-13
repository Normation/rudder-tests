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

def configure(config, os, pf_name, pf_id,  host_id, version)
  # Parameters
  if host_id == 0 then
    host_name = "server"
    memory = "1536"
  else
    host_name = "agent" + host_id.to_s
    memory = "256"
  end
  name = pf_name + "_" + host_name
  net = "192.168." + (pf_id+40).to_s
  ip = net + "." + (host_id+2).to_s
  forward = 100*(80+pf_id)+80
  command  = "/vagrant/scripts/cleanbox " + net + "\n"
  if host_id == 0 then
    command += "export ALLOWEDNETWORK=" + net + ".0/24\n"
    command += "/vagrant/scripts/rudder-setup setup-server " + version + "\n"
    command += "/vagrant/scripts/create-token\n"
  else
    command += "/vagrant/scripts/rudder-setup setup-agent " + version + "\n"
  end

  # Configure
  config.vm.define (name).to_sym do |server_config|
    server_config.vm.box = os[:name]
    server_config.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", memory]
    end
    if host_id == 0 then
      server_config.vm.network :forwarded_port, guest: 80, host: forward
      server_config.vm.network :forwarded_port, guest: 443, host: forward+1
    end
    server_config.vm.network :private_network, ip: ip
    server_config.vm.hostname = host_name
    server_config.vm.provision :shell, :inline => command
  end
end


Vagrant.configure("2") do |config|

  centos7 = {
    :name   => "chef/centos-7.0",
  }

  centos6 = {
    :name   => "geerlingguy/centos6",
  }

  centos5 = {
    :name   => "hfm4/centos5",
  }

  oracle6 = {
    :name   => "kikitux/oracle6",
  }
 
  debian5 = {
    :name   => "pelavinz/debian-lenny" ,
  }
 
  debian6 = {
    :name   => "dene/debian-squeeze",
  }

  debian7 = {
    :name   => "cargomedia/debian-7-amd64-default",
  }

  debian8 = {
    :name   => " oar-team/debian8",
  }
    
  sles11 = {
    :name   => "idar/sles11sp3 ",
  }

  ubuntu12_04  = {
    :name   => "ubuntu/precise64",
  }
 
  ubuntu12_10 = {
    :name   => "chef/ubuntu-12.10",
  }

  ubuntu14_04  = {
    :name   => "ubuntu/trusty64",
  }
  
  solaris11 = {
    :name   => "ruby-concurrency/oracle-solaris-11",
  }



### AUTOGEN TAG

end



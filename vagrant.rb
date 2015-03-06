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

$centos5 = "hfm4/centos5"
$centos6 = "geerlingguy/centos6"
$centos7 = "chef/centos-7.0"

$oracle6 = "kikitux/oracle6"

$sles11 = "idar/sles11sp3"

$debian5 = "pelavinz/debian-lenny"
$debian6 = "dene/debian-squeeze"
$debian7 = "cargomedia/debian-7-amd64-default"
$debian8 = "oar-team/debian8"

$ubuntu12_04 = "ubuntu/precise64"
$ubuntu12_10 = "chef/ubuntu-12.10"
$ubuntu14_04 = "ubuntu/trusty64"

$solaris11 = "ruby-concurrency/oracle-solaris-11"


def configure(config, os, pf_name, pf_id, host_name, host_id, setup, version, server, host_list)
  # Parameters
  if setup == "server" then
    memory = "1536"
  else
    memory = "256"
  end
  name = pf_name + "_" + host_name
  net = "192.168." + (pf_id+40).to_s
  ip = net + "." + (host_id+2).to_s
  forward = 100*(80+pf_id)+80
  command  = '/vagrant/scripts/cleanbox ' + net + ' "' + host_list + '"\n'
  if setup == "server" then
    command += 'export ALLOWEDNETWORK=' + net + '.0/24\n'
    command += '/vagrant/scripts/rudder-setup setup-server "' + version + '"\n'
    command += '/vagrant/scripts/create-token\n'
  else
    command += '/vagrant/scripts/rudder-setup setup-' + setup + ' "' + version + '" "' + server + '"\n'
  end
  # onfigure
  config.vm.define (name).to_sym do |server_config|
    server_config.vm.box = os
    server_config.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", memory]
    end
    if setup == "server" then
      server_config.vm.network :forwarded_port, guest: 80, host: forward
      server_config.vm.network :forwarded_port, guest: 443, host: forward+1
    end
    server_config.vm.network :private_network, ip: ip
    server_config.vm.hostname = host_name
    server_config.vm.provision :shell, :inline => command
  end
end



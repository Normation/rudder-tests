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

$debian5 = "felipelavinz/debian-lenny"
$debian6 = "dene/debian-squeeze"
$debian7 = "cargomedia/debian-7-amd64-default"
$debian8 = "oar-team/debian8"

$ubuntu10_04 = "chef/ubuntu-10.04"
$ubuntu12_04 = "ubuntu/precise64"
$ubuntu12_10 = "chef/ubuntu-12.10"
$ubuntu14_04 = "ubuntu/trusty64"

$solaris10 = "uncompiled/solaris-10"
#$solaris10 = "tnarik/solaris10-minimal"
$solaris11 = "ruby-concurrency/oracle-solaris-11"

$windows7 = "designerror/windows-7"
#$windows2008 = "opentable/win-2008r2-standard-amd64-nocm"
#$windows2008 = "ferventcoder/win2008r2-x64-nocm"
$windows2008 = "opentable/win-2008-enterprise-amd64-nocm"

def configure(config, os, pf_name, pf_id, host_name, host_id, setup:'empty', version:nil, server:nil, host_list:'', windows_plugin:false, advanced_reporting:false)

  # Parameters
  if setup == "server" then
    memory = 1536
    if windows_plugin then
      memory += 512
    end
    if advanced_reporting then
      memory += 512
    end
  elsif os == $windows7 or os == $windows2008 then
    memory = 512
  elsif os == $solaris10 or os == $solaris11 then
    memory = 1024
  else
    memory = 256
  end
  memory = memory.to_s
  name = pf_name + "_" + host_name
  net = "192.168." + (pf_id+40).to_s
  ip = net + "." + (host_id+2).to_s
  forward = 100*(80+pf_id)+80

  # provisioning script
  if os == $windows7 or os == $windows2008 then
    command = "c:/vagrant/scripts/cleanbox.cmd #{net} #{host_list}\n"
    if setup != "empty" then
      command += "mkdir \"c:/Program Files/Cfengine\"\n"
      command += "echo #{server} > \"c:/Program Files/Cfengine/policy_server.dat\"\n"
      command += "c:/vagrant/rudder-plugins/Rudder-agent-x64.exe /S\n"
    end
  else
    command = "/vagrant/scripts/cleanbox #{net} \"#{host_list}\"\n"
    if setup != "empty" then
      command += "ALLOWEDNETWORK=#{net}.0/24 /vagrant/scripts/rudder-setup setup-#{setup} \"#{version}\" \"#{server}\"\n"
    end
    if setup == "server" then
      command += "/vagrant/scripts/create-token\n"
      if windows_plugin then
        command += "/vagrant/scripts/rudder-setup windows-plugin /vagrant/rudder-plugins/rudder-plugin-windows-server.zip\n"
      end
      if advanced_reporting then
        command += "/vagrant/scripts/rudder-setup reporting-plugin /vagrant/rudder-plugins/advanced-reporting.tgz\n"
      end
    end
  end

  # Configure
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



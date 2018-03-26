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

# find more : https://atlas.hashicorp.com/boxes/search
$centos5 = "normation/centos-5-64"
$centos6 = "geerlingguy/centos6"
$centos6x32 = "bento/centos-6.7-i386"
$centos7 = "geerlingguy/centos7"

$fedora18 = "boxcutter/fedora18"

$oracle6 = "kikitux/oracle6"

$sles11 = "idar/sles11sp3"
$sles12 = "alchemy-solutions/sles12sp1"

$debian5 = "normation/debian-5-64"
$debian6 = "normation/debian-6-64"
$debian7 = "normation/debian-7-64"
$debian8 = "normation/debian-8-64"
$debian9 = "normation/debian-9-64"

$ubuntu10_04 = "bento/ubuntu-10.04"
$ubuntu12_04 = "normation/ubuntu-12.04"
$ubuntu12_10 = "chef/ubuntu-12.10"
$ubuntu14_04 = "normation/ubuntu-14.04"
$ubuntu16_04 = "bento/ubuntu-16.04"

$slackware14 = "ratfactor/slackware"

$solaris10 = "uncompiled/solaris-10"
$solaris11 = "ruby-concurrency/oracle-solaris-11"

$windows7 = "designerror/windows-7"
$windows2008 = "normation/windows-2008r2-64"
$windows2012 = "opentable/win-2012r2-standard-amd64-nocm"
$windows2008r2 = "opentable/win-2008r2-standard-amd64-nocm"
$windows2012r2 = "opentable/win-2012r2-standard-amd64-nocm"

# Format pf_name => { 'pf_id' => 0, 'last_host_id' => 0, 'host_list' => [ 'host1', 'host2' ] }
$platforms = {
}
$last_pf_id = 0

require 'socket'
require "open-uri"

def configure_box(config, os, pf_name, host_name, 
                  setup:'empty', version:nil, server:'', host_list:'',
                  windows_plugin:false, advanced_reporting:false, dsc_plugin: false,
                  ncf_version:nil, cfengine_version:nil, ram:nil
                 )
  pf = $platforms.fetch(pf_name) { |key| 
                                   $last_pf_id = $last_pf_id+1
                                   { 'pf_id' => $last_pf_id-1, 'host_list' => [ ]}
                                 }
  # autodetect platform id and host id
  pf_id = pf['pf_id']
  host_id = pf['host_list'].length
  pf['host_list'].push(host_name)
  host_list = host_list + " "
  $platforms[pf_name] = pf
  configure(config, os, pf_name, pf_id, host_name, host_id, 
            setup:setup, version:version, server:server, host_list:host_list,
            windows_plugin:windows_plugin, advanced_reporting:advanced_reporting, dsc_plugin:dsc_plugin,
            ncf_version:ncf_version, cfengine_version:cfengine_version, ram:ram)
end

$proxy = nil
def get_proxy()
  unless $proxy.nil?
    return $proxy
  end
  begin
  	nrm_ip = Socket.getaddrinfo("republique-1.normation.com.", 'http')[0][2]
  	my_ip = URI.parse("http://ipinfo.io/ip").read().strip()
  	if nrm_ip == my_ip then
  	  nrm_proxy = "http://filer.interne.normation.com:3128"
  	  $proxy = "http_proxy="+nrm_proxy+" https_proxy="+nrm_proxy+" HTTP_PROXY="+nrm_proxy+" HTTPS_PROXY="+nrm_proxy
  	else
  	  $proxy = ""
    end
	rescue SocketError
		#When no internet is available
		$proxy = ""
	ensure
    return $proxy
  end
end

# keep this function separate for compatibility with older Vagrantfiles
def configure(config, os, pf_name, pf_id, host_name, host_id, 
              setup:'empty', version:nil, server:'', host_list:'', 
              windows_plugin:false, advanced_reporting:false, dsc_plugin: false,
              ncf_version:nil, cfengine_version:nil, ram:nil
             )
  # Parameters
  dev = false
  if setup == "dev-server"
    setup = "server"
    dev = true
  end
  if setup == "server" then
    memory = 1536 
    if windows_plugin then
      memory += 512
    end
    if advanced_reporting then
      memory += 512
    end
  elsif os =~ /win/ then
    memory = 512
  elsif os == $solaris10 or os == $solaris11 then
    memory = 1024
  else
    memory = 256
  end
  # override allocated ram
  unless ram.nil?
    memory = ram
  end
  memory = memory.to_s
  name = pf_name + "_" + host_name
  net = "192.168." + (pf_id+40).to_s
  ip = net + "." + (host_id+2).to_s
  forward = 100*(80+pf_id)+80

  # provisioning script
  if os =~ /win/ then
    command = "c:/vagrant/scripts/network.cmd #{net} @host_list@\n"
    if setup != "empty" and setup != "ncf" then
      if setup == "rudder-agent-cfengine" then
        command += "mkdir \"c:/Program Files/Cfengine\"\n"
        command += "echo #{server} > \"c:/Program Files/Cfengine/policy_server.dat\"\n"
        command += "c:/vagrant/rudder-plugins/Rudder-agent-x64.exe /S\n"
      else
        command += "mkdir \"c:/Program Files/Rudder\"\n"
        command += "echo #{server} > \"c:/Program Files/Rudder/policy_server.dat\"\n"
        command += "c:/vagrant/rudder-plugins/rudder-agent-dsc.exe /S\n"
      end
    end
  else
    proxy = get_proxy()
    command = "echo 'Starting VM setup'\n"
    command += "/vagrant/scripts/cleanbox.sh\n"
    command += "/vagrant/scripts/network.sh #{net} \"@host_list@\"\n"
    if setup != "empty" and setup != "ncf" then
      command += "#{proxy} ALLOWEDNETWORK=#{net}.0/24 /usr/local/bin/rudder-setup setup-#{setup} \"#{version}\" \"#{server}\"\n"
    end
    if setup == "ncf" then
      command += "#{proxy} /usr/local/bin/ncf-setup setup-local \"#{ncf_version}\" \"#{cfengine_version}\"\n"
    end
    if setup == "server" then
      command += "/vagrant/scripts/create-token\n"
      if dsc_plugin then
        command += "/opt/rudder/bin/rudder-pkg install-file /vagrant/rudder-plugins/rudder-plugin-dsc.rpkg\n"
      end
      if windows_plugin then
        command += "/usr/local/bin/rudder-setup windows-plugin /vagrant/rudder-plugins/rudder-plugin-windows-server.zip\n"
      end
      if advanced_reporting then
        command += "/usr/local/bin/rudder-setup reporting-plugin /vagrant/rudder-plugins/advanced-reporting.tgz\n"
      end
    end
    if dev then
      command += "/vagrant/scripts/dev.sh\n"
    end
    command += "/bin/true\n"
  end

  # Configure
  config.vm.define (name).to_sym do |server_config|
    server_config.vm.box = os
    server_config.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", memory]
    end
    server_config.vm.provider :libvirt do |vm|
      vm.memory = memory
      vm.nic_model_type = "e1000"
    end
    server_config.vm.provider :virtualbox do |vb|
      vb.customize ['modifyvm', :id, '--cableconnected1', 'on']
    end
    if setup == "server" then
      server_config.vm.network :forwarded_port, guest: 80, host: forward
      server_config.vm.network :forwarded_port, guest: 443, host: forward+1
    end
    if dev then
      server_config.vm.network :forwarded_port, guest: 389, host: 1389
      server_config.vm.network :forwarded_port, guest: 5432, host: 15432

      config.vm.synced_folder "/var/rudder/share", "/var/rudder/share", :create => true
      config.vm.synced_folder "/var/rudder/cfengine-community/inputs", "/var/rudder/cfengine-community/inputs", :create => true
    end
    server_config.vm.network :private_network, ip: ip
    server_config.vm.hostname = host_name
    # this is lazy evaluated and so will contain the last definition of host list
    pf_hostlist = $platforms.fetch(pf_name) { { 'host_list' => [] } }
    host_list = pf_hostlist['host_list'].join(" ") + " " + host_list
    server_config.vm.provision :shell, :inline => command.sub("@host_list@", host_list)
  end
end


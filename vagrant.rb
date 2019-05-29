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
#
# find more : https://atlas.hashicorp.com/boxes/search
$centos5 = "normation/centos-5-64"
$centos6 = "geerlingguy/centos6"
$centos6x32 = "bento/centos-6.7-i386"
$centos7 = "geerlingguy/centos7"

$rhel5 = $centos5
$rhel6 = $centos6
$rhel6x32 = $centos6x32
$rhel7 = $centos7

$fedora18 = "boxcutter/fedora18"

$oracle6 = "kikitux/oracle6"

$sles11 = "normation/sles-11-03-64"
$sles12 = "normation/sles-12-03-64"
$sles15 = "normation/sles-15-64"

$debian5 = "normation/debian-5-64"
$debian6 = "normation/debian-6-64"
$debian7 = "normation/debian-7-64"
$debian8 = "normation/debian-8-64"
$debian9 = "normation/debian-9-64"

$ubuntu10_04 = "bento/ubuntu-10.04"
$ubuntu12_04 = "normation/ubuntu-12.04"
$ubuntu12_10 = "chef/ubuntu-12.10"
$ubuntu13_04 = "rafaelrosafu/raring64-vanilla"
$ubuntu14_04 = "normation/ubuntu-14.04"
$ubuntu15_10 = "wzurowski/wily64"
$ubuntu16_04 = "normation/ubuntu-16-04-64"
$ubuntu18_04 = "bento/ubuntu-18.04"

$ubuntu10 = $ubuntu10_04
$ubuntu12 = $ubuntu12_04
$ubuntu14 = $ubuntu14_04
$ubuntu16 = $ubuntu16_04
$ubuntu18 = $ubuntu18_04

$slackware14 = "ratfactor/slackware"

$solaris10 = "uncompiled/solaris-10"
$solaris11 = "ruby-concurrency/oracle-solaris-11"

$windows7 = "designerror/windows-7"
$windows2008 = "normation/windows-2008r2-64"
$windows2012 = "opentable/win-2012r2-standard-amd64-nocm"
$windows2008r2 = "opentable/win-2008r2-standard-amd64-nocm"
$windows2012r2 = "opentable/win-2012r2-standard-amd64-nocm"

#AWS ami
$aws_sles11 = "ami-2e1aad53"
$aws_sles12 = "ami-d29b2daf"

$aws_ubuntu14_04 = "ami-933482ee"
$aws_ubuntu16_04 = "ami-0e55e373"

$aws_windows2012 = "ami-802492fd"

$aws_os = {
    "ami-2e1aad53" => "sles",
    "ami-d29b2daf" => "sles",
    "ami-933482ee" => "ubuntu",
    "ami-0e55e373" => "ubuntu",
    "ami-802492fd" => "windows"
  }


# Format pf_name => { 'pf_id' => 0, 'last_host_id' => 0, 'host_list' => [ 'host1', 'host2' ] }
$platforms = {
}
$last_pf_id = 0

require 'socket'
require "open-uri"

def configure_box(config, os, pf_name, host_name, 
                  setup:'empty', version:nil, server:'', host_list:'',
                  windows_plugin:false, advanced_reporting:false, dsc_plugin: false,
                  ncf_version:nil, cfengine_version:nil, ram:nil, cpus:nil, disk_size:nil
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
            ncf_version:ncf_version, cfengine_version:cfengine_version, ram:ram, cpus:cpus, disk_size:disk_size
)
end

$proxy = nil
def get_proxy()
  unless $proxy.nil?
    return $proxy
  end
  def local_ip
    orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true  # turn off reverse DNS resolution temporarily

    UDPSocket.open do |s|
      s.connect '8.8.8.8', 1
      s.addr.last
    end
  ensure
    Socket.do_not_reverse_lookup = orig
  end
  if local_ip().start_with?('192.168.90.') then
    nrm_ip = Socket.getaddrinfo("republique-1.normation.com.", 'http')[0][2]
    public_ip = URI.parse("http://ipinfo.io/ip").read().strip()
    if nrm_ip == public_ip then
      nrm_proxy = "http://filer.interne.normation.com:3128"
      $proxy = "http_proxy="+nrm_proxy+" https_proxy="+nrm_proxy+" HTTP_PROXY="+nrm_proxy+" HTTPS_PROXY="+nrm_proxy
    else
      $proxy = ""
    end
  else
    $proxy = ""
  end
  return $proxy
end

$command = nil
def provisioning_script(os, host_name, net, first_ip, 
              setup:'empty', version:nil, server:'', host_list:'', 
              windows_plugin:false, advanced_reporting:false, dsc_plugin: false,
              aws: false, ncf_version:nil, cfengine_version:nil, ram:nil, provision:true,
              sync_file:nil, cpus:nil, disk_size:nil

             )

  dev = false
  demo = false
  if setup =="demo-server"
    setup = "server"
    demo = true
  end
  if setup == "dev-server"
    setup = "server"
    dev = true
  end

  sync_file_prefix = "/vagrant"
  unless sync_file.nil?
    sync_file_prefix = sync_file
  end

  # provisioning script
  if os =~ /win/ then
    command = "c:/vagrant/scripts/network.cmd #{net} #{first_ip} @host_list@\n"
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
    command = "echo 'Starting VM setup'\n"
    command += sync_file_prefix + "/scripts/cleanbox.sh #{sync_file_prefix}\n"
    command += sync_file_prefix + "/scripts/network.sh #{net} #{first_ip} \"@host_list@\"\n"
    command += "export DOWNLOAD_USER=#{ENV['DOWNLOAD_USER']} DOWNLOAD_PASSWORD=#{ENV['DOWNLOAD_PASSWORD']}\n"
    if aws then
      command += "echo 'Setting up hostname'\n"
      command += "echo '#{host_name}' > /etc/hostname && hostname $(cat /etc/hostname)\n"
      proxy = ""
    else
      proxy = get_proxy()
    end
    if provision == true then
      if setup != "empty" and setup != "ncf" then
        command += "#{proxy} ALLOWEDNETWORK=#{net}.0/24 UNSUPPORTED=#{ENV['UNSUPPORTED']} REPO_PREFIX=rtf/ /usr/local/bin/rudder-setup setup-#{setup} \"#{version}\" \"#{server}\"\n"
      end
      if setup == "ncf" then
        command += "#{proxy} /usr/local/bin/ncf-setup setup-local \"#{ncf_version}\" \"#{cfengine_version}\"\n"
      end
      if setup == "server" then
        command += sync_file_prefix + "/scripts/create-token\n"
      end
      if dev then
        command += sync_file_prefix + "/scripts/dev.sh\n"
      end
      if demo then
        command += sync_file_prefix + "/scripts/demo-server-setup.sh\n"
      end
    end
  end
  return command
end

def ssh_user(ami)
  aws_users = {
    "ubuntu" => "ubuntu",
    "sles" => "ec2-user",
    "debian" => "admin",
    "centos" => "centos",
    "fedora" => "ec2-user",
    "windows" => "Administrator"
  }
  begin
    os_name = $aws_os[ami]
    return aws_users[os_name]
  rescue
    puts "No suitable user found to ssh on the remote system"
    return "ec2-user"
  end
end

# keep this function separate for compatibility with older Vagrantfiles
def configure_aws(config, os, pf_name, pf_id, host_name, host_id,
              setup:'empty', version:nil, server:'', host_list:'',
              windows_plugin:false, advanced_reporting:false, dsc_plugin: false,
              ncf_version:nil, cfengine_version:nil, ram:nil, provision:true,
              sync_file:nil, cpus:nil, disk_size:nil
             )

  if setup == 'server' then
    instance_type = "t2.medium"
    security_groups = $AWS_SERVER_GROUP
  elsif setup == 'relay' then
    instance_type = "t2.medium"
    security_groups = $AWS_RELAY_GROUP
  else
    instance_type = "t2.micro"
    security_groups = $AWS_AGENT_GROUP
  end

  user = ssh_user(os)
  name = pf_name + "_" + host_name
  # Because AWS keep the 4 first @ips of each subnet
  first_ip = 5
  net = "10.0.0"
  ip = net + "." + (first_ip + host_id).to_s

  command = provisioning_script(os, host_name, net, first_ip,
              setup:"#{setup}", version:"#{version}", server:"#{server}", host_list:"#{host_list}", windows_plugin:windows_plugin,
              advanced_reporting:advanced_reporting, dsc_plugin:dsc_plugin, aws:true, ncf_version:"#{ncf_version}",
              cfengine_version:"#{cfengine_version}", provision:provision)

  # Configure
  config.vm.define (name).to_sym do |instance|
    instance.vm.provider 'aws' do |aws, override|
      # Use dummy AWS box
      config.vm.box = 'dummy'
  
      # Read AWS authentication information from environment variables
      aws.aws_dir = ENV['HOME'] + "/.aws/"
      aws.access_key_id = $AWS_KEY
      aws.secret_access_key = $AWS_SECRET
      aws.keypair_name = $AWS_KEYNAME
  
      # Specify SSH keypair to use
      aws.region = 'eu-west-3'
      aws.ami = os
      aws.instance_type = instance_type
      # Specify region, AMI ID, and security group(s)
      aws.security_groups = security_groups
      # Private network
      aws.subnet_id = $AWS_VPC
      aws.associate_public_ip = true
      aws.private_ip_address = ip
      aws.tags = {
        'Name': "#{name}"
      }
  
      # Specify username and private key path
      override.ssh.username = user
      override.ssh.private_key_path = ENV['HOME'] + "/.aws/" + $AWS_KEYNAME + ".pem"

      #override.vm.communicator = "winrm"
      #override.winrm.username = "Administrator"
      #override.winrm.password = "VagrantRocks"

      # Provisionning
      pf_hostlist = $platforms.fetch(pf_name) { { 'host_list' => [] } }
      host_list = pf_hostlist['host_list'].join(" ") + " " + host_list
    end
    instance.vm.provision :shell, :inline => command.sub("@host_list@", host_list)
  end
end

    


# keep this function separate for compatibility with older Vagrantfiles
# NET_PREFIX must be a an int between 40 and 150.
def configure(config, os, pf_name, pf_id, host_name, host_id,
              setup:'empty', version:nil, server:'', host_list:'', 
              windows_plugin:false, advanced_reporting:false, dsc_plugin: false,
              ncf_version:nil, cfengine_version:nil, ram:nil, provision:true,
              sync_file:nil, cpus:nil, disk_size:nil
             )
  # Parameters
  dev =  setup == "dev-server" 

  if setup =~ /server/ then
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

  allocated_cpus = 1
  unless cpus.nil?
    allocated_cpus = cpus
  end

  sync_file_prefix = "/vagrant"
  unless sync_file.nil?
    sync_file_prefix = sync_file
  end

  name = pf_name + "_" + host_name
  first_ip = 2
  $NET_PREFIX ||= 40
  net = "192.168." + (pf_id+$NET_PREFIX).to_s
  ip = net + "." + (first_ip + host_id).to_s
  forward = 100*(2*$NET_PREFIX+pf_id)+80

  command = provisioning_script(os, host_name, net, first_ip,
              setup:"#{setup}", version:"#{version}", server:"#{server}", host_list:"#{host_list}", windows_plugin:windows_plugin,
              advanced_reporting:advanced_reporting, dsc_plugin:dsc_plugin, ncf_version:"#{ncf_version}", cfengine_version:"#{cfengine_version}", provision:provision,
              sync_file:sync_file)

  # Configure
  config.vm.define (name).to_sym do |server_config|
    server_config.vm.box = os
    server_config.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", memory]
      vb.customize ['modifyvm', :id, '--cableconnected1', 'on']
      vb.cpus = allocated_cpus
    end
    server_config.vm.provider :libvirt do |vm|
      vm.memory = memory
      vm.nic_model_type = "e1000"
    end
    if setup =~ /server/ then
      server_config.vm.network :forwarded_port, guest: 80, host: forward
      server_config.vm.network :forwarded_port, guest: 443, host: forward+1
    end
    if dev then
      server_config.vm.network :forwarded_port, guest: 389, host: 1389
      server_config.vm.network :forwarded_port, guest: 5432, host: 15432

      config.vm.synced_folder "/var/rudder/share", "/var/rudder/share", :create => true
      config.vm.synced_folder "/var/rudder/cfengine-community/inputs", "/var/rudder/cfengine-community/inputs", :create => true, :owner => "root", :group => "root"
    end
    server_config.vm.network :private_network, ip: ip
    server_config.vm.hostname = host_name
    # this is lazy evaluated and so will contain the last definition of host list
    pf_hostlist = $platforms.fetch(pf_name) { { 'host_list' => [] } }
    host_list = pf_hostlist['host_list'].join(" ") + " " + host_list
    unless sync_file.nil?
      config.vm.synced_folder ".", "/vagrant", disabled: true
      config.vm.provision "file", source: "./scripts/", destination: sync_file_prefix + "/scripts"
    end
    #server_config.vm.provision :shell, :inline => command.sub("@host_list@", host_list)
    # Add new disk if specified
    config.trigger.after :up do |trigger|
      trigger.ruby do |env, machine|
        unless disk_size.nil?
          puts "Virtualbox UUID is #{machine.id}"
          disk_path=File.dirname(__FILE__) + "/.vagrant/rtf_disks/#{machine.id}"
          puts "RTF disk defined in #{disk_path}"
          puts "Executing add_disk.sh on Host"
          system("./scripts/add_disk.sh #{machine.id} #{disk_path} #{disk_size} #{name}")
        end
      end
    end
  end
end

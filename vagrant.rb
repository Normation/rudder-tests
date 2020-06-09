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

# TOO deprecated
$centos5 = "normation/centos-5-64"
$centos6 = "geerlingguy/centos6"
$centos6x32 = "bento/centos-6.7-i386"
$centos7 = "geerlingguy/centos7"
$centos8 = "geerlingguy/centos8"

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
$debian10 = "normation/debian-10-64"

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

# end of deprecated

$vagrant_systems = {
  "centos5" => "normation/centos-5-64",
  "centos6" => "geerlingguy/centos6",
  "centos6x32" => "bento/centos-6.7-i386",
  "centos7" => "geerlingguy/centos7",
  "centos8" => "geerlingguy/centos8",

  "rhel5" => "normation/centos-5-64",
  "rhel6" => "geerlingguy/centos6",
  "rhel6x32" => "bento/centos-6.7-i386",
  "rhel7" => "geerlingguy/centos7",
  "rhel8" => "geerlingguy/centos8",

  "fedora18" => "boxcutter/fedora18",

  "oracle6" => "kikitux/oracle6",

  "sles11" => "normation/sles-11-03-64",
  "sles12" => "normation/sles-12-03-64",
  "sles15" => "normation/sles-15-64",

  "debian5" => "normation/debian-5-64",
  "debian6" => "normation/debian-6-64",
  "debian7" => "normation/debian-7-64",
  "debian8" => "normation/debian-8-64",
  "debian9" => "normation/debian-9-64",
  "debian10" => "normation/debian-10-64",

  "ubuntu10_04" => "bento/ubuntu-10.04",
  "ubuntu12_04" => "normation/ubuntu-12.04",
  "ubuntu12_10" => "chef/ubuntu-12.10",
  "ubuntu13_04" => "rafaelrosafu/raring64-vanilla",
  "ubuntu14_04" => "normation/ubuntu-14.04",
  "ubuntu15_10" => "wzurowski/wily64",
  "ubuntu16_04" => "normation/ubuntu-16-04-64",
  "ubuntu18_04" => "bento/ubuntu-18.04",
  "ubuntu20_04" => "ubuntu/focal64",

  "ubuntu10" => "bento/ubuntu-10.04",
  "ubuntu12" => "normation/ubuntu-12.04",
  "ubuntu14" => "normation/ubuntu-14.04",
  "ubuntu16" => "normation/ubuntu-16-04-64",
  "ubuntu18" => "bento/ubuntu-18.04",
  "ubuntu20" => "ubuntu/focal64",

  "slackware14" => "ratfactor/slackware",

  "solaris10" => "uncompiled/solaris-10",
  "solaris11" => "ruby-concurrency/oracle-solaris-11",

  "windows7" => "designerror/windows-7",
  "windows2008" => "normation/windows-2008r2-64",
  "windows2012" => "opentable/win-2012r2-standard-amd64-nocm",
  "windows2008r2" => "opentable/win-2008r2-standard-amd64-nocm",
  "windows2012r2" => "opentable/win-2012r2-standard-amd64-nocm",
}

# list of boxes that don't have vboxsf enabled
$vboxsfbug = [ 
  "geerlingguy/centos6",
  "bento/centos-6.7-i386",

  "normation/debian-7-64",
  "normation/debian-6-64",

  "bento/ubuntu-10.04",
  "chef/ubuntu-12.10",
  "ubuntu/focal64",
]

$aws = {
  # please use community AMI
  "centos8" => [ "ami-078905c4b06b2108a", "ec2-user" ],

  "sles11" => [ "ami-2e1aad53", "ec2-user" ],
  "sles12" => [ "ami-d29b2daf", "ec2-user" ],

  "ubuntu14_04" => [ "ami-933482ee", "ubuntu" ],
  "ubuntu16_04" => [ "ami-0e55e373", "ubuntu" ],
  "ubuntu18_04" => [ "ami-0701e7be9b2a77600", "ubuntu" ],

  "ubuntu14" => [ "ami-933482ee", "ubuntu" ],
  "ubuntu16" => [ "ami-0e55e373", "ubuntu" ],
  "ubuntu18" => [ "ami-0701e7be9b2a77600", "ubuntu" ],

  "windows2012" => [ "ami-802492fd", "ec2-user" ],
}

require 'socket'
require 'open-uri'
require 'json'
require 'ipaddr'

$SKIP_IP ||= 1

# Configure a complete platform by just providing an id and a json file
def platform(config, pf_id, pf_name, override={})
  conffile = "platforms/"+pf_name+".json"
  unless File.file?(conffile)
    puts "File " + conffile + " doesn't exist"
  end
  file = open(conffile)
  json = file.read
  data = JSON.parse(json)

  default = data['default']
  prio = { 'server' => '0', 'relay' => '1', 'agent' => '2' }
  machines = data.keys
  machines.delete('default')
  machines = machines.sort_by { |k| # sort by type then by name
    if prio.include?(data[k]['rudder-setup']) then
      prio[data[k]['rudder-setup']] + k
    else
      '9' +k
    end
  }
  machines.each do |machine|
    if data[machine].include? "rudder-setup" and data[machine]["rudder-setup"] =~ /server/ then
      default['server'] = machine
    end
  end
  hosts = {}
  host_id=0
  override = override.map { |k,v| [k.to_s, v] }.to_h
  machines.each do |host_name|
    machine = default.merge(data[host_name]).merge(override)

    # Machine name
    name = pf_name + "_" + host_name

    # Network information
    network, ip, port = network_info(machine, pf_id, host_id)
  
    # Configure
    config.vm.define name do |cfg|
      unless $vagrant_systems.include? machine['system'] then
        puts "Unknown system #{machine['system']}"
      end
      # Synchronize at least scripts
      if $vboxsfbug.include?($vagrant_systems[machine['system']]) or machine['provider'] == "aws" then
        cfg.vm.synced_folder ".", "/vagrant", disabled: true
        cfg.vm.synced_folder "scripts", "/vagrant/scripts", type: "rsync"
      end
      # the provisioning script is generated
      cfg.vm.provision :shell, :inline => provisioning_command(machine, host_name, network, machines)

      # provider specific code
      if machine['provider'] == "aws" then
        aws_machine(cfg, machines, host_name, machine, name, ip)
      else
        vagrant_machine(cfg, machines, host_name, machine, name, ip, port)
      end
    end

    host_id += 1
  end
end


# Configure a single machine
def vagrant_machine(cfg, machines, host_name, machine, name, ip, port)
  # RAM allocation
  if machine['rudder-setup'] =~ /server/ then
    memory = 2048
  elsif machine['system'] =~ /win/ then
    memory = 512
  elsif machine['system'] =~ /solaris/ then
    memory = 1024
  else
    memory = 256
  end
  # override allocated ram
  memory = machine['ram'] if machine.key?('ram')
  memory = memory.to_s

  cfg.vm.box = $vagrant_systems[machine['system']]
  cfg.vm.provider :virtualbox do |vm|
    vm.customize ['modifyvm', :id, '--cableconnected1', 'on']
    vm.name = name
    vm.memory = memory
    vm.cpus = machine.key?('cpus') ? machine['cpus'] : 1
  end
  cfg.vm.provider :libvirt do |vm|
    vm.memory = memory
    vm.cpus = machine.key?('cpus') ? machine['cpus'] : 1
    vm.nic_model_type = "e1000"
  end
  if machine['rudder-setup'] =~ /server/ then
    cfg.vm.network :forwarded_port, guest: 80, host: port
    cfg.vm.network :forwarded_port, guest: 443, host: port+1
  end
  if machine['rudder-setup'] == "dev-server" then
    cfg.vm.network :forwarded_port, guest: 389, host: 1389
    cfg.vm.network :forwarded_port, guest: 5432, host: 15432

    cfg.vm.synced_folder "/var/rudder/share", "/var/rudder/share", :create => true
    cfg.vm.synced_folder "/var/rudder/inventories", "/var/rudder/inventories", :create => true, :owner => "root", :group => "root"
    cfg.vm.synced_folder "/var/rudder/cfengine-community/inputs", "/var/rudder/cfengine-community/inputs", :create => true, :owner => "root", :group => "root"
  end
  cfg.vm.box_version = machine['box_version'] if machine.key?('box_version')

  # common conf
  cfg.vm.network :private_network, ip: ip.to_s()
  cfg.vm.hostname = host_name

  # Add new disk if specified
  cfg.trigger.after :up do |trigger|
    trigger.ruby do |env, m|
      if machine.key?('disk_size')
        puts "Virtualbox UUID is #{m.id}"
        disk_path=File.dirname(__FILE__) + "/.vagrant/rtf_disks/#{m.id}"
        puts "RTF disk defined in #{disk_path}"
        puts "Executing add_disk.sh on Host"
        system("./scripts/add_disk.sh #{m.id} #{disk_path} #{machine['disk_size']} #{name}")
      end
    end
  end
end

# Configure a single machine for AWS
def aws_machine(cfg, machines, host_name, machine, name, ip)
  # Machine allocation
  if machine['rudder-setup'] == 'server' or machine['rudder-setup'] == 'relay' or machine['system'] =~ /win/ then
    instance_type = "t2.medium"
  else
    instance_type = "t2.micro"
  end

  # Configure
  cfg.vm.provider 'aws' do |aws|
    # Instance
    aws.ami = $aws[machine['system']][0]
    aws.instance_type = instance_type
    # Security
    aws.security_groups = $AWS_SECURITY_GROUP
    aws.keypair_name = $AWS_KEYNAME
    # Network
    aws.subnet_id = $AWS_SUBNET
    aws.private_ip_address = ip
    aws.associate_public_ip = true
    # Tags
    aws.tags = {
      'Name': "#{name}"
    }
  end

  cfg.vm.box = 'dummy' # aws plugin does not use regular boxes
  
  # Specify username and private key path
  cfg.ssh.username = $aws[machine['system']][1]
  cfg.ssh.private_key_path = $AWS_KEYPATH

  # TODO handle windows
  #cfg.vm.communicator = "winrm"
  #cfg.winrm.username = "Administrator"
  #cfg.winrm.password = "VagrantRocks"
end

# Returns a proxy configuration if we are in Normation office
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

# compute network information
def network_info(machine, pf_id, host_id)
  # Network configuration
  # TODO deprecated
  first_ip = 2
  $NET_PREFIX ||= 40
  net = "192.168." + (pf_id+$NET_PREFIX).to_s
  ip = net + "." + (first_ip + host_id).to_s
  net = IPAddr.new ip + "/24"
  forward = 100*(2*$NET_PREFIX+pf_id)+80
  # end of deprecated

  unless $NETWORK.nil? then
    net = IPAddr.new $NETWORK
    # calculate base network (can do better ?)
    pf_id.times { net = net.to_range.last.succ }
    # calculate new ip
    ip = net
    (host_id+$SKIP_IP+1).times { ip = ip.succ() }
    # Check the ip is still valid
    unless net.include?(ip) then
      puts "Ip address for #{name} out of range"
      exit(1)
    end
    forward = (80+pf_id)*100 + 80 # start at 8080
  end

  return net, ip, forward
end

# Create the command used to provision the machine
def provisioning_command(machine, host_name, net, machines)
  dev = false
  demo = false
  setup = machine['rudder-setup']
  if setup =="demo-server"
    setup = "server"
    demo = true
  end
  if setup == "dev-server"
    setup = "server"
    dev = true
    dev_var="DEV_MODE=true"
  end

  host_list = machines.join(" ")

  # This works because even with cidr we will never cross the digit boundary
  # This is because ce don't use cidr wider than 24 with more than 255 hosts
  net_prefix = net.to_s.split('.')[0..2].join('.')
  first_ip = $SKIP_IP+1

  # provisioning script
  command = ""
  if machine['system'] =~ /win/ then
    command += "c:/vagrant/scripts/network.cmd #{net_prefix} #{first_ip} #{host_list} \n"
    if setup != "empty" and setup != "ncf" then
      command += "mkdir \"c:/Program Files/Rudder\"\n"
      command += "echo #{machine['server']} > \"c:/Program Files/Rudder/policy_server.dat\"\n"
      command += "c:/vagrant/rudder-plugins/rudder-agent-dsc.exe /S\n"
    end
  else
    command = "set -x\n"
    unless machine['extra_line'].nil?
      command += machine['extra_line'] + "\n"
    end
    command += "echo 'Starting VM setup'\n"
    if machine['provider'] == "aws" then
      command += "echo '#{host_name}' > /etc/hostname && hostname $(cat /etc/hostname)\n"
      proxy = ""
    else
      proxy = get_proxy()
    end
    command += "/vagrant/scripts/cleanbox.sh /vagrant\n"
    command += "/vagrant/scripts/network.sh #{net_prefix} #{first_ip} \"#{host_list}\"\n"
    unless machine.key?('provision') then
      # hide passwords from set -x
      command += "set +x\nexport DOWNLOAD_USER=\"#{$DOWNLOAD_USER}\"\nexport DOWNLOAD_PASSWORD=\"#{$DOWNLOAD_PASSWORD}\"\nset -x\n"

      network = net.to_s + "/" + net.prefix.to_s
      environment = "#{proxy} #{dev_var}"
      environment += " PLUGINS_VERSION=#{machine['plugins_version']} FORGET_CREDENTIALS=#{machine['forget_credentials']}"
      environment += " DISABLE_AUTODETECT_NETWORKS=yes ALLOWEDNETWORK=#{network} UNSUPPORTED=#{ENV['UNSUPPORTED']} ADMIN_PASSWORD=admin REPO_PREFIX=rtf/"

      if setup == "ncf" then
        command += "#{environment} /usr/local/bin/ncf-setup setup-local \"#{machine['ncf_version']}\" \"#{machine['cfengine_version']}\"\n"
      elsif setup != "empty" then
        arg3 = ""
        if setup == "server" then
          arg3 = "\"#{machine['plugins']}\""
        else
          arg3 = "\"#{machine['server']}\""
        end

        if machine['live'] == "true" then
          # no wait between char display, but newlines may be inserted
          filter = ""
        else
          # this forces vagrant to wait for the end of the line before displaying it
          # this avoid progress bars messing with the output
          filter = "| head -n 1G"
        end
        command += "#{environment} /usr/local/bin/rudder-setup setup-#{setup} \"#{machine['rudder-version']}\" #{arg3} #{filter}\n"
      end
      if dev then
        command += "/vagrant/scripts/dev.sh\n"
      end
      if demo then
        command += "/vagrant/scripts/demo-server-setup.sh\n"
      end
    end
  end
  return command
end

# Workaround for a bug in vagrant-aws plugin : https://github.com/mitchellh/vagrant-aws/issues/566
class Hash
  def slice(*keep_keys)
    h = {}
    keep_keys.each { |key| h[key] = fetch(key) if has_key?(key) }
    h
  end unless Hash.method_defined?(:slice)
  def except(*less_keys)
    slice(*keys - less_keys)
  end unless Hash.method_defined?(:except)
end

class IPAddr
  # Returns the prefix length in bits for the ipaddr.
  def prefix
    case @family
    when Socket::AF_INET
      n = IN4MASK ^ @mask_addr
      i = 32
    when Socket::AF_INET6
      n = IN6MASK ^ @mask_addr
      i = 128
    else
      raise AddressFamilyError, "unsupported address family"
    end
    while n.positive?
      n >>= 1
      i -= 1
    end
    i
  end
end

# TODO deprecated

# keep this function separate for compatibility with older Vagrantfiles
# NET_PREFIX must be a an int between 40 and 150.
def configure(config, os, pf_name, pf_id, host_name, host_id,
              setup:'empty', version:nil, server:'', host_list:'', 
              windows_plugin:false, advanced_reporting:false, dsc_plugin: false,
              ncf_version:nil, cfengine_version:nil, ram:nil, provision:true,
              sync_file:nil, cpus:nil, disk_size:nil
             )
  machine = {
    "system": os,
    "setup": setup,
    "version": version,
    "server": server,
    "host_list": host_list,
    "ram": ram,
    "cpus": cpus,
    "sync_file": sync_file,
  }
  machines = host_list.split(/\s+/)

  # Machine name
  name = pf_name + "_" + host_name

  # Network information
  network, ip, port = network_info(machine, pf_id, host_id)

  # Configure
  config.vm.define name do |cfg|
    # the provisioning script is generated
    cfg.vm.synced_folder ".", "/vagrant", disabled: true # disable default sync
    cfg.vm.synced_folder "scripts", "/vagrant/scripts", type: "rsync"
    cfg.vm.provision :shell, :inline => provisioning_command(machine, host_name, network, machines)

    vagrant_machine(cfg, machines, host_name, machine, name, ip, port)
  end
end

# end of deprecated

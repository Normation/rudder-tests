Adding a platform or an OS
--------------------------
OS are based on atlas vagrant boxes https://atlas.hashicorp.com/boxes/search?vagrantcloud=1
To add a new box, just add a varianble in the existing list in vagrant.rb

Platforms are in platforms/

- Platforms are a list of vm with a configuration that are related in a scenario.
- Platforms are described in json format
- A scenario may have some dependency on a platform content such as host types and names
- The "default" entry in inherited by all other entries
- The "plugins" entry is used to define the plugins that will be installed on the platform server, currently only available for the Rudder dev team.
- Each entry is a node name
- A node name should be "server" or "agentX", this is an assumption in some scenario and in the cleanbox initialization script
- "rudder-setup" describe the type of setup, currently only "agent" and "server" are supported
- "system" is one of the variable of known boxes from vagrant.rb
- "osname" is a substring of the OS name that is discovered by fusion (this is used by the fusion test)
- "provision" empty by default, define the script source to provision the vm, currently only "python" is supported
- "sync_file" folder path (without trailing "/") to deposit script files used in provisioning. If not set, vagrant will use the shared-files to upload the files

```json
{
  "default": { "run-with": "vagrant", "rudder-version": "5.0", "system": "debian9", "inventory-os": "debian" },
  "plugins": { "branding": "1.3", "notify": "1.0" },
  "server" : { "rudder-setup": "server", "sync_file": "/tmp/install" }
}
```

Using libvirt provider with rtf
-------------------------------
You need to install several vagrant plugins to use libvirt (vagrant plugin install *plugin-name*):
- vagrant-libvirt (Support of libvirt as provider)
- vagrant-mutate (To transform virtualbox boxes to libvirt format)

Unless the box is available on Atlas with libvirt provider, You will need to add boxes before lauching your tests:
```
vagrant box add <box-name>
vagrant mutate <box-name> libvirt
```
Some boxes (specially centos 7.2) do not work with vagrant 1.8.3, downgrading to vagrant 1.8.1 fixes the issue

You can then define you are using libivrt as provider by two ways:
- Defining key provider in your "default" section in your platform
- Running platform setup this way: ./rtf platform setup *platform-name*  provider=libvirt

Using aws to provide hosts
--------------------------

It is possible to use rtf with aws. It requires the aws plugin.
```
# The aws plugin available via direct plugin install is wayyy to old (0.0.1) so you must build it (now 0.7.1)
git clone https://github.com/mitchellh/vagrant-aws.git
cd vagrant-aws
apt-get install rake bundler
vi Gemfile # comment last 3 lines referencing vagrant-aws gem
bundle install --path vendor/bundle
rake build
vagrant plugin install pkg/vagrant-aws-*.gem
vagrant box add dummy https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box
```

Install and configure aws cli: see https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html
```
apt install awscli
aws configure
```

Configure VPC: 
- Create a VPC
- Give it one subnet (note the id)
- Give it one internet gateway
- Edit the subnet routing table to route default route through the gateway
Configure a security group (note the id):
- Allow https and ssh from outside: TCP:22, TCP:80, TCP:443
- Allow syslog, and cfengine from inside: previous ones + TCP/UDP:514 TCP:5309
Create a key pair (note the name):
- store the pem on your machine

Configure the parameters at the top of the Vagrantfile:
```
# name of your ssh keypair
$AWS_KEYNAME='rtf-XXX'
# Path of the private key file
$AWS_KEYPATH="rtf-XXX.pem"
# Subnet id in the VPC (id, not name)
$AWS_SUBNET='subnet-0760ec7afa0c7448e'
# Security group id in the VPC (id not name)
$AWS_SECURITY_GROUP='sg-062906d71ed329ae8'
```

You can now use rtf with aws as you usually do with virtualbox.


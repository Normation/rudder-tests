set -x
API_CLIENT="$1"
BOX="$2"
VAGRANT_CACHE="$HOME/.vagrant.d/boxes/$(echo $BOX | sed 's/\//-VAGRANTSLASH-/g')"
# test a given vagrant box in rtf by installing a Rudder server from it
git clone https://github.com/Normation/rudder-tests.git
cd rudder-tests
ln -s "${API_CLIENT}"

# Setup rtf
# clean any potential previous image cache
rm -r "${VAGRANT_CACHE}"
# add box to rtf
sed -i "1s%^%\$packer = \"$BOX\"\n%" vagrant.rb
cat > Vagrantfile <<EOF
# -*- mode: ruby -*-
# vi: set ft=ruby :
\$NET_PREFIX = 80

require_relative 'vagrant.rb'

Vagrant.configure("2") do |config|
config.vm.provider 'virtualbox' do |v|
    v.linked_clone = true if Vagrant::VERSION =~ /^1.8/
end
if Vagrant.has_plugin?("vagrant-cachier")
  config.cache.scope = :box
end

### AUTOGEN TAG

end
EOF
cat > platforms/packer.json <<EOF
{
  "default":{ "run-with": "vagrant", "rudder-version": "latest", "system": "packer", "inventory-os": "suse" },
  "server": { "rudder-setup": "server" }
}
EOF

# run scenario
timeout --preserve-status --signal=SIGTERM 300 ./rtf platform setup packer
status=$?
./rtf platform destroy packer
exit $status


require 'serverspec'
require 'net/ssh'
require 'tempfile'

host = ENV['TARGET_HOST']

if host == "localhost"
  set :backend, :exec
  set :host, host
  set :disable_sudo, true
else
  set :backend, :ssh
  `vagrant up #{host}`

  config = Tempfile.new('', Dir.tmpdir)
  `vagrant ssh-config #{host} > #{config.path}`

  options = Net::SSH::Config.for(host, [config.path])

  options[:user] ||= Etc.getlogin

  set :host,        options[:host_name] || host
  set :ssh_options, options
end

# Some common rudder test elements
url = ENV['RUDDER_SERVER']
token = ENV['RUDDER_TOKEN']
$rudderCli = 'rudder-cli --skip-verify --url=' + url.to_s + ' --token=' + token.to_s


# Set environment variables
# set :env, :LANG => 'C', :LC_MESSAGES => 'C' 

# Set PATH
# set :path, '/sbin:/usr/local/sbin:$PATH'

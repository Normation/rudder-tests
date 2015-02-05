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

# Set environment variables
set :env, :LANG => 'C', :LC_MESSAGES => 'C' 

# Set PATH
# set :path, '/sbin:/usr/local/sbin:$PATH'


# Some common rudder test elements
$params = {}
ENV.each { |key, value|
  if key.start_with?("RUDDER_")
    key2 = key[7..-1]
    $params[key2] = value
  end
}


url = $params['SERVER']
token = $params['TOKEN']
$rudderCli = 'rudder-cli --skip-verify --url=' + url.to_s + ' --token=' + token.to_s


## monkeypatching serverspec

# print test duration in dicumentation format
module RSpec
  module Core
    module Formatters
      # @private
      class DocumentationFormatter < BaseTextFormatter

        def example_passed(passed)
          output.puts passed_output(passed.example)
          output.puts "#{current_indentation}time: #{passed.example.execution_result.run_time}s"
        end

        def example_pending(pending)
          output.puts pending_output(pending.example, pending.example.execution_result.pending_message)
          output.puts "#{current_indentation}time: #{pending.example.execution_result.run_time}s"
        end

        def example_failed(failure)
          output.puts failure_output(failure.example, failure.example.execution_result.exception)
          output.puts "#{current_indentation}time: #{failure.example.execution_result.run_time}s"
        end

      end
    end
  end
end


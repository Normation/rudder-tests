# Register the api_call as a resource
module Serverspec::Helper::Type
 def agent_run()
   Serverspec::Type::AgentRun.new()
 end
end

module Serverspec::Type
  class AgentRun < Base

    def initialize
      @runner  = Specinfra::Runner
      @run = @runner.run_command("rudder agent run -r")
    end

    def reports
      unless @reports
        @reports = []
        @run.stdout.split(/$/).each do |item|
          (@reports.push(Rudder::Report.new(item))) rescue nil
        end
      end
      @reports
    end

    def to_s
      host_inventory['hostname']
      %Q!#{host_inventory['hostname']}: rudder agent run!
    end
  end
end

include Serverspec::Type

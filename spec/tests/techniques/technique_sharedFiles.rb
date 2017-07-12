require 'spec_helper'

file = $params['FILE']
basename = File.basename(file)
destination = "/var/rudder/configuration-repository/shared-files"

describe "File Upload" do
  send_file(file, "/tmp/" + basename)
end

describe command("chown -R root /tmp/" + basename + " && mv /tmp/" + basename + " " + destination + "/") do
  its(:exit_status) { should eq 0 }
end

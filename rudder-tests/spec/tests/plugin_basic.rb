require "spec_helper"

path = $params["PLUGIN_PATH"]
plugin_name = $params["PLUGIN_NAME"]
plugin_version = $params["PLUGIN_VERSION"]

describe("Rpkg") do
  describe command("ar -t #{path}") do
    its(:exit_status) { should eq 0 }
    its(:stdout) {
      should satisfy { |output|
         output.split("\n").all? { |line| line.match(/(metadata|.*\.txz)/)}
      }
    }
    its(:stdout) { should contain "metadata" }
    its(:stdout) { should contain "scripts.txz" }

    $actual_archives = described_class.stdout.split("\n").select { |archive| archive.match(/.*\.txz/) }
  end
end

describe("Metadata") do
  describe command("ar -p #{path} metadata") do
    its(:exit_status) { should eq 0 }
    its(:stdout_as_json) { should include("type" => "plugin") }
    its(:stdout_as_json) { should include("name" => "rudder-plugin-#{plugin_name}") }
    its(:stdout_as_json) { should include("version" => match(/^\d+\.\d+-\d+\.\d+(-nightly)?$/)) }
    its(:stdout_as_json) { should include("version" => "#{plugin_version}") }

    # Packaging files are not listed in the metadata
    it { expect(subject.stdout_as_json["content"].keys).to match_array $actual_archives - ["scripts.txz"]  }
  end
end

require 'spec_helper'

group = $params['GROUP']
name = $params['NAME']

directiveFile = "/tmp/directive.json"
ruleFile = "/tmp/rule.json"

describe "Add a user directive and a rule"  do

  # Add a User directive
  describe command($rudderCli + " directive create --json=" + directiveFile + " userManagement user") do
    before(:all) {
      File.open(directiveFile, 'w') { |file| 
        file << <<EOF
{
  "displayName": "#{name} Directive",
  "longDescription": "Test user management description",
  "enabled": true,
  "parameters": {
    "section": {
      "name": "sections",
      "sections": [
        {
          "section": {
            "name": "Users",
            "sections": [
              {
                "section": {
                  "name": "Password",
                  "vars": [
                    {
                      "var": {
                        "name": "USERGROUP_USER_PASSWORD",
                        "value": "linux-shadow-md5:$1$.wI5w6TO$GJln9oltmP1JLnSmyTCX11"
                      }
                    }
                  ]
                }
              }
            ],
            "vars": [
              {
                "var": {
                  "name": "USERGROUP_USER_ACTION",
                  "value": "add"
                }
              },
              {
                "var": {
                  "name": "USERGROUP_USER_GROUP",
                  "value": ""
                }
              },
              {
                "var": {
                  "name": "USERGROUP_USER_HOME",
                  "value": ""
                }
              },
              {
                "var": {
                  "name": "USERGROUP_USER_HOME_PERSONNALIZE",
                  "value": "true"
                }
              },
              {
                "var": {
                  "name": "USERGROUP_USER_LOGIN",
                  "value": "testuser"
                }
              },
              {
                "var": {
                  "name": "USERGROUP_USER_NAME",
                  "value": "Test user"
                }
              },
              {
                "var": {
                  "name": "USERGROUP_USER_PASSWORD_POLICY",
                  "value": "oneshot"
                }
              },
              {
                "var": {
                  "name": "USERGROUP_USER_SHELL",
                  "value": "/bin/bash"
                }
              },
              {
                "var": {
                  "name": "USERGROUP_USER_UID",
                  "value": ""
                }
              }
            ]
          }
        }
      ]
    }
  },
  "shortDescription": "Test User short desc",
  "techniqueName": "userManagement"
}
EOF
      }
    }
    after(:all) {
      File.delete(directiveFile)
    }
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match /^"[0-9a-f\-]+"$/ }
    it {
      # register output uuid for next command
      $uuid = subject.stdout.gsub(/^"|"$/, "").chomp()
      puts $uuid
    }
  end

  # create a rule
  describe command($rudderCli + " rule create --json=" + ruleFile + " testRule") do
    before(:all) {
      File.open(ruleFile, 'w') { |file|
        file << <<EOF
{
  "directives": [
    "#{$uuid}"
  ],
  "displayName": "#{name} Rule",
  "longDescription": "Test User Rule Description",
  "shortDescription": "Test User Rule short desc",
  "targets": [
    {
      "exclude": {
        "or": []
      },
      "include": {
        "or": [
          "#{group}"
        ]
      }
    }
  ]
}
EOF
      }
    }
    after(:all) {
      File.delete(ruleFile)
    }
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match /^"[0-9a-f\-]+"$/ }
    it {
      # register output uuid for next command
      $uuid = subject.stdout.gsub(/^"|"$/, "").chomp()
      puts $uuid
    }
  end

end

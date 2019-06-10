require 'spec_helper'

group = $params['GROUP']
name = $params['NAME']

directiveFile = "/tmp/directive.json"
ruleFile = "/tmp/rule.json"
directiveName = "#{name}"

describe "Add a user directive and a rule"  do

  # Add a User directive
  describe command($rudderCli + " directive create --json=" + directiveFile + " userManagement " + "\"" + directiveName + " Directive\"" + " | jq '.directives[0].id'") do
    before(:all) {
      File.open(directiveFile, 'w') { |file| 
        file << <<EOF
{
    "displayName": "#{name} Directive",
    "enabled": true, 
    "id": "009f509d-6afc-47fb-bcfb-5212925f02bc", 
    "longDescription": "", 
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
                                    "name": "Home directory"
                                }
                            }, 
                            {
                                "section": {
                                    "name": "Password", 
                                    "vars": [
                                        {
                                            "var": {
                                                "name": "USERGROUP_USER_PASSWORD", 
                                                "value": "linux-shadow-sha256:$5$YNADkZ07$htb77c7EFCvMnMriWLRK.MWDWkQOuZ8ErNJxW.TAK2A"
                                            }
                                        }, 
                                        {
                                            "var": {
                                                "name": "USERGROUP_USER_PASSWORD_AIX", 
                                                "value": "aix-ssha256:{ssha256}10$Sa/QDr9A9NY2wu7y$Onehh4RXy32259lis.Wm.s3NqH3rhLYaxGXuRy/I.67"
                                            }
                                        }
                                    ]
                                }
                            }, 
                            {
                                "section": {
                                    "name": "UNIX specific options", 
                                    "vars": [
                                        {
                                            "var": {
                                                "name": "USERGROUP_FORCE_USER_GROUP", 
                                                "value": "false"
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
                                                "name": "USERGROUP_USER_HOME_MOVE", 
                                                "value": "false"
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
                                                "name": "USERGROUP_USER_NAME", 
                                                "value": ""
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
                                    "name": "USERGROUP_USER_LOGIN", 
                                    "value": "testuser"
                                }
                            }, 
                            {
                                "var": {
                                    "name": "USERGROUP_USER_PASSWORD_POLICY", 
                                    "value": "everytime"
                                }
                            }
                        ]
                    }
                }
            ]
        }
    }, 
    "shortDescription": "", 
    "techniqueName": "userManagement"
}

EOF
      }
    }
    after(:all) {
      File.delete(directiveFile)
    }
    its(:stdout) { should match /^"[0-9a-f\-]+"$/ }
    its(:exit_status) { should eq 0 }
    it {
      # register output uuid for next command
      $uuid = subject.stdout.gsub(/^"|"$/, "").chomp()
    }
  end

  # create a rule
  describe command($rudderCli + " rule create --json=" + ruleFile + " \"#{name} Rule\"") do
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
    its(:stdout) { should match /^"[0-9a-f\-]+"$/ }
    its(:exit_status) { should eq 0 }
    it {
      # register output uuid for next command
      $uuid = subject.stdout.gsub(/^"|"$/, "").chomp()
    }
  end

end

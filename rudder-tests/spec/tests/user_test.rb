require 'spec_helper'

username = $params['USERNAME']

describe user("#{username}") do
  it { should exist }
  it { should have_home_directory "/home/#{username}" }
end


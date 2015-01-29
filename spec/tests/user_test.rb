require 'spec_helper'


describe user('testuser') do
  it { should exist }
  it { should have_home_directory '/home/testuser' }
end


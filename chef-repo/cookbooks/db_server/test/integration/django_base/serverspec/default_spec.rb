# Cookbook:: db_server
# Serverspec:: default

require 'spec_helper'

set :backend, :exec

describe file('/var/log/chef-kitchen/chef-client.log') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_mode 644 }
  its(:content) { should_not match(/ERROR/)}
  its(:content) { should_not match(/FATAL/)}
end
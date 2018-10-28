# Cookbook Name:: db_server
# Serverspec:: redis

require 'spec_helper'

set :backend, :exec

if os[:family] == 'ubuntu'
  # apt repository for redis should be there
  describe file('/etc/apt/sources.list.d/redis-server.list') do
    it { should_not exist }
  end

  # redis should not be installed
  describe package('redis-server') do
    it { should_not be_installed }
  end

  # redis should not be running
  describe service('redis-server') do
    it { should_not be_enabled }
    it { should_not be_running }
  end
end

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

describe package('unattended-upgrades') do
  it { should be_installed }
end

describe package('bsd-mailx') do
  it { should_not be_installed }
end

describe file('/etc/apt/apt.conf.d/50unattended-upgrades') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_mode 644 }
  its(:md5sum) { should eq '6435438c08332ad23d59aec068e6bc1f' }
  it { should contain 'Unattended-Upgrade::Mail "admin@example.com";' }
end

describe file('/etc/apt/apt.conf.d/20auto-upgrades') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_mode 644 }
  its(:md5sum) { should eq '1c261d6541420797f8b824d65ac5c197' }
end

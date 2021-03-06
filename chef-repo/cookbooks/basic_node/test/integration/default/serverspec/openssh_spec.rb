# Cookbook Name:: basic_node
# Recipe:: openssh

require 'spec_helper'

set :backend, :exec

describe package('openssh-server') do
  it { should be_installed }
end

describe service('ssh') do
  it { should be_enabled }
  it { should be_running }
end

describe file('/home/node_admin/.ssh') do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by 'node_admin' }
  it { should be_grouped_into 'node_admin' }
  it { should be_mode 750 }
end

describe file('/home/node_admin/.ssh/authorized_keys') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'node_admin' }
  it { should be_grouped_into 'node_admin' }
  it { should be_mode 640 }
  its(:md5sum) { should eq '77322ef05ceebe1647ba639bf15924cf' }
  its(:content) { should match(%r(ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDV6LFiLYnDGQu/DFgMcuAD1BAqQp9cjKM5872hHS4d3tIeT5kcW7jUhEkJqo5OFtmPChdI4IchlzkuOzUHvNAuwgUkbhp0HSXDUiXCUDJLTkBsCg7iYIBEmqQF/xPHYvYoMmJxx4nS6SuXh9iYAHanGmEnVQtAChzbkEsARGhOG9CpUnqz7v\+35qymNeEaj2Imw7ItQTh3WFZRzD\+vaAh5\+tmgE2JvjiGWt5NQa/5E91VOOj9hfzMzArGoCVDfTmdReyMYHKpVH3vb4uRfXU9/aewPj8ue1VJ25FbA3Z1vb9bjWAF4qwvJpXhWWY3rZeBD2cL4i5uLfDa2uBjb3JmdBR71oD/OiomJWfdC9zKjQTh8FGt32GQxFi35jUthBV2gIiyxAuFkBjyTnXoTXMUtjUoTl6KIwBuOoEvEA337IwyPT7yb4mFbK5giV4KwlXmX8Ju/sL9NYq8Dku95ZtLlz4wyaY2SF8RDPh8GsB/EVE/UYvlOSOZvYYKZkRCHWMGTVHUUmOWlq7UUPD8Pl3hUFaVAHzeRTumeXC3jhntVW1wRpIYDSXvdVzurfxpMrmvA\+HQUxxHm17Kj5aq47Zoh2vZWsIUyPpsHv/mmvumZSoeCw\+0b302XvSVYTy7j73amvewB4UJFI14ocnSH0jAE\+axn7PYJr1WB6QB14FE2Bw== admin@adminPC))}
end

describe file('/etc/ssh/sshd_config') do
  sshd_config = [
      /^PermitRootLogin no/,
      /^PasswordAuthentication no/,
      /^PubkeyAuthentication yes/,
      /^RSAAuthentication yes/,
      /^AllowUsers node_admin vagrant/
  ]
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_mode 644 }
  its(:md5sum) { should eq '3e073988392c63ddaa23b5e784a07874' }
  sshd_config.each do |p|
    its(:content) { should match(p)}
  end
end

# Cookbook Name:: basic_node
# Recipe:: default

include_recipe 'chef-vault'

node_admin_item = chef_vault_item('basic_node', "node_admin#{node['basic_node']['node_number']}")

node.default['apt']['unattended_upgrades']['mail'] = node_admin_item['email']

include_recipe 'apt::default'
include_recipe 'apt::unattended-upgrades'

resources('package[bsd-mailx]').action []

include_recipe 'basic_node::mail'
include_recipe 'basic_node::admin_user'
include_recipe 'basic_node::openssh'
include_recipe 'basic_node::security_updates'
include_recipe 'basic_node::firewall'
include_recipe 'basic_node::ntp'

if node['basic_node']['remote_unlock']['encryption']
  include_recipe 'basic_node::remote_unlock'
end

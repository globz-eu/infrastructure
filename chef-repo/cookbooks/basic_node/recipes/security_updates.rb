# Cookbook Name:: basic_node
# Recipe:: security_updates

include_recipe 'chef-vault'

node_admin_item = chef_vault_item('basic_node', "node_admin#{node['basic_node']['node_number']}")

package 'apticron'

template '/etc/apticron/apticron.conf' do
  source 'apticron.conf.erb'
  action :create
  owner 'root'
  group 'root'
  mode '0644'
  variables(admin_email: node_admin_item['email'])
end

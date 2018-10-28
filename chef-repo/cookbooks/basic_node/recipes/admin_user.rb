# Cookbook Name:: basic_node
# Recipe:: admin_user

include_recipe 'chef-vault'

node_admin_item = chef_vault_item('basic_node', "node_admin#{node['basic_node']['node_number']}")

user node_admin_item['user'] do
  home "/home/#{node_admin_item['user']}"
  manage_home true
  password node_admin_item['password']
  shell '/bin/bash'
end

group 'sudo' do
  action :manage
  members node_admin_item['user']
  append true
end

group 'adm' do
  action :manage
  members node_admin_item['user']
  append true
end

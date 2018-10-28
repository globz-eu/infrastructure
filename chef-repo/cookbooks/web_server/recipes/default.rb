# Cookbook Name:: web_server
# Recipe:: default

include_recipe 'apt::default'
include_recipe 'chef-vault'

node_nr = node['web_server']['node_number']
web_user_item = chef_vault_item('web_user', "web_user#{node_nr}")
web_user = web_user_item['user']

if node['install_scripts']['users'].empty?
  node.default['install_scripts']['users'] = [
      {user: web_user, password: web_user_item['password'], groups: %w(www-data loggers), scripts: 'web'}
  ]
  include_recipe 'install_scripts::user'
  if node['install_scripts']['git']['app_repo']
    include_recipe 'install_scripts::scripts'
  end
end

include_recipe 'web_server::nginx'

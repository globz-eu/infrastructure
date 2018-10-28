# Cookbook Name:: db_server
# Recipe:: default

include_recipe 'apt::default'
include_recipe 'chef-vault'

db_user_item = chef_vault_item('pg_server', "db_user#{node['db_server']['node_number']}")
db_user = db_user_item['user']

if node['install_scripts']['users'].empty?
  node.default['install_scripts']['users'] = [{user: db_user, password: db_user_item['password_hash'], scripts: 'db'}]
  include_recipe 'install_scripts::user'
  if node['install_scripts']['git']['app_repo']
    include_recipe 'install_scripts::scripts'
  end
end

include_recipe 'db_server::postgresql'
include_recipe 'db_server::redis'

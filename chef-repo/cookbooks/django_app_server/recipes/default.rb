# Cookbook Name:: django_app_server
# Recipe:: default

include_recipe 'apt::default'
include_recipe 'chef-vault'

app_user_item = chef_vault_item('app_user', "app_user#{node['django_app_server']['node_number']}")
app_user = app_user_item['user']

if node['install_scripts']['users'].empty?
  node.default['install_scripts']['users'] = [
      {user: app_user, password: app_user_item['password'], groups: %w(www-data loggers), scripts: 'app'},
  ]
  include_recipe 'install_scripts::user'
  if node['install_scripts']['git']['app_repo']
    include_recipe 'install_scripts::scripts'
  end
end

include_recipe 'django_app_server::python'
include_recipe 'django_app_server::uwsgi'
include_recipe 'django_app_server::django_app'

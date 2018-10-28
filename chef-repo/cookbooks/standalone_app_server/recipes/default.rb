# Cookbook Name:: standalone_app_server
# Recipe:: default

include_recipe 'apt::default'
include_recipe 'chef-vault'

node_nr = node['standalone_app_server']['node_number']
db_user_item = chef_vault_item('pg_server', "db_user#{node_nr}")
db_user = db_user_item['user']
app_user_item = chef_vault_item('app_user', "app_user#{node_nr}")
app_user = app_user_item['user']
web_user_item = chef_vault_item('web_user', "web_user#{node_nr}")
web_user = web_user_item['user']

node.default['install_scripts']['users'] = [
    {user: db_user, password: db_user_item['password_hash'], scripts: 'db'},
    {user: app_user, password: app_user_item['password'], groups: %w(www-data loggers), scripts: 'app'},
    {user: web_user, password: web_user_item['password'], groups: %w(www-data loggers), scripts: 'web'}
]
node.default['django_app_server']['django_app']['celery'] = node['standalone_app_server']['start_app']['celery']

include_recipe 'install_scripts::user'
include_recipe 'install_scripts::scripts'
include_recipe 'db_server::default'
include_recipe 'django_app_server::default'
include_recipe 'web_server::default'

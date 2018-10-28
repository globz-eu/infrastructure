# Cookbook:: standalone_app_server
# Attributes:: default

default['standalone_app_server']['node_number'] = '000'
node_nr = node['standalone_app_server']['node_number']
default['standalone_app_server']['git']['app_repo'] = 'https://github.com/globz-eu/django_base.git'
app_repo = node['standalone_app_server']['git']['app_repo']
default['standalone_app_server']['start_app']['celery'] = false
default['standalone_app_server']['update']['purge_db'] = true

default['install_scripts']['git']['app_repo'] = app_repo

default['django_app_server']['node_number'] = node_nr
default['django_app_server']['git']['app_repo'] = app_repo

default['db_server']['node_number'] = node_nr
default['db_server']['git']['app_repo'] = app_repo

default['web_server']['node_number'] = node_nr
default['web_server']['git']['app_repo'] = app_repo
default['web_server']['nginx']['server_name'] = false
default['web_server']['nginx']['https'] = false
ssl = node['web_server']['nginx']['https']

if ssl
  default['basic_node']['firewall']['web_server'] = 'https'
else
  default['basic_node']['firewall']['web_server'] = 'http'
end

default['basic_node']['node_number'] = node_nr

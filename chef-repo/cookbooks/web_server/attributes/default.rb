# Cookbook Name:: web_server

default['web_server']['node_number'] = '000'
node_nr = node['web_server']['node_number']

default['web_server']['node_number'] = node_nr
default['web_server']['git']['app_repo'] = false
app_repo = node['web_server']['git']['app_repo']
default['web_server']['nginx']['git']['scripts_repo'] = 'https://github.com/globz-eu/scripts.git'
default['web_server']['nginx']['server_name'] = false
default['web_server']['nginx']['app_home'] = false
default['web_server']['nginx']['https'] = false
default['web_server']['nginx']['www'] = false
ssl = node['web_server']['nginx']['https']

default['basic_node']['node_number'] = node_nr

if ssl
  default['basic_node']['firewall']['web_server'] = ['http', 'https']
else
  default['basic_node']['firewall']['web_server'] = ['http']
end

if app_repo
  default['install_scripts']['git']['app_repo'] = app_repo
else
  default['install_scripts']['git']['app_repo'] = false
end

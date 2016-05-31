default['web_server']['nginx']['app_name'] = 'django_base'
default['web_server']['nginx']['scripts_repo'] = 'https://github.com/gloz-eu/scripts'
default['web_server']['nginx']['app_repo'] = 'https://github.com/gloz-eu/django_base'
default['web_server']['nginx']['static_path'] = "/var/www/#{default['web_server']['nginx']['app_name']}/static"
default['web_server']['nginx']['server_name'] = '192.168.1.81'

default['basic_node']['firewall']['web_server'] = true

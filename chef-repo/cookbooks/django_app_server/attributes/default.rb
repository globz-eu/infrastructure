# Cookbook Name:: django_app_server

default['poise-python']['install_python2'] = false

default['django_app_server']['node_number'] = '000'
default['django_app_server']['git']['app_repo'] = false
app_repo = node['django_app_server']['git']['app_repo']
default['django_app_server']['git']['scripts_repo'] = 'https://github.com/globz-eu/scripts.git'
default['django_app_server']['django_app']['debug'] = 'False'
default['django_app_server']['django_app']['allowed_host'] = false
default['django_app_server']['django_app']['engine'] = 'django.db.backends.postgresql_psycopg2'
default['django_app_server']['django_app']['db_host'] = 'localhost'
default['django_app_server']['django_app']['celery'] = false
default['django_app_server']['django_app']['db_user'] = 'db_user'
default['django_app_server']['uwsgi']['processes'] = '2'
default['django_app_server']['uwsgi']['socket'] = 'unix'

if app_repo
  default['install_scripts']['git']['app_repo'] = app_repo
else
  default['install_scripts']['git']['app_repo'] = false
end

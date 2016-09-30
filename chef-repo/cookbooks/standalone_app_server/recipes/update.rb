# =====================================================================
# Web app infrastructure for Django project
# Copyright (C) 2016 Stefan Dieterle
# e-mail: golgoths@yahoo.fr
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# =====================================================================
#
# Cookbook Name:: standalone_app_server
# Recipe:: update

include_recipe 'chef-vault'

node_nr = node['standalone_app_server']['node_number']

db_user_item = chef_vault_item('pg_server', "db_user#{node_nr}")
db_user = db_user_item['user']
app_user_item = chef_vault_item('app_user', "app_user#{node_nr}")
app_user = app_user_item['user']
web_user_item = chef_vault_item('web_user', "web_user#{node_nr}")
web_user = web_user_item['user']
app_repo = node['django_app_server']['git']['app_repo']
/https:\/\/github.com\/[\w\-]+\/(?<name>\w+)\.git/ =~ app_repo
unless name == nil
  app_name = name
end

celery = node['standalone_app_server']['start_app']['celery']

bash 'server_down' do
  cwd "/home/#{web_user}/sites/#{app_name}/scripts"
  code './webserver.py -s down'
  user 'root'
end

bash 'stop_uwsgi' do
  cwd "/home/#{app_user}/sites/#{app_name}/scripts"
  code './djangoapp.py -u stop'
  user 'root'
end

bash 'stop_celery' do
  cwd "/home/#{app_user}/sites/#{app_name}/scripts"
  code './djangoapp.py -c stop'
  user 'root'
end if celery

bash 'restore_static' do
  cwd "/home/#{web_user}/sites/#{app_name}/scripts"
  code './webserver.py -r'
  user 'root'
end

bash 'remove_app' do
  cwd "/home/#{app_user}/sites/#{app_name}/scripts"
  code './djangoapp.py -x'
  user 'root'
end

bash 'db_reset' do
  cwd "/home/#{db_user}/sites/#{app_name}/scripts"
  code './dbserver.py -r'
  user 'root'
end

bash 'reinstall_app' do
  cwd "/home/#{app_user}/sites/#{app_name}/scripts"
  code './djangoapp.py -imt'
  user 'root'
end

bash 'restart_celery' do
  cwd "/home/#{app_user}/sites/#{app_name}/scripts"
  code './djangoapp.py -c start'
  user 'root'
end if celery

bash 'restart_uwsgi' do
  cwd "/home/#{app_user}/sites/#{app_name}/scripts"
  code './djangoapp.py -u start'
  user 'root'
end

bash 'server_up' do
  cwd "/home/#{web_user}/sites/#{app_name}/scripts"
  code './webserver.py -s up'
  user 'root'
end

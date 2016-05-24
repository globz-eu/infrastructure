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
# Cookbook:: standalone_app_server
# Recipe:: start_app

include_recipe 'chef-vault'

app_user_vault = chef_vault_item('app_user', 'app_user')
app_user = app_user_vault['user']
app_name = node['django_app_server']['django_app']['app_name']

# TODO: replace by script
bash 'migrate' do
  cwd "/home/#{app_user}/sites/#{app_name}/source/#{app_name}"
  code "/home/#{app_user}/.envs/#{app_name}/bin/python ./manage.py migrate --settings #{app_name}.settings_admin"
  user 'root'
end

directory "/var/log/#{app_name}/test_results" do
  owner 'root'
  group 'root'
  mode '0700'
end

bash 'test_app' do
  cwd "/home/#{app_user}/sites/#{app_name}/source/#{app_name}"
  code "/home/#{app_user}/.envs/#{app_name}/bin/python ./manage.py test --settings #{app_name}.settings_admin &> /var/log/#{app_name}/test_results/test_$(date +\"%d-%m-%y-%H%M%S\").log"
  user 'root'
end

# TODO: move static content to static folder

file "/etc/nginx/sites-enabled/#{app_name}_down.conf" do
  action :delete
end

link "/etc/nginx/sites-enabled/#{app_name}.conf" do
  owner 'root'
  group 'root'
  to "/etc/nginx/sites-available/#{app_name}.conf"
  notifies :restart, 'service[nginx]', :immediately
end

bash 'start_uwsgi' do
  cwd "/home/#{app_user}/sites/#{app_name}/source"
  code 'uwsgi --ini ./django_base_uwsgi.ini '
  user 'root'
end

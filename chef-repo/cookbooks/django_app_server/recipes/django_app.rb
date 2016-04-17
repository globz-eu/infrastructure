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
# Cookbook Name:: django_app_server
# Recipe:: django_app
#
# Manages django app configuration, app dependencies, package
# requirements, static and media content

include_recipe 'chef-vault'
include_recipe 'poise-python::default'

app_user_vault = chef_vault_item('app_user', 'app_user')
django_app_vault = chef_vault_item('django_app', 'app')

# create static content directory
directory "/home/#{app_user_vault['user']}/sites/#{node['django_app_server']['app_name']}/static" do
  owner app_user_vault['user']
  group 'www-data'
  mode '0750'
end

# create media directory
directory "/home/#{app_user_vault['user']}/sites/#{node['django_app_server']['app_name']}/media" do
  owner app_user_vault['user']
  group 'www-data'
  mode '0750'
end

# add app path to venv python path
template "/home/#{app_user_vault['user']}/.envs/#{node['django_app_server']['app_name']}/lib/python3.4/#{node['django_app_server']['app_name']}.pth" do
  source 'app_name.pth.erb'
  action :create
  owner app_user_vault['user']
  group app_user_vault['user']
  mode '0400'
  variables({
                app_path: "/home/#{app_user_vault['user']}/sites/#{node['django_app_server']['app_name']}/source",
            })
end

# create host-specific configuration file for django app
template "/home/#{app_user_vault['user']}/sites/#{node['django_app_server']['app_name']}/source/configuration.py" do
  source 'configuration.py.erb'
  action :create
  owner app_user_vault['user']
  group app_user_vault['user']
  mode '0400'
  variables({
                secret_key: django_app_vault['secret_key'],
                debug: node['django_app_server']['debug'],
                allowed_host: node['django_app_server']['allowed_host'],
                engine: node['django_app_server']['engine'],
                app_name: node['django_app_server']['app_name'],
                db_user: django_app_vault['db_user'],
                db_user_password: django_app_vault['db_user_password'],
                db_host: node['django_app_server']['db_host']
            })
end

# create django settings file for administrative tasks (manage.py)
template "/home/#{app_user_vault['user']}/sites/#{node['django_app_server']['app_name']}/source/#{node['django_app_server']['app_name']}/settings_admin.py" do
  source 'settings_admin.py.erb'
  action :create
  owner app_user_vault['user']
  group app_user_vault['user']
  mode '0400'
  variables({
                secret_key: django_app_vault['secret_key'],
                debug: node['django_app_server']['debug'],
                allowed_host: node['django_app_server']['allowed_host'],
                engine: node['django_app_server']['engine'],
                app_name: node['django_app_server']['app_name'],
                # TODO: manage installed apps for settings_admin.py
                installed_apps: "'django_base'",
                db_admin_user: django_app_vault['db_admin_user'],
                db_admin_password: django_app_vault['db_admin_password'],
                db_host: node['django_app_server']['db_host']
            })
end

# create python script for installation of system dependencies
template "/home/#{app_user_vault['user']}/sites/#{node['django_app_server']['app_name']}/source/install_dependencies.py" do
  source 'install_dependencies.py.erb'
  action :create
  owner app_user_vault['user']
  group app_user_vault['user']
  mode '0500'
  variables({
              dep_file_path: "/home/#{app_user_vault['user']}/sites/#{node['django_app_server']['app_name']}/source/system_dependencies.txt"
            })
end

# install system dependencies for app python packages
bash 'install_dependencies' do
  cwd "/home/#{app_user_vault['user']}/sites/#{node['django_app_server']['app_name']}/source"
  code './install_dependencies.py'
  user 'root'
end

# install python packages for app
bash 'install_requirements' do
  cwd "/home/#{app_user_vault['user']}/sites/#{node['django_app_server']['app_name']}/source"
  code "/home/#{app_user_vault['user']}/.envs/#{node['django_app_server']['app_name']}/bin/pip3 install -r ./requirements.txt"
  user 'root'
end

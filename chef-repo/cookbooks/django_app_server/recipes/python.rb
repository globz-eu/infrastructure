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
# Recipe:: python

include_recipe 'poise-python::default'
include_recipe 'chef-vault'

app_user_item = chef_vault_item('app_user', 'app_user')

python_runtime '3.4'

directory "/home/#{app_user_item['user']}/.envs" do
  owner app_user_item['user']
  group app_user_item['user']
  mode '0500'
end

directory "/home/#{app_user_item['user']}/.envs/#{node['django_app_server']['app_name']}" do
  owner app_user_item['user']
  group app_user_item['user']
  mode '0500'
end

python_virtualenv "/home/#{app_user_item['user']}/.envs/#{node['django_app_server']['app_name']}" do
  python '3.4'
end

package 'python3-numpy'

python_package 'numpy' do
  version '1.11.0'
  virtualenv "/home/#{app_user_item['user']}/.envs/#{node['django_app_server']['app_name']}"
end

execute "chown -R #{app_user_item['user']}:#{app_user_item['user']} /home/app_user/.envs/#{node['django_app_server']['app_name']}"
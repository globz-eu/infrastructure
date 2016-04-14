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
# Recipe:: git

include_recipe 'chef-vault'

app_user_item = chef_vault_item('app_user', 'app_user')

package 'git'

directory "/home/#{app_user_item['user']}/sites" do
  owner app_user_item['user']
  group 'www-data'
  mode '0750'
end

directory "/home/#{app_user_item['user']}/sites/#{node['django_app_server']['app_name']}" do
  owner app_user_item['user']
  group 'www-data'
  mode '0750'
end

directory "/home/#{app_user_item['user']}/sites/#{node['django_app_server']['app_name']}/source" do
  owner app_user_item['user']
  group 'app_user'
  mode '0750'
end

git "/home/#{app_user_item['user']}/sites/#{node['django_app_server']['app_name']}/source" do
  repository node['django_app_server']['git_repo']
end

execute 'chown -R app_user:app_user /home/app_user/sites/app_name/source'

execute 'find /home/app_user/sites/app_name/source -type f -exec chmod 0400 {} +'

execute 'find /home/app_user/sites/app_name/source -type d -exec chmod 0500 {} +'
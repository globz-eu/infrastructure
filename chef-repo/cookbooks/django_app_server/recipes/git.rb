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

# TODO move to django_app

include_recipe 'chef-vault'

app_user_item = chef_vault_item('app_user', 'app_user')
app_user = app_user_item['user']
app_name = node['django_app_server']['django_app']['app_name']

package 'git'

directory "/home/#{app_user}/sites" do
  owner app_user
  group 'www-data'
  mode '0550'
end

# if app_name
#   directory "/home/#{app_user}/sites/#{app_name}" do
#     owner app_user
#     group 'www-data'
#     mode '0550'
#   end
#
#   directory "/home/#{app_user}/sites/#{app_name}/source" do
#     owner app_user
#     group app_user
#     mode '0500'
#   end
#
#   # TODO: replace git clone by script
#   bash 'git_clone_app' do
#     cwd "/home/#{app_user}/sites/#{app_name}/source"
#     code "git clone #{node['django_app_server']['git']['git_repo']}"
#     user 'root'
#   end
#
#   execute "chown -R #{app_user}:#{app_user} /home/#{app_user}/sites/#{app_name}/source"
#
#   execute "find /home/#{app_user}/sites/#{app_name}/source -type f -exec chmod 0400 {} +"
#
#   execute "find /home/#{app_user}/sites/#{app_name}/source -type d -exec chmod 0500 {} +"
# end

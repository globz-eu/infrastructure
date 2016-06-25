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
# Recipe:: default

include_recipe 'apt::default'
include_recipe 'chef-vault'

app_user_item = chef_vault_item('app_user', "app_user#{node['django_app_server']['node_number']}")
app_user = app_user_item['user']

if node['install_scripts']['users'].empty?
  node.default['install_scripts']['users'] = [
      {user: app_user, password: app_user_item['password'], groups: ['www-data'], scripts: 'app'},
  ]
  include_recipe 'install_scripts::user'
  include_recipe 'install_scripts::scripts'
end

include_recipe 'django_app_server::python'
include_recipe 'django_app_server::uwsgi'
include_recipe 'django_app_server::django_app'

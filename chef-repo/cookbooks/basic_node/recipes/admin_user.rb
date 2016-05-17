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
# Cookbook Name:: basic_node
# Recipe:: admin_user

include_recipe 'chef-vault'

node_admin_item = chef_vault_item("basic_node#{node['basic_node']['node_number']}", 'node_admin')

user node_admin_item['user'] do
  home "/home/#{node_admin_item['user']}"
  supports :manage_home => true
  password node_admin_item['password']
  shell '/bin/bash'
end

group 'sudo' do
  action :manage
  members node_admin_item['user']
  append true
end

group 'adm' do
  action :manage
  members node_admin_item['user']
  append true
end

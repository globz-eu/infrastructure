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
# Cookbook Name:: db_server
# Recipe:: default

include_recipe 'apt::default'
include_recipe 'chef-vault'

db_user_item = chef_vault_item('pg_server', "db_user#{node['db_server']['node_number']}")
db_user = db_user_item['user']

if node['install_scripts']['users'].empty?
  node.default['install_scripts']['users'] = [{user: db_user, password: db_user_item['password_hash'], scripts: 'db'}]
  include_recipe 'install_scripts::user'
  if node['install_scripts']['git']['app_repo']
    include_recipe 'install_scripts::scripts'
  end
end

include_recipe 'db_server::postgresql'
include_recipe 'db_server::redis'

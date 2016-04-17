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
# Recipe:: app_user

include_recipe 'chef-vault'

app_user_item = chef_vault_item('app_user', 'app_user')
app_user = app_user_item['user']

user app_user do
  home "/home/#{app_user}"
  supports :manage_home => true
  password app_user_item['password']
  shell '/bin/bash'
end

group 'www-data' do
  action :manage
  members app_user
  append true
end
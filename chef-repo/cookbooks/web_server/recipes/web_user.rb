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
# Recipe:: web_user

include_recipe 'chef-vault'

web_user_item = chef_vault_item('web_user', 'web_user')
web_user = app_user_item['user']

user web_user do
  home "/home/#{web_user}"
  supports :manage_home => true
  password web_user_item['password']
  shell '/bin/bash'
end

group 'www-data' do
  action :manage
  members web_user
  append true
end
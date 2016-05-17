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

app_name = node['django_app_server']['django_app']['app_name']

include_recipe 'apt::default'
include_recipe 'chef-vault'
include_recipe 'django_app_server::app_user'
include_recipe 'django_app_server::git'
include_recipe 'django_app_server::python'

# if app_name
#   include_recipe 'django_app_server::django_app'
# end

include_recipe 'django_app_server::uwsgi'

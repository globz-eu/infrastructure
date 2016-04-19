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
# Recipe:: uwsgi
#
# Installs uwsgi python package globally, generates uwsgi.ini config
# file

include_recipe 'poise-python::default'
include_recipe 'chef-vault'

app_user_item = chef_vault_item('app_user', 'app_user')
app_user = app_user_item['user']
app_name = node['django_app_server']['django_app']['app_name']

if node['django_app_server']['uwsgi']['socket'] == 'unix'
  socket = "/home/#{app_user}/sites/#{app_name}/sockets/#{app_name}.sock"
  chmod_socket = 'chmod-socket = 660'
else if node['django_app_server']['uwsgi']['socket'] == 'tcp'
  socket = ':8001'
  chmod_socket = '# chmod-socket = 660'
     else
       socket = "/home/#{app_user}/sites/#{app_name}/sockets/#{app_name}.sock"
       chmod_socket = '# chmod-socket = 660'
     end
end

python_package 'uwsgi' do
  python '/usr/bin/python3.4'
end

directory '/var/log/uwsgi' do
  owner 'root'
  group 'root'
  mode '0755'
end

template "/home/#{app_user}/sites/#{app_name}/source/#{app_name}_uwsgi.ini" do
  owner app_user
  group app_user
  mode '0400'
  source 'app_name_uwsgi.ini.erb'
  variables({
      app_name: node['django_app_server']['django_app']['app_name'],
      app_user: app_user,
      processes: node['django_app_server']['uwsgi']['processes'],
      socket: socket,
      chmod_socket: chmod_socket,
      log_file: "/var/log/uwsgi/#{app_name}.log",
      pid_file: "/tmp/#{app_name}-uwsgi-master.pid"
            })
end

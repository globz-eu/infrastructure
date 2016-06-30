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
# Cookbook:: standalone_app_server
# Recipe:: start_app

include_recipe 'chef-vault'

node_nr = node['standalone_app_server']['node_number']

app_user_vault = chef_vault_item('app_user', "app_user#{node_nr}")
app_user = app_user_vault['user']
app_repo = node['standalone_app_server']['git']['app_repo']
/https:\/\/github.com\/[\w\-]+\/(?<name>\w+)\.git/ =~ app_repo
unless name == nil
  app_name = name
end

directory "/var/log/#{app_name}/test_results" do
  owner 'root'
  group 'root'
  mode '0700'
end

bash 'test_and_start_app' do
  cwd "/home/#{app_user}/sites/#{app_name}/scripts"
  code './djangoapp.py -mt -u start'
  user 'root'
end

file "/etc/nginx/sites-enabled/#{app_name}_down.conf" do
  action :delete
end

link "/etc/nginx/sites-enabled/#{app_name}.conf" do
  owner 'root'
  group 'root'
  to "/etc/nginx/sites-available/#{app_name}.conf"
  notifies :restart, 'service[nginx]', :immediately
end

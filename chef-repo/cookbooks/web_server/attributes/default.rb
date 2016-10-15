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
# Cookbook Name:: web_server

default['web_server']['node_number'] = '000'
node_nr = node['web_server']['node_number']

default['web_server']['node_number'] = node_nr
default['web_server']['git']['app_repo'] = false
app_repo = node['web_server']['git']['app_repo']
default['web_server']['nginx']['git']['scripts_repo'] = 'https://github.com/globz-eu/scripts.git'
default['web_server']['nginx']['server_name'] = false
default['web_server']['nginx']['app_home'] = false
default['web_server']['nginx']['https'] = false
ssl = node['web_server']['nginx']['https']

default['basic_node']['node_number'] = node_nr

if ssl
  default['basic_node']['firewall']['web_server'] = ['http', 'https']
else
  default['basic_node']['firewall']['web_server'] = ['http']
end

if app_repo
  default['install_scripts']['git']['app_repo'] = app_repo
else
  default['install_scripts']['git']['app_repo'] = false
end

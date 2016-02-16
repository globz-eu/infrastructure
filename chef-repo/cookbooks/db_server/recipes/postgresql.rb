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
# Recipe:: postgresql

include_recipe 'chef-vault'

template '/etc/apt/sources.list.d/postgresql.list' do
  source 'postgresql.list.erb'
  action :create
  owner 'root'
  mode '0644'
  variables({
                source: 'deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main 9.5',
            })
end

execute 'add apt-key' do
  command 'wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -'
end

execute 'apt-get update' do
  command 'apt-get update'
end

package ['postgresql-9.5', 'postgresql-contrib-9.5', 'postgresql-client-9.5', 'postgresql-server-dev-9.5']

service 'postgresql' do
  action [:start, :enable]
end
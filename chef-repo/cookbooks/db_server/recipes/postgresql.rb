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
#
# Installs and configures a postgresql9.5 server, creates a database and
# a db user with default SELECT, INSERT, UPDATE, DELETE privileges

include_recipe 'chef-vault'

postgres_vault = chef_vault_item('pg_server', 'postgres')
db_user_vault = chef_vault_item('pg_server', 'db_user')
db_user = db_user_vault['user']
db_name = node['db_server']['postgresql']['db_name']
node.default['postgresql']['password']['postgres'] = postgres_vault['password']

include_recipe 'postgresql::default'
include_recipe 'postgresql::server'
include_recipe 'postgresql::contrib'
include_recipe 'database::postgresql'

postgresql_connection_info = {
    :host      => '127.0.0.1',
    :port      => 5432,
    :username  => postgres_vault['user'],
    :password  => postgres_vault['password']
}

if db_name
  postgresql_database db_name do
    connection postgresql_connection_info
    action :create
  end

  postgresql_database_user db_user do
    connection postgresql_connection_info
    password db_user_vault['password']
    action :create
    notifies :run, 'bash[grant_default_db]', :immediately
    notifies :run, 'bash[grant_default_seq]', :immediately
  end

  bash 'grant_default_db' do
    code "sudo -u #{postgres_vault['user']} psql -d #{db_name} -c 'ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO #{db_user};'"
    user 'root'
    action :nothing
  end

  bash 'grant_default_seq' do
    code "sudo -u #{postgres_vault['user']} psql -d #{db_name} -c 'ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, USAGE ON SEQUENCES TO #{db_user};'"
    user 'root'
    action :nothing
  end

end

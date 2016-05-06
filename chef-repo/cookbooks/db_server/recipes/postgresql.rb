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

if node['platform_version'].include?('14.04')
  include_recipe 'postgresql::server'
  include_recipe 'postgresql::contrib'
elsif node['platform_version'].include?('16.04')
  package [
              'postgresql',
              'postgresql-contrib-9.5',
              'postgresql-server-dev-9.5'
          ]

  service 'postgresql' do
    action :start
  end

  # TODO: check enable postgresql service

  bash 'set_postgres_password' do
    code "sudo -u #{postgres_vault['user']} psql -c \"ALTER USER #{postgres_vault['user']} WITH PASSWORD '#{postgres_vault['password']}';\""
    user 'root'
  end

  template('/etc/postgresql/9.5/main/pg_hba.conf') do
    owner 'postgres'
    group 'postgres'
    mode '0600'
    source 'pg_hba.conf.erb'
    variables({
                  postgres_local: 'ident',
                  all_local: 'md5',
                  all_IPv4: 'md5',
                  all_IPv6: 'md5',
              })
    notifies :restart, 'service[postgresql]', :immediately
  end
end

# TODO: make script, make idempotent
if db_name
  bash 'create_database' do
    code "sudo -u #{postgres_vault['user']} psql -c 'CREATE DATABASE #{db_name};'"
    user 'root'
  end

  bash 'create_user' do
    code "sudo -u #{postgres_vault['user']} psql -c \"CREATE USER #{db_user} WITH PASSWORD '#{db_user_vault['password']}';\""
    user 'root'
  end

  bash 'grant_default_db' do
    code "sudo -u #{postgres_vault['user']} psql -d #{db_name} -c 'ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO #{db_user};'"
    user 'root'
  end

  bash 'grant_default_seq' do
    code "sudo -u #{postgres_vault['user']} psql -d #{db_name} -c 'ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, USAGE ON SEQUENCES TO #{db_user};'"
    user 'root'
  end
end

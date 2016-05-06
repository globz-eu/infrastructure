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
# Cookbook Name:: standalone_app_server
# Recipe:: reinstall_app

# TODO: replace recipe by script

include_recipe 'chef-vault'

postgres_vault = chef_vault_item('pg_server', 'postgres')
db_user_vault = chef_vault_item('pg_server', 'db_user')
db_user = db_user_vault['user']
db_name = node['db_server']['postgresql']['db_name']
node.default['postgresql']['password']['postgres'] = postgres_vault['password']
app_user_item = chef_vault_item('app_user', 'app_user')
app_user = app_user_item['user']
app_name = node['django_app_server']['django_app']['app_name']

include_recipe 'postgresql::default'
include_recipe 'postgresql::server'
include_recipe 'postgresql::contrib'
include_recipe 'database::postgresql'

postgresql_db_connection_info = {
    :db_name   => db_name,
    :host      => '127.0.0.1',
    :port      => 5432,
    :username  => postgres_vault['user'],
    :password  => postgres_vault['password']
}

# stop nginx
bash 'nginx_stop' do
  code 'service nginx stop'
  user 'root'
  action :nothing
end

# stop uwsgi
bash 'stop_uwsgi' do
  code 'echo q > /tmp/fifo0'
  user 'root'
  notifies :run, 'bash[nginx_stop]', :immediately
end

# re-create database
bash 'drop_database' do
  code "sudo -u postgres psql -c 'DROP DATABASE #{app_name};'"
  user 'root'
end

bash 'create_database' do
  code "sudo -u postgres psql -c 'CREATE DATABASE #{app_name};'"
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

# uninstall app
directory "/home/#{app_user}/sites/#{app_name}/tmp" do
  owner app_user
  group app_user
  mode '0750'
end

bash 'backup_configuration' do
  cwd "/home/#{app_user}/sites/#{app_name}/source/#{app_name}"
  code 'cp ./configuration.py ../../tmp/'
  user 'root'
end

bash 'backup_settings_admin' do
  cwd "/home/#{app_user}/sites/#{app_name}/source/#{app_name}"
  code "cp ./#{app_name}/settings_admin.py ../../tmp/"
  user 'root'
end

bash 'backup_install_dependencies' do
  cwd "/home/#{app_user}/sites/#{app_name}/source"
  code 'cp ./install_dependencies.py ../tmp/'
  user 'root'
end

bash 'backup_uwsgi_ini' do
  cwd "/home/#{app_user}/sites/#{app_name}/source"
  code "cp ./#{app_name}_uwsgi.ini ../tmp/"
  user 'root'
end

bash 'remove_app' do
  cwd "/home/#{app_user}/sites/#{app_name}/source"
  code 'rm -Rf ./*'
  user 'root'
end

bash 'remove_static' do
  cwd "/home/#{app_user}/sites/#{app_name}/static"
  code 'rm -Rf ./*'
  user 'root'
end

bash 'remove_media' do
  cwd "/home/#{app_user}/sites/#{app_name}/media"
  code 'rm -Rf ./*'
  user 'root'
end

# re-install app
bash 'git_clone_app' do
  cwd "/home/#{app_user}/sites/#{app_name}/source"
  code "git clone #{node['django_app_server']['git']['git_repo']}"
  user 'root'
end

execute "chown -R #{app_user}:#{app_user} /home/#{app_user}/sites/#{app_name}/source"

execute "find /home/#{app_user}/sites/#{app_name}/source -type f -exec chmod 0400 {} +"

execute "find /home/#{app_user}/sites/#{app_name}/source -type d -exec chmod 0500 {} +"

bash 'reset_configuration' do
  cwd "/home/#{app_user}/sites/#{app_name}/source/#{app_name}"
  code 'cp ../../tmp/configuration.py ./'
  user 'root'
end

bash 'reset_settings_admin' do
  cwd "/home/#{app_user}/sites/#{app_name}/source/#{app_name}"
  code "cp ../../tmp/settings_admin.py ./#{app_name}/"
  user 'root'
end

bash 'reset_install_dependencies' do
  cwd "/home/#{app_user}/sites/#{app_name}/source"
  code 'cp ../tmp/install_dependencies.py ./'
  user 'root'
end

bash 'reset_uwsgi_ini' do
  cwd "/home/#{app_user}/sites/#{app_name}/source"
  code "cp ../tmp/#{app_name}_uwsgi.ini ./"
  user 'root'
end

bash 're-migrate' do
  cwd "/home/#{app_user}/sites/#{app_name}/source/#{app_name}"
  code "/home/#{app_user}/.envs/#{app_name}/bin/python ./manage.py migrate --settings #{app_name}.settings_admin"
  user 'root'
end

bash 're-test_app' do
  cwd "/home/#{app_user}/sites/#{app_name}/source/#{app_name}"
  code "/home/#{app_user}/.envs/#{app_name}/bin/python ./manage.py test --settings #{app_name}.settings_admin &> /var/log/#{app_name}/test_results/test_$(date +\"%d-%m-%y-%H%M%S\").log"
  user 'root'
end

# restart uwsgi
bash 're-start_uwsgi' do
  cwd "/home/#{app_user}/sites/#{app_name}/source"
  code 'uwsgi --ini ./django_base_uwsgi.ini '
  user 'root'
end

# restart nginx
bash 're-start_nginx' do
  code 'service nginx start'
  user 'root'
end

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
db_admin_user = postgres_vault['user']
node.default['postgresql']['password']['postgres'] = postgres_vault['password']
app_repo = node['db_server']['postgresql']['git']['app_repo']
scripts_repo = node['db_server']['postgresql']['git']['scripts_repo']
app_name = false
db_name = false
if app_repo
  /https:\/\/github.com\/[\w\-]+\/(?<name>\w+)\.git/ =~ app_repo
  if name
    app_name = name
    db_name = name
  end
end

if node['platform_version'].include?('14.04')
  include_recipe 'postgresql::server'
  include_recipe 'postgresql::contrib'
elsif node['platform_version'].include?('16.04')
  package %w(postgresql postgresql-contrib-9.5 postgresql-server-dev-9.5)

  service 'postgresql' do
    action :start
  end

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

if db_name
  bash 'create_user' do
    code "sudo -u #{postgres_vault['user']} psql -c \"CREATE USER #{db_user} WITH PASSWORD '#{db_user_vault['password']}';\""
    user 'root'
    not_if "sudo -u #{postgres_vault['user']} psql -c '\\du' | grep #{db_user}", :user => 'root'
  end

  package 'git'

  directory '/var/log/django_base' do
    owner 'root'
    group 'root'
    mode '0755'
  end

  directory "/home/#{db_user}/sites" do
    owner db_user
    group db_user
    mode '0500'
  end

  directory "/home/#{db_user}/sites/#{app_name}" do
    owner db_user
    group db_user
    mode '0500'
  end

  bash 'git_clone_db_scripts' do
    cwd "/home/#{db_user}/sites/#{app_name}"
    code "git clone #{scripts_repo}"
    user 'root'
    not_if "ls /home/#{db_user}/sites/#{app_name}/scripts", :user => 'root'
    notifies :run, 'bash[own_db_scripts]', :immediately
    notifies :run, 'bash[db_scripts_dir_permissions]', :immediately
    notifies :run, 'bash[make_db_scripts_executable]', :immediately
    notifies :run, 'bash[make_db_scripts_utilities_readable]', :immediately
  end

  package 'python3-pip'

  bash 'install_db_scripts_requirements' do
    cwd "/home/#{db_user}/sites/#{app_name}/scripts"
    code 'pip3 install -r requirements.txt'
    user 'root'
  end

  bash 'own_db_scripts' do
    code "chown -R #{db_user}:#{db_user} /home/#{db_user}/sites/#{app_name}/scripts"
    user 'root'
    action :nothing
  end

  bash 'db_scripts_dir_permissions' do
    code "chmod 0500 /home/#{db_user}/sites/#{app_name}/scripts"
    user 'root'
    action :nothing
  end

  bash 'make_db_scripts_executable' do
    code "chmod 0500 /home/#{db_user}/sites/#{app_name}/scripts/*.py"
    user 'root'
    action :nothing
  end

  bash 'make_db_scripts_utilities_readable' do
    code "chmod 0400 /home/#{db_user}/sites/#{app_name}/scripts/utilities/*.py"
    user 'root'
    action :nothing
  end

  template "/home/#{db_user}/sites/#{app_name}/scripts/conf.py" do
    owner db_user
    group db_user
    mode '0400'
    source 'conf.py.erb'
    variables({
        dist_version: node['platform_version'],
        debug: 'DEBUG',
        nginx_conf: '',
        git_repo: app_repo,
        app_home: '',
        app_home_tmp: '',
        app_user: '',
        web_user: '',
        webserver_user: '',
        db_user: db_user,
        db_admin_user: db_admin_user,
        static_path: '',
        media_path: '',
        uwsgi_path: '',
        down_path: '',
        log_file: "/var/log/#{app_name}/create_db.log"
              })
  end

  bash 'run_create_database' do
    cwd "/home/#{db_user}/sites/#{app_name}/scripts"
    code './dbserver.py -c'
    user 'root'
  end
end

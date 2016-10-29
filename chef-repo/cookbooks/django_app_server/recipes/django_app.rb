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
# Recipe:: django_app
#
# Manages django app configuration, creates venv file structure, creates
# venv, installs apt package python3-numpy and python package numpy
# (need to be installed before biopython), changes ownership of venv to
# app_user, manages app dependencies, package
# requirements, static and media content

include_recipe 'chef-vault'

node_number = node['django_app_server']['node_number']
app_user_vault = chef_vault_item('app_user', "app_user#{node['django_app_server']['node_number']}")
app_user = app_user_vault['user']
init_user_vault = chef_vault_item('django_app', "init_users#{node['django_app_server']['node_number']}")
django_app_vault = chef_vault_item('django_app', "app#{node['django_app_server']['node_number']}")
db_user_vault = chef_vault_item('pg_server', "db_user#{node['django_app_server']['node_number']}")
pg_user_vault = chef_vault_item('pg_server', "postgres#{node['django_app_server']['node_number']}")
node_ip_item = chef_vault_item('basic_node', "node_ips#{node_number}")
if node['django_app_server']['django_app']['allowed_host']
  allowed_host = node['django_app_server']['django_app']['allowed_host']
else
  allowed_host = node_ip_item['public_ip']
end

if node['django_app_server']['django_app']['db_user'] == 'db_user'
  db_user = db_user_vault['user']
  db_password = db_user_vault['password']
elsif node['django_app_server']['django_app']['db_user'] == 'postgres'
  db_user = pg_user_vault['user']
  db_password = pg_user_vault['password']
else
  db_user = pg_user_vault['user']
  db_password = pg_user_vault['password']
end

app_repo = node['django_app_server']['git']['app_repo']
celery = node['django_app_server']['django_app']['celery']

# install git
package 'git'

# create venv file structure
directory "/home/#{app_user}/.envs" do
  owner app_user
  group app_user
  mode '0500'
end

# when git repo is specified clone from git repo
if app_repo
  /https:\/\/github.com\/[\w\-]+\/(?<name>\w+)\.git/ =~ app_repo
  unless name == nil
    app_name = name.downcase
  end

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

  directory "/home/#{app_user}/sites/#{app_name}/source" do
    owner app_user
    group app_user
    mode '0500'
  end

  # create app fifo directory
  directory "/tmp/#{app_name}" do
    owner 'root'
    group 'root'
    mode '0777'
  end

  # create conf.d directory
  directory "/home/#{app_user}/sites/#{app_name}/conf.d" do
    owner app_user
    group 'www-data'
    mode '0750'
  end

  # create sockets directory
  directory "/home/#{app_user}/sites/#{app_name}/sockets" do
    owner app_user
    group 'www-data'
    mode '0750'
  end

  # TODO: adapt to settings.json
  # create host-specific configuration file for django app
  template "/home/#{app_user}/sites/#{app_name}/conf.d/settings.json" do
    source 'settings.json.erb'
    action :create
    owner app_user
    group app_user
    mode '0400'
    variables({
                  secret_key: django_app_vault['secret_key'],
                  allowed_hosts: allowed_host,
                  db_engine: node['django_app_server']['django_app']['engine'],
                  db_name: app_name,
                  db_user: db_user,
                  db_password: db_password,
                  db_admin_user: pg_user_vault['user'],
                  db_admin_password: pg_user_vault['password'],
                  db_host: node['django_app_server']['django_app']['db_host'],
                  test_db_name: "test_#{app_name}",
                  broker_url: 'redis://localhost:6379/0',
                  celery_result_backend: 'redis://localhost:6379/0',
                  server_url: 'liveserver',
                  init_users: init_user_vault['users'],
                  init_superuser: init_user_vault['superuser'],
              })
  end

  # create install_django_app configuration file
  template "/home/#{app_user}/sites/#{app_name}/scripts/conf.py" do
    source 'conf.py.erb'
    action :create
    owner app_user
    group app_user
    mode '0400'
    variables({
        dist_version: node['platform_version'],
        log_level: "'DEBUG'",
        nginx_conf: '',
        git_repo: app_repo,
        celery_pid: "/var/run/#{app_name}/celery",
        app_home: "/home/#{app_user}/sites/#{app_name}/source",
        app_user: app_user,
        venv: "/home/#{app_user}/.envs/#{app_name}",
        reqs_file: "/home/#{app_user}/sites/#{app_name}/source/#{app_name}/requirements.txt",
        sys_deps_file: "/home/#{app_user}/sites/#{app_name}/source/#{app_name}/system_dependencies.txt",
        log_file: "/var/log/#{app_name}/install.log",
        fifo_dir: "/tmp/#{app_name}"
              })
  end

  # make the uwsgi.ini file
  template "/home/#{app_user}/sites/#{app_name}/conf.d/#{app_name}_uwsgi.ini" do
    owner app_user
    group app_user
    mode '0400'
    source 'app_name_uwsgi.ini.erb'
    variables({
                  app_name: app_name,
                  module: app_name,
                  app_user: app_user,
                  fifo: "/tmp/#{app_name}/fifo0",
                  web_user: 'www-data',
                  processes: node['django_app_server']['uwsgi']['processes'],
                  socket: socket,
                  chmod_socket: chmod_socket,
                  log_file: "/var/log/uwsgi/#{app_name}.log",
                  pid_file: "/tmp/#{app_name}-uwsgi-master.pid"
              })
  end

  # create the celery file structure
  if celery
    %W(
    /var/log/#{app_name}/celery
    /var/run/#{app_name}
    /var/run/#{app_name}/celery
    ).each do |f|
      directory f do
        owner 'root'
        group 'root'
        mode '0700'
      end
    end
  end

  bash 'install_django_app' do
    cwd "/home/#{app_user}/sites/#{app_name}/scripts"
    code './djangoapp.py -i'
    user 'root'
  end
end

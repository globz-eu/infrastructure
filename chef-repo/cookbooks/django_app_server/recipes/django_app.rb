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

app_user_vault = chef_vault_item('app_user', 'app_user')
app_user = app_user_vault['user']
django_app_vault = chef_vault_item('django_app', 'app')
app_name = node['django_app_server']['django_app']['app_name']
git_repo = node['django_app_server']['git']['git_repo']

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

# install git
package 'git'

# make sites directory
directory "/home/#{app_user}/sites" do
  owner app_user
  group 'www-data'
  mode '0550'
end

# create app directory structure
directory "/home/#{app_user}/sites/#{app_name}" do
  owner app_user
  group 'www-data'
  mode '0550'
end

directory "/home/#{app_user}/sites/#{app_name}/source" do
  owner app_user
  group app_user
  mode '0500'
end

# create venv file structure
directory "/home/#{app_user}/.envs" do
  owner app_user
  group app_user
  mode '0500'
end

# create app log directory
directory "/var/log/#{app_name}" do
  owner 'root'
  group 'root'
  mode '0755'
end

# create static content directory
directory "/home/#{app_user}/sites/#{app_name}/static" do
  owner app_user
  group 'www-data'
  mode '0750'
end

# create media directory
directory "/home/#{app_user}/sites/#{app_name}/media" do
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

# when git repo is specified clone from git repo
if git_repo
  bash 'git_clone_scripts' do
    cwd "/home/#{app_user}/sites/#{app_name}"
    code "git clone #{git_repo}/scripts.git"
    user 'root'
    not_if "ls /home/#{app_user}/sites/#{app_name}/scripts", :user => 'root'
  end

  # TODO: only execute when git_clone_scripts is executed
  execute "chown -R #{app_user}:#{app_user} /home/#{app_user}/sites/#{app_name}/scripts"

  execute "chmod 0500 /home/#{app_user}/sites/#{app_name}/scripts"

  execute "chmod +x /home/#{app_user}/sites/#{app_name}/scripts/*.py"

  template "/home/#{app_user}/sites/#{app_name}/scripts/install_django_app_conf.py" do
    source 'install_django_app_conf.py.erb'
    action :create
    owner app_user
    group app_user
    mode '0400'
    variables({
        debug: 'False',
        git_repo: "#{git_repo}/#{app_name}.git",
        app_folder: "/home/#{app_user}/sites/#{app_name}/source",
        venv: "/home/#{app_user}/.envs/#{app_name}",
        reqs_file: "/home/#{app_user}/sites/#{app_name}/source/#{app_name}/requirements.txt",
        sys_deps_file: "/home/#{app_user}/sites/#{app_name}/source/#{app_name}/system_dependencies.txt",
        log_file: "/var/log/#{app_name}/install.log"
              })
  end

  if node['platform_version'].include?('14.04')
    bash 'install_django_app' do
      cwd "/home/#{app_user}/sites/#{app_name}/scripts"
      code './install_django_app_trusty.py'
      user 'root'
    end
  end

  if node['platform_version'].include?('16.04')
    bash 'install_django_app' do
      cwd "/home/#{app_user}/sites/#{app_name}/scripts"
      code './install_django_app_xenial.py'
      user 'root'
    end
  end

  # TODO: move to script
  execute "chown -R #{app_user}:#{app_user} /home/#{app_user}/sites/#{app_name}/source"

  execute "find /home/#{app_user}/sites/#{app_name}/source -type f -exec chmod 0400 {} +"

  execute "find /home/#{app_user}/sites/#{app_name}/source -type d -exec chmod 0500 {} +"

  # change ownership of venv back to app_user
  execute "chown -R #{app_user}:#{app_user} /home/app_user/.envs/#{app_name}"

  # create host-specific configuration file for django app
  template "/home/#{app_user}/sites/#{app_name}/source/#{app_name}/configuration.py" do
    source 'configuration.py.erb'
    action :create
    owner app_user
    group app_user
    mode '0400'
    variables({
                  secret_key: django_app_vault['secret_key'],
                  debug: node['django_app_server']['django_app']['debug'],
                  allowed_host: node['django_app_server']['django_app']['allowed_host'],
                  engine: node['django_app_server']['django_app']['engine'],
                  app_name: app_name,
                  db_user: django_app_vault['db_user'],
                  db_user_password: django_app_vault['db_user_password'],
                  db_host: node['django_app_server']['django_app']['db_host']
              })
  end

  # create django settings file for administrative tasks (manage.py)
  template "/home/#{app_user}/sites/#{app_name}/source/#{app_name}/#{app_name}/settings_admin.py" do
    source 'settings_admin.py.erb'
    action :create
    owner app_user
    group app_user
    mode '0400'
    variables({
                  app_name: app_name,
                  db_admin_user: django_app_vault['db_admin_user'],
                  db_admin_password: django_app_vault['db_admin_password'],
              })
  end
end

# make the uwsgi.ini file
if app_name
  template "/home/#{app_user}/sites/#{app_name}/source/#{app_name}_uwsgi.ini" do
    owner app_user
    group app_user
    mode '0400'
    source 'app_name_uwsgi.ini.erb'
    variables({
                  app_name: node['django_app_server']['django_app']['app_name'],
                  app_user: app_user,
                  web_user: 'www-data',
                  processes: node['django_app_server']['uwsgi']['processes'],
                  socket: socket,
                  chmod_socket: chmod_socket,
                  log_file: "/var/log/uwsgi/#{app_name}.log",
                  pid_file: "/tmp/#{app_name}-uwsgi-master.pid"
              })
  end
end

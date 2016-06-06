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
# Recipe:: nginx

include_recipe 'chef-vault'
include_recipe 'basic_node::firewall'

web_user_vault = chef_vault_item('web_user', 'web_user')
web_user = web_user_vault['user']
app_user_vault = chef_vault_item('app_user', 'app_user')
app_user = app_user_vault['user']
app_name = node['web_server']['nginx']['app_name']
if node['web_server']['nginx']['app_home']
  app_home = node['web_server']['nginx']['app_home']
else
  app_home = ''
end
server_name = node['web_server']['nginx']['server_name']
app_repo = node['web_server']['nginx']['git']['app_repo']
scripts_repo = node['web_server']['nginx']['git']['scripts_repo']

package 'nginx'

service 'nginx' do
  action :nothing
end

package 'git'

# create site file structure
directory "/home/#{web_user}/sites" do
  owner web_user
  group 'www-data'
  mode '0750'
end

if app_repo
  /https:\/\/github.com\/[\w\-]+\/(?<name>\w+)\.git/ =~ app_repo
  if name
    app_name = name
  end

  static_path = "/home/#{web_user}/sites/#{app_name}/static"
  media_path = "/home/#{web_user}/sites/#{app_name}/media"
  uwsgi_path = "/home/#{web_user}/sites/#{app_name}/uwsgi"
  down_path = "/home/#{web_user}/sites/#{app_name}/down"
  paths = [static_path, media_path, uwsgi_path, down_path]

  directory "/home/#{web_user}/sites/#{app_name}" do
    owner web_user
    group 'www-data'
    mode '0550'
  end

  directory "/var/log/#{app_name}" do
    owner 'root'
    group 'root'
    mode '0755'
  end

  paths.each do |p|
    directory p do
      owner web_user
      group 'www-data'
      mode '0550'
    end
  end

  bash 'git_clone_static_scripts' do
    cwd "/home/#{web_user}/sites/#{app_name}"
    code "git clone #{scripts_repo}"
    user 'root'
    not_if "ls /home/#{web_user}/sites/#{app_name}/scripts", :user => 'root'
    notifies :run, 'bash[own_static_scripts]', :immediately
    notifies :run, 'bash[static_scripts_dir_permissions]', :immediately
    notifies :run, 'bash[make_static_scripts_executable]', :immediately
    notifies :run, 'bash[make_static_scripts_utilities_readable]', :immediately
  end

  # TODO: remove unused files from scripts folder

  bash 'own_static_scripts' do
    code "chown -R #{web_user}:#{web_user} /home/#{web_user}/sites/#{app_name}/scripts"
    user 'root'
    action :nothing
  end

  bash 'static_scripts_dir_permissions' do
    code "chmod 0500 /home/#{web_user}/sites/#{app_name}/scripts"
    user 'root'
    action :nothing
  end

  bash 'make_static_scripts_executable' do
    code "chmod 0500 /home/#{web_user}/sites/#{app_name}/scripts/*.py"
    user 'root'
    action :nothing
  end

  bash 'make_static_scripts_utilities_readable' do
    code "chmod 0400 /home/#{web_user}/sites/#{app_name}/scripts/utilities/*.py"
    user 'root'
    action :nothing
  end

  template "/home/#{web_user}/sites/#{app_name}/scripts/conf.py" do
    owner web_user
    group web_user
    mode '0400'
    source 'conf.py.erb'
    variables({
                  dist_version: node['platform_version'],
                  debug: 'DEBUG',
                  git_repo: app_repo,
                  app_home: app_home,
                  app_home_tmp: "/home/#{web_user}/sites/#{app_name}/source",
                  app_user: '',
                  web_user: web_user,
                  webserver_user: 'www-data',
                  static_path: static_path,
                  media_path: media_path,
                  uwsgi_path: uwsgi_path,
                  log_file: "/var/log/#{app_name}/serve_static.log"
              })
  end

  bash 'serve_static' do
    cwd "/home/#{web_user}/sites/#{app_name}/scripts"
    code './servestatic.py'
    user 'root'
  end

  # TODO: adapt to tcp sockets option
  template "/etc/nginx/sites-available/#{app_name}.conf" do
    owner 'root'
    group 'root'
    mode '0400'
    source 'app_name.conf.erb'
    variables({
        app_name: app_name,
        server_unix_socket: "server unix:///home/#{app_user}/sites/#{app_name}/sockets/#{app_name}.sock;",
        server_tcp_socket: '# server 127.0.0.1:8001;',
        listen_port: '80',
        server_name: server_name,
        web_user: web_user,
        static_path: static_path,
        media_path: media_path,
        uwsgi_path: uwsgi_path
              })
  end

  template "#{down_path}/index.html" do
    owner web_user
    group 'www-data'
    mode '0440'
    source 'index_down.html.erb'
    variables({
        app_name: app_name
              })
  end

  template "/etc/nginx/sites-available/#{app_name}_down.conf" do
    owner 'root'
    group 'root'
    mode '0400'
    source 'app_name_down.conf.erb'
    variables({
                  app_name: app_name,
                  listen_port: '80',
                  server_name: server_name,
                  down_path: down_path
              })
  end

  file '/etc/nginx/sites-enabled/default' do
    action :delete
  end

  link "/etc/nginx/sites-enabled/#{app_name}_down.conf" do
    owner 'root'
    group 'root'
    to "/etc/nginx/sites-available/#{app_name}_down.conf"
    notifies :restart, 'service[nginx]', :immediately
  end
end

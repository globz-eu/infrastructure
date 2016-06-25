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

node_nr = node['web_server']['node_number']
web_user_vault = chef_vault_item('web_user', "web_user#{node_nr}")
web_user = web_user_vault['user']
app_user_vault = chef_vault_item('app_user', "app_user#{node_nr}")
app_user = app_user_vault['user']
app_name = node['web_server']['nginx']['app_name']
if node['web_server']['nginx']['app_home']
  app_home = node['web_server']['nginx']['app_home']
else
  app_home = ''
end
server_name = node['web_server']['nginx']['server_name']
app_repo = node['web_server']['nginx']['git']['app_repo']

package 'nginx'

service 'nginx' do
  action :nothing
end

package 'git'

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

  paths.each do |p|
    directory p do
      owner web_user
      group 'www-data'
      mode '0550'
    end
  end

  template "/home/#{web_user}/sites/#{app_name}/scripts/conf.py" do
    owner web_user
    group web_user
    mode '0400'
    source 'conf.py.erb'
    variables({
                  dist_version: node['platform_version'],
                  debug: 'DEBUG',
                  nginx_conf: '',
                  git_repo: app_repo,
                  app_home: app_home,
                  app_home_tmp: "/home/#{web_user}/sites/#{app_name}/source",
                  app_user: '',
                  web_user: web_user,
                  webserver_user: 'www-data',
                  static_path: static_path,
                  media_path: media_path,
                  uwsgi_path: uwsgi_path,
                  down_path: down_path,
                  log_file: "/var/log/#{app_name}/serve_static.log"
              })
  end

  bash 'serve_static' do
    cwd "/home/#{web_user}/sites/#{app_name}/scripts"
    code './webserver.py -m'
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
    not_if "ls #{down_path}/index.html"
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
                  down_path: down_path,
                  static_path: static_path,
                  media_path: media_path,
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

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
node_ip_item = chef_vault_item('basic_node', "node_ips#{node_nr}")
django_app_vault = chef_vault_item('django_app', "app#{node['django_app_server']['node_number']}")
if node['web_server']['nginx']['app_home']
  app_home = node['web_server']['nginx']['app_home']
else
  app_home = ''
end
if node['web_server']['nginx']['server_name']
  server_name = node['web_server']['nginx']['server_name']
else
  server_name = node_ip_item['public_ip']
end

app_repo = node['web_server']['git']['app_repo']
ssl = node['web_server']['nginx']['https']

package 'nginx'

service 'nginx' do
  action :nothing
end

package 'git'

if app_repo
  /https:\/\/github.com\/[\w\-]+\/(?<name>\w+)\.git/ =~ app_repo
  if name
    app_name = name.downcase
  end

  static_path = "/home/#{web_user}/sites/#{app_name}/static"
  media_path = "/home/#{web_user}/sites/#{app_name}/media"
  uwsgi_path = "/home/#{web_user}/sites/#{app_name}/uwsgi"
  down_path = "/home/#{web_user}/sites/#{app_name}/down"
  paths = [static_path, media_path, uwsgi_path, down_path]

  # create venv file structure
  directory "/home/#{web_user}/.envs" do
    owner web_user
    group web_user
    mode '0500'
  end

  # install python runtime
  include_recipe 'django_app_server::python'

  # create static directories
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
                  log_level: 'DEBUG',
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
                  venv: "/home/#{web_user}/.envs/#{app_name}",
                  log_file: "/var/log/#{app_name}/serve_static.log",
                  fifo_dir: ''
              })
  end

  # create conf.d directory
  directory "/home/#{web_user}/sites/#{app_name}/conf.d" do
    owner web_user
    group web_user
    mode '0750'
  end

  # create host-specific configuration file for django app
  template "/home/#{web_user}/sites/#{app_name}/conf.d/settings.json" do
    source 'settings.json.erb'
    action :create
    owner web_user
    group web_user
    mode '0400'
    variables({
                  secret_key: django_app_vault['secret_key'],
                  allowed_host: '',
                  db_engine: '',
                  db_name: '',
                  db_user: '',
                  db_password: '',
                  db_admin_user: '',
                  db_admin_password: '',
                  db_host: '',
                  test_db_name: '',
                  broker_url: '',
                  celery_result_backend: ''
              })
  end

  bash 'serve_static' do
    cwd "/home/#{web_user}/sites/#{app_name}/scripts"
    code './webserver.py -m'
    user 'root'
  end

  # TODO: adapt to tcp sockets option
  if ssl
    template "/etc/nginx/sites-available/#{app_name}.conf" do
      owner 'root'
      group 'root'
      mode '0400'
      source 'app_name_https.conf.erb'
      variables({
                    app_name: app_name,
                    server_unix_socket: "server unix:///home/#{app_user}/sites/#{app_name}/sockets/#{app_name}.sock;",
                    server_tcp_socket: '# server 127.0.0.1:8001;',
                    listen_port: '443',
                    server_name: server_name,
                    static_path: static_path,
                    media_path: media_path,
                    uwsgi_path: uwsgi_path
                })
    end

    template "/etc/nginx/sites-available/#{app_name}_down.conf" do
      owner 'root'
      group 'root'
      mode '0400'
      source 'app_name_down_https.conf.erb'
      variables({
                    app_name: app_name,
                    listen_port: '443',
                    server_name: server_name,
                    down_path: down_path,
                    static_path: static_path,
                    media_path: media_path,
                })
    end

    directory '/etc/nginx/ssl' do
      owner 'root'
      group 'www-data'
      mode '0550'
    end

    cert = chef_vault_item('web_user', "certificate#{node_nr}")['certificate']
    key = chef_vault_item('web_user', "certificate#{node_nr}")['key']

    template '/etc/nginx/ssl/server.crt' do
      owner 'root'
      group 'www-data'
      mode '0640'
      source 'server.crt.erb'
      variables({
          server_crt: cert
                })
    end

    template '/etc/nginx/ssl/server.key' do
      owner 'root'
      group 'www-data'
      mode '0640'
      source 'server.key.erb'
      variables({
                    server_key: key
                })
    end
  else
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
                    static_path: static_path,
                    media_path: media_path,
                    uwsgi_path: uwsgi_path
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
                    down_path: down_path,
                    static_path: static_path,
                    media_path: media_path,
                })
    end
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

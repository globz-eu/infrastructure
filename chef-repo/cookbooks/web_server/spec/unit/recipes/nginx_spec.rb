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
# Spec:: nginx

require 'spec_helper'

describe 'web_server::nginx' do
  ['14.04', '16.04'].each do |version|
    context "When git repo is specified, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version) do |node|
          node.set['web_server']['nginx']['git']['app_repo'] = 'https://github.com/globz-eu/django_base.git'
          if version == '14.04'
            node.set['web_server']['node_number'] = '000'
          elsif version == '16.04'
            node.set['web_server']['node_number'] = '001'
          end
        end.converge(described_recipe)
      end

      before do
        stub_command('ls /home/web_user/sites/django_base/down/index.html').and_return(true)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'includes chef-vault and firewall recipes' do
        recipes = %w(chef-vault basic_node::firewall)
        recipes.each do |r|
          expect(chef_run).to include_recipe(r)
        end
      end

      it 'installs the nginx package' do
        expect(chef_run).to install_package( 'nginx' )
      end

      it 'does not start nginx service until notified' do
        expect(chef_run).to_not start_service( 'nginx' )
      end

      it 'creates firewall rules' do
        expect(chef_run).to create_firewall_rule('http')
      end

      it 'creates or updates django_base.conf file' do
        params = [
            /^# django_base.conf$/,
            %r(^\s+server unix:///home/app_user/sites/django_base/sockets/django_base\.sock; # for a file socket$),
            /^\s+# server 127\.0\.0\.1:8001; # for a web port socket/,
            /^\s+listen\s+80;$/,
            /^\s+server_name\s+192\.168\.1\.81;$/,
            %r(^\s+alias /home/web_user/sites/django_base/media;),
            %r(^\s+alias /home/web_user/sites/django_base/static;),
            %r(^\s+include\s+/home/web_user/sites/django_base/uwsgi/uwsgi_params;$)
        ]
        expect(chef_run).to create_template('/etc/nginx/sites-available/django_base.conf').with({
            owner: 'root',
            group: 'root',
            mode: '0400',
            source: 'app_name.conf.erb',
            variables: {
                app_name: 'django_base',
                server_unix_socket: 'server unix:///home/app_user/sites/django_base/sockets/django_base.sock;',
                server_tcp_socket: '# server 127.0.0.1:8001;',
                listen_port: '80',
                server_name: '192.168.1.81',
                web_user: 'web_user',
                static_path: '/home/web_user/sites/django_base/static',
                media_path: '/home/web_user/sites/django_base/media',
                uwsgi_path: '/home/web_user/sites/django_base/uwsgi'
            }
        })
        params.each do |p|
          expect(chef_run).to render_file('/etc/nginx/sites-available/django_base.conf').with_content(p)
        end
      end

      it 'installs the git package' do
        expect( chef_run ).to install_package('git')
      end

      it 'creates the site file structure' do
        sites_paths = ['static', 'media', 'uwsgi', 'down']
        sites_paths.each do |s|
          expect(chef_run).to create_directory("/home/web_user/sites/django_base/#{s}").with(
              owner: 'web_user',
              group: 'www-data',
              mode: '0550',
          )
        end
      end

      it 'creates the /home/web_user/sites/django_base/scripts/conf.py file' do
        expect(chef_run).to create_template('/home/web_user/sites/django_base/scripts/conf.py').with(
            owner: 'web_user',
            group: 'web_user',
            mode: '0400',
            source: 'conf.py.erb',
            variables: {
                dist_version: version,
                debug: 'DEBUG',
                nginx_conf: '',
                git_repo: 'https://github.com/globz-eu/django_base.git',
                app_home: '',
                app_home_tmp: '/home/web_user/sites/django_base/source',
                app_user: '',
                web_user: 'web_user',
                webserver_user: 'www-data',
                static_path: '/home/web_user/sites/django_base/static',
                media_path: '/home/web_user/sites/django_base/media',
                uwsgi_path: '/home/web_user/sites/django_base/uwsgi',
                down_path: '/home/web_user/sites/django_base/down',
                log_file: '/var/log/django_base/serve_static.log'
            }
        )
        install_app_conf = [
            %r(^DIST_VERSION = '#{version}'$),
            %r(^DEBUG = 'DEBUG'$),
            %r(^NGINX_CONF = ''$),
            %r(^APP_HOME_TMP = '/home/web_user/sites/django_base/source'$),
            %r(^APP_HOME = ''$),
            %r(^APP_USER = ''$),
            %r(^WEB_USER = 'web_user'$),
            %r(^WEBSERVER_USER = 'www-data'$),
            %r(^GIT_REPO = 'https://github\.com/globz-eu/django_base\.git'$),
            %r(^STATIC_PATH = '/home/web_user/sites/django_base/static'$),
            %r(^MEDIA_PATH = '/home/web_user/sites/django_base/media'$),
            %r(^UWSGI_PATH = '/home/web_user/sites/django_base/uwsgi'$),
            %r(^DOWN_PATH = '/home/web_user/sites/django_base/down'$),
            %r(^VENV = ''$),
            %r(^REQS_FILE = ''$),
            %r(^SYS_DEPS_FILE = ''$),
            %r(^LOG_FILE = '/var/log/django_base/serve_static\.log'$)
        ]
        install_app_conf.each do |u|
          expect(chef_run).to render_file(
                                  '/home/web_user/sites/django_base/scripts/conf.py'
                              ).with_content(u)
        end
      end

      it 'runs the serve_static script' do
        expect(chef_run).to run_bash('serve_static').with(
            cwd: '/home/web_user/sites/django_base/scripts',
            code: './webserver.py -m',
            user: 'root'
        )
      end

      it 'creates the server down index page' do
        params = [
            %r(^\s+<h1>django_base is down for maintenance\. Please come back later\.</h1>$)
        ]
        expect(chef_run).to_not create_template('/home/web_user/sites/django_base/down/index.html').with(
             owner: 'web_user',
             group: 'www-data',
             mode: '0440',
             source: 'index_down.html.erb',
             variables: {
                 app_name: 'django_base'
             }
        )
        params.each do |p|
          expect(chef_run).to_not render_file('/home/web_user/sites/django_base/down/index.html').with_content(p)
        end
      end

      it 'creates or updates django_base_down.conf file' do
        params = [
            /^# django_base_down.conf$/,
            %r(^\s+index index.html;$),
            /^\s+listen\s+80;$/,
            /^\s+server_name\s+192\.168\.1\.81;$/,
            %r(^\s+root /home/web_user/sites/django_base/down;),
            %r(^\s+alias /home/web_user/sites/django_base/media;),
            %r(^\s+alias /home/web_user/sites/django_base/static;),
        ]
        expect(chef_run).to create_template('/etc/nginx/sites-available/django_base_down.conf').with({
                  owner: 'root',
                  group: 'root',
                  mode: '0400',
                  source: 'app_name_down.conf.erb',
                  variables: {
                      app_name: 'django_base',
                      listen_port: '80',
                      server_name: '192.168.1.81',
                      down_path: '/home/web_user/sites/django_base/down',
                      static_path: '/home/web_user/sites/django_base/static',
                      media_path: '/home/web_user/sites/django_base/media',
                  }
                                                                                                })
        params.each do |p|
          expect(chef_run).to render_file('/etc/nginx/sites-available/django_base_down.conf').with_content(p)
        end
      end

      it 'disables the default site' do
        expect(chef_run).to delete_file('/etc/nginx/sites-enabled/default')
      end

      it 'enables the server down site' do
        expect(chef_run).to create_link('/etc/nginx/sites-enabled/django_base_down.conf').with(
                   owner: 'root',
                   group: 'root',
                   to: '/etc/nginx/sites-available/django_base_down.conf'
        )
      end

      it 'notifies nginx to restart' do
        site_down_enabled = chef_run.link('/etc/nginx/sites-enabled/django_base_down.conf')
        expect(site_down_enabled).to notify('service[nginx]').to(:restart).immediately
      end
    end
  end
end

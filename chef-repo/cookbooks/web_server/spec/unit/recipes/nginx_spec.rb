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
    context "When all attributes are default, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        runner = ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version)
        runner.converge(described_recipe)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'includes chef-vault and firewall recipes' do
        recipes = ['chef-vault', 'basic_node::firewall']
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
            %r(^\s+alias /home/app_user/sites/django_base/media;),
            %r(^\s+alias /home/app_user/sites/django_base/static;),
            %r(^\s+include\s+/home/app_user/sites/django_base/source/django_base/uwsgi_params;$)
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
                app_user: 'app_user',
            }
        })
        params.each do |p|
          expect(chef_run).to render_file('/etc/nginx/sites-available/django_base.conf').with_content(p)
        end
      end

      it 'creates the server down site file structure' do
        expect(chef_run).to create_directory('/var/www').with(
            owner: 'root',
            group: 'www-data',
            mode: '0750',
        )
        expect(chef_run).to create_directory('/var/www/django_base_down').with(
            owner: 'root',
            group: 'www-data',
            mode: '0750',
        )
      end

      it 'creates the server down index page' do
        params = [
            %r(^\s+<h1>django_base is down for maintenance\. Please come back later\.</h1>$)
        ]
        expect(chef_run).to create_template('/var/www/django_base_down/index.html').with(
             owner: 'root',
             group: 'www-data',
             mode: '0440',
             source: 'index_down.html.erb',
             variables: {
                 app_name: 'django_base'
             }
        )
        params.each do |p|
          expect(chef_run).to render_file('/var/www/django_base_down/index.html').with_content(p)
        end
      end

      it 'creates or updates django_base_down.conf file' do
        params = [
            /^# django_base_down.conf$/,
            %r(^\s+index index.html;$),
            /^\s+listen\s+80;$/,
            /^\s+server_name\s+192\.168\.1\.81;$/,
            %r(^\s+root /var/www/django_base_down;)
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

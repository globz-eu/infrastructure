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
# Spec:: default

require 'spec_helper'

describe 'standalone_app_server::default' do
  context 'When all attributes are default, on an Ubuntu 14.04 platform' do
    include ChefVault::TestFixtures.rspec_shared_context(true)
    let(:chef_run) do
      runner = ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04')
      runner.converge(described_recipe)
    end

    before do
      stub_command(/ls \/.*\/recovery.conf/).and_return(false)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    # manages app user
    it 'creates the admin user' do
      expect(chef_run).to create_user('app_user').with(
          home: '/home/app_user',
          shell: '/bin/bash',
          password: '$6$g7n0bpuYPHBI.$FVkbyH37IcBhDc000UcrGZ/u4n1f9JaEhLtBrT1VcAwKXL1sh9QDoTb3leMdazZVLQuv/w1FCBeqXX6GZGWid/'
      )
    end

    it 'adds app_user to group www-data' do
      expect(chef_run).to manage_group('www-data').with(
          append: true,
          members: ['app_user']
      )
    end

    # installs app from git
    it 'installs the git package' do
      expect( chef_run ).to install_package('git')
    end

    it 'creates the /home/app_user/sites directory' do
      expect(chef_run).to create_directory('/home/app_user/sites').with(
          owner: 'app_user',
          group: 'www-data',
          mode: '0550',
      )
    end

    it 'creates the /home/app_user/sites/django_base directory' do
      expect(chef_run).to create_directory('/home/app_user/sites/django_base').with(
          owner: 'app_user',
          group: 'www-data',
          mode: '0550',
      )
    end

    it 'creates the /home/app_user/sites/django_base/source directory' do
      expect(chef_run).to create_directory('/home/app_user/sites/django_base/source').with(
          owner: 'app_user',
          group: 'app_user',
          mode: '0500',
      )
    end

    it 'clones or syncs the django app' do
      expect( chef_run ).to sync_git('/home/app_user/sites/django_base/source').with(repository: 'https://github.com/globz-eu/django_base.git')
    end

    it 'changes ownership of the django app to app_user:app_user' do
      expect(chef_run).to run_execute('chown -R app_user:app_user /home/app_user/sites/django_base/source')
    end

    it 'changes permissions for all files in django app to 0400' do
      expect(chef_run).to run_execute('find /home/app_user/sites/django_base/source -type f -exec chmod 0400 {} +')
    end

    it 'changes permissions for all directories in django app to 0500' do
      expect(chef_run).to run_execute('find /home/app_user/sites/django_base/source -type d -exec chmod 0500 {} +')
    end

    # manages the python environment
    it 'creates a python 3.4 runtime' do
      expect(chef_run).to install_python_runtime('3.4')
    end

    it 'creates the venv file structure' do
      expect(chef_run).to create_directory('/home/app_user/.envs').with({
                                                                            owner: 'app_user',
                                                                            group: 'app_user',
                                                                            mode: '0500'
                                                                        })
      expect(chef_run).to create_directory('/home/app_user/.envs/django_base').with({
                                                                                        owner: 'app_user',
                                                                                        group: 'app_user',
                                                                                        mode: '0500'
                                                                                    })
    end

    it 'creates a venv' do
      expect(chef_run).to create_python_virtualenv('/home/app_user/.envs/django_base').with({
                                                                                                python: '/usr/bin/python3.4'
                                                                                            })
    end

    it 'installs python3-numpy' do
      expect(chef_run).to install_package('python3-numpy')
    end

    it 'installs the numpy python package' do
      expect(chef_run).to install_python_package('numpy').with({version: '1.11.0'})
    end

    it 'changes ownership of the venv to app_user:app_user' do
      expect(chef_run).to run_execute('chown -R app_user:app_user /home/app_user/.envs/django_base')
    end

    # configures the django app
    it 'creates the directory structure for the app static files' do
      expect(chef_run).to create_directory('/home/app_user/sites/django_base/static').with(
          owner: 'app_user',
          group: 'www-data',
          mode: '0750',
      )
      expect(chef_run).to create_directory('/home/app_user/sites/django_base/media').with(
          owner: 'app_user',
          group: 'www-data',
          mode: '0750',
      )
    end

    it 'creates the directory structure for the unix socket' do
      expect(chef_run).to create_directory('/home/app_user/sites/django_base/sockets').with(
          owner: 'app_user',
          group: 'www-data',
          mode: '0750',
      )
    end

    it 'adds the app path to the python path' do
      expect(chef_run).to create_template('/home/app_user/.envs/django_base/lib/python3.4/django_base.pth').with(
          owner: 'app_user',
          group: 'app_user',
          mode: '0400',
          source: 'app_name.pth.erb',
          variables: {
              app_path: '/home/app_user/sites/django_base/source',
          })
    end

    it 'adds the configuration file' do
      expect(chef_run).to create_template('/home/app_user/sites/django_base/source/configuration.py').with(
          owner: 'app_user',
          group: 'app_user',
          mode: '0400',
          source: 'configuration.py.erb',
          variables: {
              secret_key: 'n)#o5pw7kelvr982iol48tz--n#q!*8681k3sv0^*q#-lddwv!',
              debug: 'False',
              allowed_host: '192.168.1.82',
              engine: 'django.db.backends.postgresql_psycopg2',
              app_name: 'django_base',
              db_user: 'db_user',
              db_user_password: 'db_user_password',
              db_host: 'localhost'
          })
      expect(chef_run).to render_file('/home/app_user/sites/django_base/source/configuration.py')
    end

    it 'adds the admin settings file' do
      expect(chef_run).to create_template('/home/app_user/sites/django_base/source/django_base/settings_admin.py').with(
          owner: 'app_user',
          group: 'app_user',
          mode: '0400',
          source: 'settings_admin.py.erb',
          variables: {
              app_name: 'django_base',
              db_admin_user: 'postgres',
              db_admin_password: 'postgres_password',
          })
      expect(chef_run).to render_file('/home/app_user/.envs/django_base/lib/python3.4/django_base.pth')
    end

    it 'adds the python script for installing system dependencies' do
      expect(chef_run).to create_template('/home/app_user/sites/django_base/source/install_dependencies.py').with(
          owner: 'app_user',
          group: 'app_user',
          mode: '0500',
          source: 'install_dependencies.py.erb',
          variables: {
              dep_file_path: '/home/app_user/sites/django_base/source/system_dependencies.txt'
          })
      expect(chef_run).to render_file('/home/app_user/.envs/django_base/lib/python3.4/django_base.pth')
    end

    it 'runs the install_dependencies script' do
      expect(chef_run).to run_bash('install_dependencies').with({
                                                                    cwd: '/home/app_user/sites/django_base/source',
                                                                    code: './install_dependencies.py',
                                                                    user: 'root'
                                                                })
    end

    it 'installs python packages from requirements.txt' do
      expect(chef_run).to run_bash('install_requirements').with({
                                                                    cwd: '/home/app_user/sites/django_base/source',
                                                                    code: '/home/app_user/.envs/django_base/bin/pip3 install -r ./requirements.txt',
                                                                    user: 'root'
                                                                })
    end

    # installs and configures the uwsgi server
    it 'installs the uwsgi python package' do
      expect(chef_run).to install_python_package('uwsgi').with({python: '/usr/bin/python3.4'})
    end

    it 'creates the /var/log/uwsgi directory' do
      expect(chef_run).to create_directory('/var/log/uwsgi').with(
          owner: 'root',
          group: 'root',
          mode: '0755',
      )
    end

    it 'adds the django_base_uwsgi.ini file' do
      expect(chef_run).to create_template('/home/app_user/sites/django_base/source/django_base_uwsgi.ini').with(
          owner: 'app_user',
          group: 'app_user',
          mode: '0400',
          source: 'app_name_uwsgi.ini.erb',
          variables: {
              app_name: 'django_base',
              app_user: 'app_user',
              processes: '2',
              socket: '/home/app_user/sites/django_base/sockets/django_base.sock',
              chmod_socket: 'chmod-socket = 660',
              log_file: '/var/log/uwsgi/django_base.log',
              pid_file: '/tmp/django_base-uwsgi-master.pid'
          })
      expect(chef_run).to render_file('/home/app_user/sites/django_base/source/django_base_uwsgi.ini')
    end

    # configures the postgresql database
    it 'starts the postgresql service' do
      expect(chef_run).to start_service( 'postgresql' )
    end

    it 'enables the postgresql service' do
      expect(chef_run).to enable_service( 'postgresql' )
    end

    it 'renders the pg_hba file' do
      pg_auth = [
          /local\s+all\s+postgres\s+ident/,
          /local\s+all\s+all\s+md5/,
          %r(host\s+all\s+all\s+127\.0\.0\.1/32\s+md5),
          %r(host\s+all\s+all\s+::1/128\s+md5)
      ]
      pg_auth.each do |p|
        expect(chef_run).to render_file('/etc/postgresql/9.5/main/pg_hba.conf').with_content(p)
      end
    end

    it 'creates database' do
      expect(chef_run).to create_postgresql_database('django_base').with({
                                                                             connection: {
                                                                                 :host      => '127.0.0.1',
                                                                                 :port      => 5432,
                                                                                 :username  => 'postgres',
                                                                                 :password  => 'postgres_password'
                                                                             }
                                                                         })
    end

    it 'creates database user' do
      expect(chef_run).to create_postgresql_database_user('db_user').with({
                                                                              connection: {
                                                                                  :host      => '127.0.0.1',
                                                                                  :port      => 5432,
                                                                                  :username  => 'postgres',
                                                                                  :password  => 'postgres_password'
                                                                              },
                                                                              password: 'db_user_password'
                                                                          })
    end

    it 'subscribes grant commands to database user creation' do
      grant_db = chef_run.bash('grant_default_db')
      grant_seq = chef_run.bash('grant_default_seq')
      expect(grant_db).to subscribe_to('postgresql_database_user[db_user]').on(:run).immediately
      expect(grant_seq).to subscribe_to('postgresql_database_user[db_user]').on(:run).immediately
    end

    it 'installs the "postgresql-9.5 postgresql-contrib-9.5 postgresql-client-9.5 postgresql-server-9.5 postgresql-server-dev-9.5" package' do
      expect(chef_run).to install_package('postgresql-9.5')
      expect(chef_run).to install_package('postgresql-contrib-9.5')
      expect(chef_run).to install_package('postgresql-client-9.5')
      expect(chef_run).to install_package('postgresql-server-dev-9.5')
    end

    it 'runs default privilege grant code' do
      expect(chef_run).to_not run_bash('grant_default_db').with({
          code: "sudo -u postgres psql -d django_base -c 'ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO db_user;'",
          user: 'root'
                                                                })
      expect(chef_run).to_not run_bash('grant_default_seq').with({
           code: "sudo -u postgres psql -d django_base -c 'ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, USAGE ON SEQUENCES TO db_user;'",
           user: 'root'
                                                                 })
    end

    # configures the nginx server
    it 'installs the nginx package' do
      expect(chef_run).to install_package( 'nginx' )
    end

    it 'starts the nginx service' do
      expect(chef_run).to start_service( 'nginx' )
    end

    it 'enables the nginx service' do
      expect(chef_run).to enable_service( 'nginx' )
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
          /^\s+server_name\s+192\.168\.1\.82;$/,
          %r(^\s+alias /home/app_user/sites/django_base/media;),
          %r(^\s+alias /home/app_user/sites/django_base/static;),
          %r(^\s+include\s+/home/app_user/sites/django_base/source/uwsgi_params;$)
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
              server_name: '192.168.1.82',
              app_user: 'app_user',
          }
                                                                                              })
      params.each do |p|
        expect(chef_run).to render_file('/etc/nginx/sites-available/django_base.conf').with_content(p)
      end
    end

    it 'creates a symlink from sites-enabled/django_base.conf to sites-available' do
      expect(chef_run).to create_link('/etc/nginx/sites-enabled/django_base.conf').with({
                                                                                            owner: 'root',
                                                                                            group: 'root',
                                                                                            to: '/etc/nginx/sites-available/django_base.conf'
                                                                                        })
    end

    it 'notifies nginx to restart on creation of the symlink to sites-enabled/django_base.conf' do
      symlink = chef_run.link('/etc/nginx/sites-enabled/django_base.conf')
      expect(symlink).to notify('service[nginx]').immediately
    end

    it 'removes default site file' do
      expect(chef_run).to delete_file('/etc/nginx/sites-enabled/default')
    end

    it 'starts the uwsgi server' do
      pending 'implement uwsgi server test'
    end

    it 'manages migrations' do
      pending 'implement migrations test'
    end

  end
end

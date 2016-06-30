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
# Spec:: postgresql

require 'spec_helper'

describe 'db_server::postgresql' do
  ['14.04', '16.04'].each do |version|
    context "When all attributes are default, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version).converge(described_recipe)
      end

      before do
        stub_command(/ls \/.*\/recovery.conf/).and_return(false)
        stub_command("sudo -u postgres psql -c '\\l' | grep ").and_return(false)
        stub_command("sudo -u postgres psql -c '\\du' | grep db_user").and_return(false)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'includes the expected recipes' do
        expect(chef_run).to include_recipe('chef-vault')
      end

      it 'starts the postgresql service' do
        expect(chef_run).to start_service( 'postgresql' )
      end

      if version == '14.04'
        it 'enables the postgresql service' do
          expect(chef_run).to enable_service( 'postgresql' )
        end
      end

      if version == '16.04'
        it 'manages the pg_hba.conf file' do
          expect(chef_run).to create_template('/etc/postgresql/9.5/main/pg_hba.conf').with({
                     owner: 'postgres',
                     group: 'postgres',
                     mode: '0600',
                     source: 'pg_hba.conf.erb',
                     variables: {
                         postgres_local: 'ident',
                         all_local: 'md5',
                         all_IPv4: 'md5',
                         all_IPv6: 'md5',
                     }
                                                                                           })
        end

        it 'restarts postgresql service after creation of pg_hba.conf' do
          hba_conf = chef_run.template('/etc/postgresql/9.5/main/pg_hba.conf')
          expect(hba_conf).to notify('service[postgresql]').to(:restart).immediately
        end

        it 'sets the postgres password' do
          expect(chef_run).to run_bash('set_postgres_password').with({
                     code: "sudo -u postgres psql -c \"ALTER USER postgres WITH PASSWORD 'postgres_password';\"",
                     user: 'root'
                                                                     })
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
      end

      it 'does not create database' do
        expect(chef_run).to_not run_bash('create_database')
      end

      it 'does not create database user' do
        expect(chef_run).to_not run_bash('create_user')
        expect(chef_run).to_not run_bash('grant_default_seq')
      end
    end
  end
end

describe 'db_server::postgresql' do
  ['14.04', '16.04'].each do |version|
    context "When app repo is specified, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version) do |node|
          node.set['db_server']['git']['app_repo'] = 'https://github.com/globz-eu/django_base.git'
        end.converge(described_recipe)
      end

      before do
        stub_command(/ls \/.*\/recovery.conf/).and_return(false)
        stub_command("sudo -u postgres psql -c '\\l' | grep django_base").and_return(false)
        stub_command("sudo -u postgres psql -c '\\du' | grep db_user").and_return(false)
        stub_command('ls /home/db_user/sites/django_base/scripts').and_return(false)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'starts the postgresql service' do
        expect(chef_run).to start_service( 'postgresql' )
      end

      if version == '14.04'
        it 'enables the postgresql service' do
          expect(chef_run).to enable_service( 'postgresql' )
        end
      end

      if version == '16.04'
        it 'manages the pg_hba.conf file' do
          expect(chef_run).to create_template('/etc/postgresql/9.5/main/pg_hba.conf').with({
                     owner: 'postgres',
                     group: 'postgres',
                     mode: '0600',
                     source: 'pg_hba.conf.erb',
                     variables: {
                         postgres_local: 'ident',
                         all_local: 'md5',
                         all_IPv4: 'md5',
                         all_IPv6: 'md5',
                     }
                                                                                           })
        end

        it 'restarts postgresql service after creation of pg_hba.conf' do
          hba_conf = chef_run.template('/etc/postgresql/9.5/main/pg_hba.conf')
          expect(hba_conf).to notify('service[postgresql]').to(:restart).immediately
        end

        it 'sets the postgres password' do
          expect(chef_run).to run_bash('set_postgres_password').with({
                     code: "sudo -u postgres psql -c \"ALTER USER postgres WITH PASSWORD 'postgres_password';\"",
                     user: 'root'
                                                           })
        end
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

      if version == '14.04'
        it 'installs the "postgresql-9.5 postgresql-contrib-9.5 postgresql-client-9.5 postgresql-server-9.5 postgresql-server-dev-9.5" package' do
          expect(chef_run).to install_package('postgresql-9.5')
          expect(chef_run).to install_package('postgresql-contrib-9.5')
          expect(chef_run).to install_package('postgresql-client-9.5')
          expect(chef_run).to install_package('postgresql-server-dev-9.5')
        end
      elsif version == '16.04'
        it 'installs the "postgresql-9.5 postgresql-contrib-9.5 postgresql-client-9.5 postgresql-server-9.5 postgresql-server-dev-9.5" package' do
          expect(chef_run).to install_package(%w(postgresql postgresql-contrib-9.5 postgresql-server-dev-9.5))
        end
      end

      it 'creates database user' do
        expect(chef_run).to run_bash('create_user').with({
          code: "sudo -u postgres psql -c \"CREATE USER db_user WITH PASSWORD 'db_user_password';\"",
          user: 'root'
                                                         })
      end

      it 'creates the /home/db_user/sites/django_base/scripts/conf.py file' do
        expect(chef_run).to create_template('/home/db_user/sites/django_base/scripts/conf.py').with(
            owner: 'db_user',
            group: 'db_user',
            mode: '0400',
            source: 'conf.py.erb',
            variables: {
                dist_version: version,
                debug: 'DEBUG',
                nginx_conf: '',
                git_repo: 'https://github.com/globz-eu/django_base.git',
                app_home: '',
                app_home_tmp: '',
                app_user: '',
                web_user: '',
                webserver_user: '',
                db_user: 'db_user',
                db_admin_user: 'postgres',
                static_path: '',
                media_path: '',
                uwsgi_path: '',
                down_path: '',
                log_file: '/var/log/django_base/create_db.log'
            }
        )
        install_app_conf = [
            %r(^DIST_VERSION = '#{version}'$),
            %r(^DEBUG = 'DEBUG'$),
            %r(^NGINX_CONF = ''$),
            %r(^APP_HOME = ''$),
            %r(^APP_HOME_TMP = ''$),
            %r(^APP_USER = ''$),
            %r(^WEB_USER = ''$),
            %r(^WEBSERVER_USER = ''$),
            %r(^DB_USER = 'db_user'$),
            %r(^DB_ADMIN_USER = 'postgres'$),
            %r(^GIT_REPO = 'https://github\.com/globz-eu/django_base\.git'$),
            %r(^STATIC_PATH = ''$),
            %r(^MEDIA_PATH = ''$),
            %r(^UWSGI_PATH = ''$),
            %r(^VENV = ''$),
            %r(^REQS_FILE = ''$),
            %r(^SYS_DEPS_FILE = ''$),
            %r(^LOG_FILE = '/var/log/django_base/create_db\.log'$)
        ]
        install_app_conf.each do |u|
          expect(chef_run).to render_file(
                                  '/home/db_user/sites/django_base/scripts/conf.py'
                              ).with_content(u)
        end
      end

      it 'runs create database script' do
        expect(chef_run).to run_bash('run_create_database').with(
          code: './dbserver.py -c',
          cwd: '/home/db_user/sites/django_base/scripts',
          user: 'root'
        )
      end
    end
  end
end

describe 'db_server::postgresql' do
  ['14.04', '16.04'].each do |version|
    context "When app repo is specified, on a second run on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version) do |node|
          node.set['db_server']['postgresql']['git']['app_repo'] = 'https://github.com/globz-eu/django_base.git'
        end.converge(described_recipe)
      end

      before do
        stub_command(/ls \/.*\/recovery.conf/).and_return(false)
        stub_command("sudo -u postgres psql -c '\\l' | grep django_base").and_return(true)
        stub_command("sudo -u postgres psql -c '\\du' | grep db_user").and_return(true)
        stub_command('ls /home/db_user/sites/django_base/scripts').and_return(false)
      end

      it 'do not create database user' do
        expect(chef_run).to_not run_bash('create_user').with({
                   code: "sudo -u postgres psql -c \"CREATE USER db_user WITH PASSWORD 'db_user_password';\"",
                   user: 'root'
                                                         })
      end
    end
  end
end

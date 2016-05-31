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
# Server Spec:: django_app

require 'spec_helper'

describe 'django_app_server::django_app' do
  ['14.04', '16.04'].each do |version|
    context "When app name is specified, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version) do |node|
          node.set['django_app_server']['django_app']['app_name'] = 'django_base'
        end.converge(described_recipe)
      end

      before do
        stub_command('ls /home/app_user/sites/django_base/source/django_base').and_return(false)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

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

      it 'creates the /home/app_user/.envs directory' do
        expect(chef_run).to create_directory('/home/app_user/.envs').with(
            owner: 'app_user',
            group: 'app_user',
            mode: '0500',
        )
      end

      it 'creates the /var/log/django_base directory' do
        expect(chef_run).to create_directory('/var/log/django_base').with(
            owner: 'root',
            group: 'root',
            mode: '0755',
        )
      end

      it 'creates the /home/app_user/sites/django_base/static directory' do
        expect(chef_run).to create_directory('/home/app_user/sites/django_base/static').with(
            owner: 'app_user',
            group: 'www-data',
            mode: '0750',
        )
      end

      it 'creates the /home/app_user/sites/django_base/media directory' do
        expect(chef_run).to create_directory('/home/app_user/sites/django_base/media').with(
            owner: 'app_user',
            group: 'www-data',
            mode: '0750',
        )
      end

      it 'creates the /home/app_user/sites/django_base/sockets directory' do
        expect(chef_run).to create_directory('/home/app_user/sites/django_base/sockets').with(
            owner: 'app_user',
            group: 'www-data',
            mode: '0750',
        )
      end

      it 'creates the /home/app_user/sites/django_base/source/django_base_uwsgi.ini file' do
        expect(chef_run).to create_template('/home/app_user/sites/django_base/source/django_base_uwsgi.ini').with(
            owner: 'app_user',
            group: 'app_user',
            mode: '0400',
            source: 'app_name_uwsgi.ini.erb',
            variables: {
                app_name: 'django_base',
                app_user: 'app_user',
                web_user: 'www-data',
                processes: '2',
                socket: '/home/app_user/sites/django_base/sockets/django_base.sock',
                chmod_socket: 'chmod-socket = 660',
                log_file: '/var/log/uwsgi/django_base.log',
                pid_file: '/tmp/django_base-uwsgi-master.pid'
            }
        )
        uwsgi_ini = [
            %r(^# django_base_uwsgi\.ini file$),
            %r(^chdir = /home/app_user/sites/django_base/source/django_base$),
            %r(^module = django_base\.wsgi$),
            %r(^home = /home/app_user/\.envs/django_base$),
            %r(^uid = app_user$),
            %r(^gid = www-data$),
            %r(^processes = 2$),
            %r(^socket = /home/app_user/sites/django_base/sockets/django_base\.sock$),
            %r(^chmod-socket = 660$),
            %r(^daemonize = /var/log/uwsgi/django_base\.log$),
            %r(^safe-pidfile = /tmp/django_base-uwsgi-master\.pid$)
        ]
        uwsgi_ini.each do |u|
          expect(chef_run).to render_file('/home/app_user/sites/django_base/source/django_base_uwsgi.ini').with_content(u)
        end
      end
    end
  end
end

describe 'django_app_server::django_app' do
  ['14.04', '16.04'].each do |version|
    context "When app name and git repo are specified, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version) do |node|
          node.set['django_app_server']['django_app']['app_name'] = 'django_base'
          node.set['django_app_server']['git']['git_repo'] = 'https://github.com/globz-eu'
        end.converge(described_recipe)
      end

      before do
        stub_command('ls /home/app_user/sites/django_base/source/django_base').and_return(false)
        stub_command('ls /home/app_user/sites/django_base/scripts').and_return(false)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

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

      it 'creates the /home/app_user/.envs directory' do
        expect(chef_run).to create_directory('/home/app_user/.envs').with(
            owner: 'app_user',
            group: 'app_user',
            mode: '0500',
        )
      end

      it 'creates the /var/log/django_base directory' do
        expect(chef_run).to create_directory('/var/log/django_base').with(
            owner: 'root',
            group: 'root',
            mode: '0755',
        )
      end

      it 'creates the /home/app_user/sites/django_base/static directory' do
        expect(chef_run).to create_directory('/home/app_user/sites/django_base/static').with(
            owner: 'app_user',
            group: 'www-data',
            mode: '0750',
        )
      end

      it 'creates the /home/app_user/sites/django_base/media directory' do
        expect(chef_run).to create_directory('/home/app_user/sites/django_base/media').with(
            owner: 'app_user',
            group: 'www-data',
            mode: '0750',
        )
      end

      it 'creates the /home/app_user/sites/django_base/conf.d directory' do
        expect(chef_run).to create_directory('/home/app_user/sites/django_base/conf.d').with(
            owner: 'app_user',
            group: 'www-data',
            mode: '0750',
        )
      end

      it 'creates the /home/app_user/sites/django_base/sockets directory' do
        expect(chef_run).to create_directory('/home/app_user/sites/django_base/sockets').with(
            owner: 'app_user',
            group: 'www-data',
            mode: '0750',
        )
      end

      it 'creates the /home/app_user/sites/django_base/conf.d/configuration.py file' do
        expect(chef_run).to create_template('/home/app_user/sites/django_base/conf.d/configuration.py').with(
            owner: 'app_user',
            group: 'app_user',
            mode: '0400',
            source: 'configuration.py.erb',
            variables: {
                secret_key: 'n)#o5pw7kelvr982iol48tz--n#q!*8681k3sv0^*q#-lddwv!',
                debug: 'False',
                allowed_host: 'localhost',
                engine: 'django.db.backends.postgresql_psycopg2',
                app_name: 'django_base',
                db_user: 'db_user',
                db_user_password: 'db_user_password',
                db_host: 'localhost'
            }
        )
        config = [
            %r(^SECRET_KEY = 'n\)#o5pw7kelvr982iol48tz--n#q!\*8681k3sv0\^\*q#-lddwv!'$),
            %r(^DEBUG = False$),
            %r(^ALLOWED_HOSTS = \['localhost'\]$),
            %r(^\s+'ENGINE': 'django\.db\.backends\.postgresql_psycopg2',$),
            %r(^\s+'NAME': 'django_base',$),
            %r(^\s+'USER': 'db_user',$),
            %r(^\s+'PASSWORD': "db_user_password",$),
            %r(^\s+'HOST': 'localhost',$),
            %r(^\s+'NAME': 'test_django_base',$)
        ]
        config.each do |u|
          expect(chef_run).to render_file('/home/app_user/sites/django_base/conf.d/configuration.py').with_content(u)
        end
      end

      it 'creates the /home/app_user/sites/django_base/conf.d/settings_admin.py file' do
        expect(chef_run).to create_template('/home/app_user/sites/django_base/conf.d/settings_admin.py').with(
            owner: 'app_user',
            group: 'app_user',
            mode: '0400',
            source: 'settings_admin.py.erb',
            variables: {
                app_name: 'django_base',
                db_admin_user: 'postgres',
                db_admin_password: 'postgres_password',
            }
        )
        install_app_conf = [
            %r(^from django_base\.settings import \*$),
            %r(^\s+'USER': 'postgres',$),
            %r(^\s+'PASSWORD': "postgres_password",$)
        ]
        install_app_conf.each do |u|
          expect(chef_run).to render_file('/home/app_user/sites/django_base/conf.d/settings_admin.py').with_content(u)
        end
      end

      it 'creates the /home/app_user/sites/django_base/source/django_base_uwsgi.ini file' do
        expect(chef_run).to create_template('/home/app_user/sites/django_base/source/django_base_uwsgi.ini').with(
            owner: 'app_user',
            group: 'app_user',
            mode: '0400',
            source: 'app_name_uwsgi.ini.erb',
            variables: {
                app_name: 'django_base',
                app_user: 'app_user',
                web_user: 'www-data',
                processes: '2',
                socket: '/home/app_user/sites/django_base/sockets/django_base.sock',
                chmod_socket: 'chmod-socket = 660',
                log_file: '/var/log/uwsgi/django_base.log',
                pid_file: '/tmp/django_base-uwsgi-master.pid'
            }
        )
        uwsgi_ini = [
            %r(^# django_base_uwsgi\.ini file$),
            %r(^chdir = /home/app_user/sites/django_base/source/django_base$),
            %r(^module = django_base\.wsgi$),
            %r(^home = /home/app_user/\.envs/django_base$),
            %r(^uid = app_user$),
            %r(^gid = www-data$),
            %r(^processes = 2$),
            %r(^socket = /home/app_user/sites/django_base/sockets/django_base\.sock$),
            %r(^chmod-socket = 660$),
            %r(^daemonize = /var/log/uwsgi/django_base\.log$),
            %r(^safe-pidfile = /tmp/django_base-uwsgi-master\.pid$)
        ]
        uwsgi_ini.each do |u|
          expect(chef_run).to render_file('/home/app_user/sites/django_base/source/django_base_uwsgi.ini').with_content(u)
        end
      end

      it 'clones the scripts' do
        expect( chef_run ).to run_bash('git_clone_scripts').with(
            cwd: '/home/app_user/sites/django_base',
            code: 'git clone https://github.com/globz-eu/scripts.git',
            user: 'root'
        )
      end

      it 'notifies script ownership and permission commands' do
        clone_scripts = chef_run.bash('git_clone_scripts')
        expect(clone_scripts).to notify('bash[own_scripts]').to(:run).immediately
        expect(clone_scripts).to notify('bash[scripts_dir_permissions]').to(:run).immediately
        expect(clone_scripts).to notify('bash[make_scripts_executable]').to(:run).immediately
      end

      it 'changes ownership of the script directory to app_user:app_user' do
        expect(chef_run).to_not run_bash('own_scripts')
      end

      it 'changes permissions the scripts directory to 0500' do
        expect(chef_run).to_not run_bash('scritps_dir_permissions')
      end

      it 'makes scripts executable' do
        expect(chef_run).to_not run_bash('make_scripts_executable')
      end

      it 'creates the /home/app_user/sites/django_base/scripts/install_django_app_conf.py file' do
        expect(chef_run).to create_template('/home/app_user/sites/django_base/scripts/install_django_app_conf.py').with(
            owner: 'app_user',
            group: 'app_user',
            mode: '0400',
            source: 'install_django_app_conf.py.erb',
            variables: {
                dist_version: version,
                debug: 'False',
                git_repo: 'https://github.com/globz-eu/django_base.git',
                app_home: '/home/app_user/sites/django_base/source',
                app_user: 'app_user',
                venv: '/home/app_user/.envs/django_base',
                reqs_file: '/home/app_user/sites/django_base/source/django_base/requirements.txt',
                sys_deps_file: '/home/app_user/sites/django_base/source/django_base/system_dependencies.txt',
                log_file: '/var/log/django_base/install.log'
            }
        )
        install_app_conf = [
            %r(^DIST_VERSION = #{version}$),
            %r(^DEBUG = False$),
            %r(^APP_HOME = '/home/app_user/sites/django_base/source'$),
            %r(^APP_USER = 'app_user'$),
            %r(^GIT_REPO = 'https://github\.com/globz-eu/django_base\.git'$),
            %r(^VENV = '/home/app_user/\.envs/django_base'$),
            %r(^REQS_FILE = '/home/app_user/sites/django_base/source/django_base/requirements\.txt'$),
            %r(^SYS_DEPS_FILE = '/home/app_user/sites/django_base/source/django_base/system_dependencies\.txt'$),
            %r(^LOG_FILE = '/var/log/django_base/install\.log'$)
        ]
        install_app_conf.each do |u|
          expect(chef_run).to render_file('/home/app_user/sites/django_base/scripts/install_django_app_conf.py').with_content(u)
        end
      end



      if version == '14.04'
        it 'runs the install_django_app script' do
          expect(chef_run).to run_bash('install_django_app').with(
                      cwd: '/home/app_user/sites/django_base/scripts',
                      code: './install_django_app_trusty.py',
                      user: 'root'
          )
        end
      end

      if version == '16.04'
        it 'runs the install_django_app script' do
          expect(chef_run).to run_bash('install_django_app').with(
              cwd: '/home/app_user/sites/django_base/scripts',
              code: './install_django_app_xenial.py',
              user: 'root'
          )
        end
      end

      it 'adds the django_base_uwsgi.ini file' do
        params = [
            /^# django_base_uwsgi.ini file$/,
            %r(^chdir\s+=\s+/home/app_user/sites/django_base/source/django_base$),
            /^module\s+=\s+django_base\.wsgi$/,
            %r(^home\s+=\s+/home/app_user/\.envs/django_base$),
            /^uid\s+=\s+app_user$/,
            /^gid\s+=\s+www-data$/,
            /^processes\s+=\s+2$/,
            %r(^socket = /home/app_user/sites/django_base/sockets/django_base\.sock$),
            /^chmod-socket\s+=\s+660$/,
            %r(^daemonize\s+=\s+/var/log/uwsgi/django_base\.log$),
            %r(^master-fifo\s+=\s+/tmp/fifo0$)
        ]
        expect(chef_run).to create_template('/home/app_user/sites/django_base/source/django_base_uwsgi.ini').with(
            owner: 'app_user',
            group: 'app_user',
            mode: '0400',
            source: 'app_name_uwsgi.ini.erb',
            variables: {
                app_name: 'django_base',
                app_user: 'app_user',
                web_user: 'www-data',
                processes: '2',
                socket: '/home/app_user/sites/django_base/sockets/django_base.sock',
                chmod_socket: 'chmod-socket = 660',
                log_file: '/var/log/uwsgi/django_base.log',
                pid_file: '/tmp/django_base-uwsgi-master.pid'
            })
        params.each do |p|
          expect(chef_run).to render_file('/home/app_user/sites/django_base/source/django_base_uwsgi.ini').with_content(p)
        end
      end
    end
  end
end

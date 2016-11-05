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

def common
  it 'converges successfully' do
    expect { chef_run }.to_not raise_error
  end

  it 'includes the expected recipes' do
    expect(chef_run).to include_recipe('chef-vault')
  end

  it 'installs the git package' do
    expect( chef_run ).to install_package('git')
  end

  it 'creates the /home/app_user/.envs directory' do
    expect(chef_run).to create_directory('/home/app_user/.envs').with(
        owner: 'app_user',
        group: 'app_user',
        mode: '0700',
    )
  end
end

def app(version, initial_users: false)
  it 'creates the /home/app_user/sites/django_base/source directory' do
    expect(chef_run).to create_directory('/home/app_user/sites/django_base/source').with(
        owner: 'app_user',
        group: 'app_user',
        mode: '0500',
    )
  end

  it 'creates the fifo directory' do
    expect(chef_run).to create_directory('/tmp/django_base').with(
        owner: 'root',
        group: 'root',
        mode: '0777',
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

  it 'creates the /home/app_user/sites/django_base/conf.d/settings.json file' do
    if version == '14.04'
      allowed_host = '192.168.1.82'
    elsif version == '16.04'
      allowed_host = '192.168.1.83'
    else
      allowed_host = ''
    end
    allowed_host_regex = Regexp.escape(allowed_host)
    vars = {
        secret_key: 'n)#o5pw7kelvr982iol48tz--n#q!*8681k3sv0^*q#-lddwv!',
        allowed_hosts: allowed_host,
        db_engine: 'django.db.backends.postgresql_psycopg2',
        db_name: 'django_base',
        db_user: 'db_user',
        db_password: 'db_user_password',
        db_admin_user: 'postgres',
        db_admin_password: 'postgres_password',
        db_host: 'localhost',
        test_db_name: 'test_django_base',
        broker_url: 'redis://localhost:6379/0',
        celery_result_backend: 'redis://localhost:6379/0',
        server_url: 'liveserver',
    }
    if initial_users
      vars[:init_users] = "\n  [\"user0\", \"user0@example.com\", \"user0_password\"],\n  [\"user1\", \"user1@example.com\", \"user1_password\"]\n"
      vars[:init_superuser] = "\"superuser\", \"superuser@example.com\", \"superuser_password\""
    else
      vars[:init_users] = ''
      vars[:init_superuser] = ''
    end
    expect(chef_run).to create_template('/home/app_user/sites/django_base/conf.d/settings.json').with(
        owner: 'app_user',
        group: 'app_user',
        mode: '0400',
        source: 'settings.json.erb',
        variables: vars
    )
    config = [
        %r(^\s+"SECRET_KEY": "n\)#o5pw7kelvr982iol48tz--n#q!\*8681k3sv0\^\*q#-lddwv!",$),
        %r(^\s+"ALLOWED_HOSTS": \["#{allowed_host_regex}"\],$),
        %r(^\s+"DEBUG": false,$),
        %r(^\s+"DB_ENGINE": "django\.db\.backends\.postgresql_psycopg2",$),
        %r(^\s+"DB_NAME": "django_base",$),
        %r(^\s+"DB_USER": "db_user",$),
        %r(^\s+"DB_PASSWORD": "db_user_password",$),
        %r(^\s+"DB_ADMIN_USER": "postgres",$),
        %r(^\s+"DB_ADMIN_PASSWORD": "postgres_password",$),
        %r(^\s+"DB_HOST": "localhost",$),
        %r(^\s+"TEST_DB_NAME": "test_django_base",$),
        %r(^\s+"BROKER_URL": "redis://localhost:6379/0",$),
        %r(^\s+"CELERY_RESULT_BACKEND": "redis://localhost:6379/0",$),
        %r(^\s+"SERVER_URL": "liveserver",$),
        %r(^\s+"SECURE_SSL_REDIRECT": false,$),
        %r(^\s+"SECURE_PROXY_SSL_HEADER": \[\],$),
        %r(^\s+"CHROME_DRIVER": "",$),
        %r(^\s+"FIREFOX_BINARY": "",$),
        %r(^\s+"HEROKU": false$),
    ]
    if initial_users
      users = [
          %r(^\s+"INITIAL_USERS": \[$),
          %r(^\s+\["user0", "user0@example\.com", "user0_password"\],$),
          %r(^\s+\["user1", "user1@example\.com", "user1_password"\]$),
          %r(^\s+"INITIAL_SUPERUSER": \["superuser", "superuser@example\.com", "superuser_password"\],$),
      ]
    else
      users = [
          %r(^\s+"INITIAL_USERS": \[\],$),
          %r(^\s+"INITIAL_SUPERUSER": \[\],$),
      ]
    end
    config += users
    config.each do |u|
      expect(chef_run).to render_file('/home/app_user/sites/django_base/conf.d/settings.json').with_content(u)
    end
  end

  it 'creates the /home/app_user/sites/django_base/scripts/conf.py file' do
    expect(chef_run).to create_template('/home/app_user/sites/django_base/scripts/conf.py').with(
        owner: 'app_user',
        group: 'app_user',
        mode: '0400',
        source: 'conf.py.erb',
        variables: {
            dist_version: version,
            log_level: "'DEBUG'",
            nginx_conf: '',
            git_repo: 'https://github.com/globz-eu/django_base.git',
            celery_pid: '/var/run/django_base/celery',
            app_home: '/home/app_user/sites/django_base/source',
            app_user: 'app_user',
            venv: '/home/app_user/.envs/django_base',
            reqs_file: '/home/app_user/sites/django_base/source/django_base/requirements.txt',
            sys_deps_file: '/home/app_user/sites/django_base/source/django_base/system_dependencies.txt',
            log_file: '/var/log/django_base/install.log',
            fifo_dir: '/tmp/django_base'
        }
    )
    install_app_conf = [
        %r(^DIST_VERSION = '#{version}'$),
        %r(^LOG_LEVEL = 'DEBUG'$),
        %r(^NGINX_CONF = ''$),
        %r(^APP_HOME = '/home/app_user/sites/django_base/source'$),
        %r(^APP_USER = 'app_user'$),
        %r(^GIT_REPO = 'https://github\.com/globz-eu/django_base\.git'$),
        %r(^CELERY_PID_PATH = '/var/run/django_base/celery'$),
        %r(^VENV = '/home/app_user/\.envs/django_base'$),
        %r(^REQS_FILE = '/home/app_user/sites/django_base/source/django_base/requirements\.txt'$),
        %r(^SYS_DEPS_FILE = '/home/app_user/sites/django_base/source/django_base/system_dependencies\.txt'$),
        %r(^LOG_FILE = '/var/log/django_base/install\.log'$),
        %r(^FIFO_DIR = '/tmp/django_base'$)
    ]
    install_app_conf.each do |u|
      expect(chef_run).to render_file('/home/app_user/sites/django_base/scripts/conf.py').with_content(u)
    end
  end

  it 'runs the create_venv script' do
    expect(chef_run).to run_bash('create_venv').with(
        cwd: '/home/app_user/sites/django_base/scripts',
        code: './djangoapp.py -e',
        user: 'app_user'
    )
  end

  it 'runs the install_django_app script' do
    expect(chef_run).to run_bash('install_django_app').with(
        cwd: '/home/app_user/sites/django_base/scripts',
        code: './djangoapp.py -i',
        user: 'root'
    )
  end

  it 'creates the /home/app_user/sites/django_base/conf.d/django_base_uwsgi.ini file' do
    expect(chef_run).to create_template('/home/app_user/sites/django_base/conf.d/django_base_uwsgi.ini').with(
        owner: 'app_user',
        group: 'app_user',
        mode: '0400',
        source: 'app_name_uwsgi.ini.erb',
        variables: {
            app_name: 'django_base',
            module: 'django_base',
            app_user: 'app_user',
            fifo: '/tmp/django_base/fifo0',
            web_user: 'www-data',
            processes: '2',
            socket: '/home/app_user/sites/django_base/sockets/django_base.sock',
            chmod_socket: 'chmod-socket = 660',
            log_file: '/var/log/uwsgi/django_base.log',
            pid_file: '/tmp/django_base-uwsgi-master.pid'
        }
    )
    uwsgi_ini = [
        %r(^master-fifo\s+=\s+/tmp/django_base/fifo0$),
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
      expect(chef_run).to render_file('/home/app_user/sites/django_base/conf.d/django_base_uwsgi.ini').with_content(u)
    end
  end

  it 'creates celery pid and log files directory structure' do
    %w(
        /var/log/django_base/celery
        /var/run/django_base
        /var/run/django_base/celery
        ).each do |f|
      expect(chef_run).to create_directory(f).with({
                                                       owner: 'root',
                                                       group: 'root',
                                                       mode: '0700'
                                                   })
    end
  end
end

describe 'django_app_server::django_app' do
  %w(14.04 16.04).each do |version|
    context "When all attributes are default, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version).converge(described_recipe)
      end

      before do
        stub_command('ls /home/app_user/sites/django_base/source/django_base').and_return(false)
      end

      common

    end
  end
end

# TODO: add default and celery is true case

describe 'django_app_server::django_app' do
  %w(14.04 16.04).each do |version|
    context "When git app repo is specified and celery is true, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version) do |node|
          node.set['django_app_server']['git']['app_repo'] = 'https://github.com/globz-eu/django_base.git'
          node.set['django_app_server']['django_app']['celery'] = true
          if version == '14.04'
            node.set['django_app_server']['node_number'] = '000'
          elsif version == '16.04'
            node.set['django_app_server']['node_number'] = '001'
          end
        end.converge(described_recipe)
      end

      before do
        stub_command('ls /home/app_user/sites/django_base/source/django_base').and_return(false)
        stub_command('ls /home/app_user/sites/django_base/scripts').and_return(false)
      end

      common

      app(version)

    end
  end
end

describe 'django_app_server::django_app' do
  %w(14.04 16.04).each do |version|
    context "When git app repo is specified, celery is true and init users is not empty, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version) do |node|
          node.set['django_app_server']['git']['app_repo'] = 'https://github.com/globz-eu/django_base.git'
          node.set['django_app_server']['django_app']['celery'] = true
          if version == '14.04'
            node.set['django_app_server']['node_number'] = '002'
          elsif version == '16.04'
            node.set['django_app_server']['node_number'] = '003'
          end
        end.converge(described_recipe)
      end

      before do
        stub_command('ls /home/app_user/sites/django_base/source/django_base').and_return(false)
        stub_command('ls /home/app_user/sites/django_base/scripts').and_return(false)
      end

      common

      app(version, initial_users: true)

    end
  end
end

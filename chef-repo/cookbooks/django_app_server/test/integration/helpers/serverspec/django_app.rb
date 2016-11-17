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
require 'find'

set :backend, :exec

def django_app_spec(app_name: '', ips: '')
  if os[:family] == 'ubuntu'
    ip_regex = Regexp.escape(ips[os[:release]])

    describe package('git') do
      it { should be_installed }
    end

    # Virtual environment directory structure should be present
    describe file('/home/app_user/.envs') do
      it { should exist }
      it { should be_directory }
      it { should be_owned_by 'app_user' }
      it { should be_grouped_into 'app_user' }
      it { should be_mode 700 }
    end

    if app_name != ''
      # File structure for app should be present
      describe file('/home/app_user/sites') do
        it { should exist }
        it { should be_directory }
        it { should be_owned_by 'app_user' }
        it { should be_grouped_into 'www-data' }
        it { should be_mode 550 }
      end

      describe file("/home/app_user/sites/#{app_name}") do
        it { should exist }
        it { should be_directory }
        it { should be_owned_by 'app_user' }
        it { should be_grouped_into 'www-data' }
        it { should be_mode 550 }
      end

      describe file("/home/app_user/sites/#{app_name}/source") do
        it { should exist }
        it { should be_directory }
        it { should be_owned_by 'app_user' }
        it { should be_grouped_into 'app_user' }
        it { should be_mode 500 }
      end

      # App should be installed
      describe file("/home/app_user/sites/#{app_name}/source/#{app_name}/manage.py") do
        it { should exist }
        it { should be_file }
        it { should be_owned_by 'app_user' }
        it { should be_grouped_into 'app_user' }
        it { should be_mode 400 }
      end

      # check django_base/source ownership and permissions
      Find.find("/home/app_user/sites/#{app_name}/source/#{app_name}") do |f|
        unless f =~ %r(/home/app_user/sites/#{app_name}/source/#{app_name}/\.git/.*) or
            f =~ %r(/home/app_user/sites/#{app_name}/source/#{app_name}/.*__pycache__.*) or
            f =~ %r(/home/app_user/sites/#{app_name}/source/#{app_name}/reports*)
          if FileTest.directory?(f)
            describe file(f) do
              it { should be_directory }
              it { should be_owned_by 'app_user' }
              it { should be_grouped_into 'app_user' }
              it { should be_mode 500 }
            end
          else
            describe file(f) do
              it { should be_file }
              it { should be_owned_by 'app_user' }
              it { should be_grouped_into 'app_user' }
              it { should be_mode 400 }
            end
          end
        end
      end

      # Install scripts should be present
      describe file("/home/app_user/sites/#{app_name}/scripts") do
        it { should exist }
        it { should be_directory }
        it { should be_owned_by 'app_user' }
        it { should be_grouped_into 'app_user' }
        it { should be_mode 500 }
      end

      scripts = ['djangoapp.py']
      scripts.each do |s|
        describe file "/home/app_user/sites/#{app_name}/scripts/#{s}" do
          it { should exist }
          it { should be_file }
          it { should be_owned_by 'app_user' }
          it { should be_grouped_into 'app_user' }
          it { should be_mode 500 }
        end
      end

      describe file "/home/app_user/sites/#{app_name}/scripts/utilities/commandfileutils.py" do
        it { should exist }
        it { should be_file }
        it { should be_owned_by 'app_user' }
        it { should be_grouped_into 'app_user' }
        it { should be_mode 400 }
      end

      # Scripts dependencies should be present
      describe command ('pip3 list | grep psutil') do
        its(:stdout) { should match(/psutil\s+\(\d+\.\d+\.\d+\)/)}
      end

      # fifo directory for django app should be present
      describe file("/tmp/#{app_name}") do
        it { should exist }
        it { should be_directory }
        it { should be_owned_by 'root' }
        it { should be_grouped_into 'root' }
        it { should be_mode 777 }
      end

      # App log directory should be present
      describe(file("/var/log/#{app_name}")) {
        it { should exist }
        it { should be_directory }
        it { should be_owned_by 'root' }
        it { should be_grouped_into 'loggers' }
        it { should be_mode 775 }
      }

      # Virtual env directory for app should be present
      describe file("/home/app_user/.envs/#{app_name}") do
        it { should exist }
        it { should be_directory }
        it { should be_owned_by 'app_user' }
        it { should be_grouped_into 'app_user' }
        it { should be_mode 700 }
      end

      # check .envs/django_base ownership and permissions
      Find.find("/home/app_user/.envs/#{app_name}") { |f|
        unless f =~ %r(/home/app_user/.envs/#{app_name}/lib/.*)
          unless File.symlink?(f)
            if FileTest.directory?(f)
              describe file(f) do
                it { should be_directory }
                it { should be_owned_by 'app_user' }
                it { should be_grouped_into 'app_user' }
              end
            else
              describe file(f) do
                it { should be_file }
                it { should be_owned_by 'app_user' }
                it { should be_grouped_into 'app_user' }
              end
            end
          end
        end
      }

      # Config file for for installation scripts should be present
      describe file("/home/app_user/sites/#{app_name}/scripts/conf.py") do
        params = [
            %r(^DIST_VERSION = '#{os[:release]}'$),
            %r(^LOG_LEVEL = 'DEBUG'$),
            %r(^NGINX_CONF = ''$),
            %r(^APP_HOME = '/home/app_user/sites/#{app_name}/source'$),
            %r(^APP_USER = 'app_user'$),
            %r(^GIT_REPO = 'https://github\.com/globz-eu/#{app_name}\.git'$),
            %r(^CELERY_PID_PATH = '/var/run/#{app_name}/celery'$),
            %r(^VENV = '/home/app_user/\.envs/#{app_name}'$),
            %r(^REQS_FILE = '/home/app_user/sites/#{app_name}/source/#{app_name}/requirements\.txt'$),
            %r(^SYS_DEPS_FILE = '/home/app_user/sites/#{app_name}/source/#{app_name}/system_dependencies\.txt'$),
            %r(^LOG_FILE = '/var/log/#{app_name}/install\.log'$),
            %r(^FIFO_DIR = '/tmp/#{app_name}'$)
        ]
        it { should exist }
        it { should be_file }
        it { should be_owned_by 'app_user' }
        it { should be_grouped_into 'app_user' }
        it { should be_mode 400 }
        params.each do |p|
          its(:content) { should match(p)}
        end
      end

      # conf.d directory for django app should be present
      describe file("/home/app_user/sites/#{app_name}/conf.d") do
        it { should exist }
        it { should be_directory }
        it { should be_owned_by 'app_user' }
        it { should be_grouped_into 'www-data' }
        it { should be_mode 750 }
      end

      # Sockets directory for uWSGI should be present
      describe file("/home/app_user/sites/#{app_name}/sockets") do
        it { should exist }
        it { should be_directory }
        it { should be_owned_by 'app_user' }
        it { should be_grouped_into 'www-data' }
        it { should be_mode 750 }
      end

      if os[:release] == '14.04'
        describe file("/home/app_user/.envs/#{app_name}/lib/python3.4/site-packages/#{app_name}.pth") do
          it { should exist }
          it { should be_file }
          it { should be_owned_by 'app_user' }
          it { should be_grouped_into 'app_user' }
          it { should be_mode 644 }
          its(:content) { should match(/\/home\/app_user\/sites\/#{app_name}\/source/)}
        end
      end

      if os[:release] == '16.04'
        describe file("/home/app_user/.envs/#{app_name}/lib/python3.5/site-packages/#{app_name}.pth") do
          it { should exist }
          it { should be_file }
          it { should be_owned_by 'app_user' }
          it { should be_grouped_into 'app_user' }
          it { should be_mode 644 }
          its(:content) { should match(/\/home\/app_user\/sites\/#{app_name}\/source/)}
        end
      end

      # System dependencies should be installed
      describe package('libxml2-dev') do
        it { should be_installed }
      end

      describe package('libxslt1-dev') do
        it { should be_installed }
      end

      describe package('zlib1g-dev') do
        it { should be_installed }
      end

      describe package('python3-numpy') do
        it { should be_installed }
      end

      # Python packages should be installed
      describe command ("/home/app_user/.envs/#{app_name}/bin/pip3 list") do
        packages = [
            /^Django \(\d+\.\d+\.\d+\)$/,
            /^numpy \(\d+\.\d+\.\d+\)$/,
            /^biopython \(\d+\.\d+\)$/,
            /^lxml \(\d+\.\d+\.\d+\)$/,
            /^psycopg2 \(\d+\.\d+\.\d+\)$/,
        ]
        packages.each do |p|
          its(:stdout) { should match(p)}
        end
      end

      # Django app configuration file should be present
      configuration_files = %W(
      /home/app_user/sites/#{app_name}/conf.d/settings.json
      /home/app_user/sites/#{app_name}/source/#{app_name}/settings.json
      )
      configuration_files.each do |f|
        describe file(f) do
          params = [
              %r(^\s+"SECRET_KEY": "n\)#o5pw7kelvr982iol48tz--n#q!\*8681k3sv0\^\*q#-lddwv!",$),
              %r(^\s+"ALLOWED_HOSTS": \["#{ip_regex}"\],$),
              %r(^\s+"DEBUG": false,$),
              %r(^\s+"DB_ENGINE": "django\.db\.backends\.postgresql_psycopg2",$),
              %r(^\s+"DB_NAME": "#{app_name}",$),
              %r(^\s+"DB_USER": "db_user",$),
              %r(^\s+"DB_PASSWORD": "db_user_password",$),
              %r(^\s+"DB_ADMIN_USER": "postgres",$),
              %r(^\s+"DB_ADMIN_PASSWORD": "postgres_password",$),
              %r(^\s+"DB_HOST": "localhost",$),
              %r(^\s+"TEST_DB_NAME": "test_#{app_name}",$),
              %r(^\s+"BROKER_URL": "redis://localhost:6379/0",$),
              %r(^\s+"CELERY_RESULT_BACKEND": "redis://localhost:6379/0",$),
              %r(^\s+"SECURE_SSL_REDIRECT": false,$),
              %r(^\s+"SECURE_PROXY_SSL_HEADER": \[\],$),
              %r(^\s+"CHROME_DRIVER": "",$),
              %r(^\s+"FIREFOX_BINARY": "",$),
              %r(^\s+"TEST": "functional",$),
              %r(^\s+"SERVER_URL": "liveserver",$),
              %r(^\s+"INITIAL_USERS": \[$),
              %r(^\s+\["user0", "user0@example\.com", "user0_password"\],$),
              %r(^\s+\["user1", "user1@example\.com", "user1_password"\]$),
              %r(^\s+"INITIAL_SUPERUSER": \["superuser", "superuser@example\.com", "superuser_password"\],$),
              %r(^\s+"HEROKU": false$),
          ]
          it { should exist }
          it { should be_file }
          it { should be_owned_by 'app_user' }
          it { should be_grouped_into 'app_user' }
          it { should be_mode 400 }
          params.each do |p|
            its(:content) { should match(p)}
          end
        end
      end

      # Behave configuration file for functional tests is present
      behave_conf_files = %W(
      /home/app_user/sites/#{app_name}/conf.d/behave.ini
      /home/app_user/sites/#{app_name}/source/#{app_name}/behave.ini
      )
      behave_conf_files.each do |f|
        describe file(f) do
          it { should exist }
          it { should be_file }
          it { should be_owned_by 'app_user' }
          it { should be_grouped_into 'app_user' }
          it { should be_mode 400 }
          its(:content) { should match(%r(^paths=functional_tests/features$))}
        end
      end

      # Django app configuration file for admin tasks should be present
      describe file("/home/app_user/sites/#{app_name}/source/#{app_name}/settings_admin.py") do
        it { should exist }
        it { should be_file }
        it { should be_owned_by 'app_user' }
        it { should be_grouped_into 'app_user' }
        it { should be_mode 400 }
      end

      # uWSGI ini file should be present
      uwsgi_conf_files = %W(
      /home/app_user/sites/#{app_name}/conf.d/#{app_name}_uwsgi.ini
      /home/app_user/sites/#{app_name}/source/#{app_name}_uwsgi.ini
      )
      uwsgi_conf_files.each do |f|
        describe file(f) do
          params = [
              %r(^master-fifo\s+=\s+/tmp/#{app_name}/fifo0$),
              %r(^# #{app_name}_uwsgi\.ini file$),
              %r(^chdir = /home/app_user/sites/#{app_name}/source/#{app_name}),
              %r(^module = #{app_name}\.wsgi$),
              %r(^home = /home/app_user/\.envs/#{app_name}$),
              %r(^uid = app_user$),
              %r(^gid = www-data$),
              %r(^processes = 2$),
              %r(^socket = /home/app_user/sites/#{app_name}/sockets/#{app_name}\.sock$),
              %r(^chmod-socket = 660$),
              %r(^daemonize = /var/log/uwsgi/#{app_name}\.log$),
              %r(^safe-pidfile = /tmp/#{app_name}-uwsgi-master\.pid$)
          ]
          it { should exist }
          it { should be_file }
          it { should be_owned_by 'app_user' }
          it { should be_grouped_into 'app_user' }
          it { should be_mode 400 }
          params.each do |p|
            its(:content) { should match(p)}
          end
        end
      end
    end

  end
end

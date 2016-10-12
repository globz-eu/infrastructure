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

if os[:family] == 'ubuntu'
  describe package('git') do
    it { should be_installed }
  end

  # File structure for app should be present
  describe file('/home/app_user/sites') do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'app_user' }
    it { should be_grouped_into 'www-data' }
    it { should be_mode 550 }
  end

  describe file('/home/app_user/sites/formalign') do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'app_user' }
    it { should be_grouped_into 'www-data' }
    it { should be_mode 550 }
  end

  describe file('/home/app_user/sites/formalign/source') do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'app_user' }
    it { should be_grouped_into 'app_user' }
    it { should be_mode 500 }
  end

  # App should be installed
  describe file('/home/app_user/sites/formalign/source/formalign/manage.py') do
    it { should exist }
    it { should be_file }
    it { should be_owned_by 'app_user' }
    it { should be_grouped_into 'app_user' }
    it { should be_mode 400 }
  end

  # check formalign/source ownership and permissions
  Find.find('/home/app_user/sites/formalign/source/formalign') do |f|
    unless f =~ %r(/home/app_user/sites/formalign/source/formalign/\.git/.*) or
    f =~ %r(/home/app_user/sites/formalign/source/formalign/.*__pycache__.*) or
    f =~ %r(/home/app_user/sites/formalign/source/formalign/reports*)
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
  describe file('/home/app_user/sites/formalign/scripts') do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'app_user' }
    it { should be_grouped_into 'app_user' }
    it { should be_mode 500 }
  end

  scripts = ['djangoapp.py']
  scripts.each do |s|
    describe file "/home/app_user/sites/formalign/scripts/#{s}" do
      it { should exist }
      it { should be_file }
      it { should be_owned_by 'app_user' }
      it { should be_grouped_into 'app_user' }
      it { should be_mode 500 }
    end
  end

  describe file '/home/app_user/sites/formalign/scripts/utilities/commandfileutils.py' do
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
  describe file('/tmp/formalign') do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    it { should be_mode 777 }
  end

  # App log directory should be present
  describe file('/var/log/formalign') do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    it { should be_mode 755 }
  end

  # Virtual environment directory structure should be present
  describe file('/home/app_user/.envs') do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'app_user' }
    it { should be_grouped_into 'app_user' }
    it { should be_mode 500 }
  end

  describe file('/home/app_user/.envs/formalign') do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'app_user' }
    it { should be_grouped_into 'app_user' }
    it { should be_mode 500 }
  end

  # check .envs/formalign ownership and permissions
  Find.find('/home/app_user/.envs/formalign') do |f|
    unless f =~ %r(/home/app_user/.envs/formalign/lib/.*)
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
  end

  # Config file for for installation scripts should be present
  describe file('/home/app_user/sites/formalign/scripts/conf.py') do
    params = [
        %r(^DIST_VERSION = '#{os[:release]}'$),
        %r(^DEBUG = 'DEBUG'$),
        %r(^NGINX_CONF = ''$),
        %r(^APP_HOME = '/home/app_user/sites/formalign/source'$),
        %r(^APP_USER = 'app_user'$),
        %r(^GIT_REPO = 'https://github\.com/globz-eu/formalign\.git'$),
        %r(^CELERY_PID_PATH = '/var/run/formalign/celery'$),
        %r(^VENV = '/home/app_user/\.envs/formalign'$),
        %r(^REQS_FILE = '/home/app_user/sites/formalign/source/formalign/requirements\.txt'$),
        %r(^SYS_DEPS_FILE = '/home/app_user/sites/formalign/source/formalign/system_dependencies\.txt'$),
        %r(^LOG_FILE = '/var/log/formalign/install\.log'$)
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
  describe file('/home/app_user/sites/formalign/conf.d') do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'app_user' }
    it { should be_grouped_into 'www-data' }
    it { should be_mode 750 }
  end

  # Sockets directory for uWSGI should be present
  describe file('/home/app_user/sites/formalign/sockets') do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'app_user' }
    it { should be_grouped_into 'www-data' }
    it { should be_mode 750 }
  end

  if os[:release] == '14.04'
    describe file('/home/app_user/.envs/formalign/lib/python3.4/formalign.pth') do
      it { should exist }
      it { should be_file }
      it { should be_owned_by 'app_user' }
      it { should be_grouped_into 'app_user' }
      it { should be_mode 644 }
      its(:content) { should match(/\/home\/app_user\/sites\/formalign\/source/)}
    end
  end

  if os[:release] == '16.04'
    describe file('/home/app_user/.envs/formalign/lib/python3.5/formalign.pth') do
      it { should exist }
      it { should be_file }
      it { should be_owned_by 'app_user' }
      it { should be_grouped_into 'app_user' }
      it { should be_mode 644 }
      its(:content) { should match(/\/home\/app_user\/sites\/formalign\/source/)}
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
  describe command ( '/home/app_user/.envs/formalign/bin/pip3 list' ) do
    packages = [
        /^Django \(1\.9\.7\)$/,
        /^numpy \(1\.11\.1\)$/,
        /^biopython \(1\.67\)$/,
        /^lxml \(3\.6\.0\)$/,
        /^psycopg2 \(2\.6\.1\)$/,
    ]
    packages.each do |p|
      its(:stdout) { should match(p)}
    end
  end

  # Django app configuration file should be present
  configuration_files = %w(
  /home/app_user/sites/formalign/conf.d/configuration.py
  /home/app_user/sites/formalign/source/formalign/configuration.py
  )
  configuration_files.each do |f|
    describe file(f) do
      if os[:release] == '14.04'
        params = [
            %r(^SECRET_KEY = 'n\)#o5pw7kelvr982iol48tz--n#q!\*8681k3sv0\^\*q#-lddwv!'$),
            %r(ALLOWED_HOSTS = \['192\.168\.1\.85'\]$),
            %r(^\s+'PASSWORD': "db_user_password",$),
            %r(^DEBUG = False$),
            %r(^\s+'ENGINE': 'django\.db\.backends\.postgresql_psycopg2',$),
            %r(^\s+'NAME': 'formalign',$),
            %r(^\s+'USER': 'db_user',$),
            %r(^\s+'HOST': 'localhost',$),
            %r(^\s+'NAME': 'test_formalign',$)
        ]
      elsif os[:release] == '16.04'
        params = [
            %r(^SECRET_KEY = 'n\)#o5pw7kelvr982iol48tz--n#q!\*8681k3sv0\^\*q#-lddwv!'$),
            %r(ALLOWED_HOSTS = \['192\.168\.1\.86'\]$),
            %r(^\s+'PASSWORD': "db_user_password",$),
            %r(^DEBUG = False$),
            %r(^\s+'ENGINE': 'django\.db\.backends\.postgresql_psycopg2',$),
            %r(^\s+'NAME': 'formalign',$),
            %r(^\s+'USER': 'db_user',$),
            %r(^\s+'HOST': 'localhost',$),
            %r(^\s+'NAME': 'test_formalign',$)
        ]
      end
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

  # Django app configuration file for admin tasks should be present
  settings_admin_files = %w(
  /home/app_user/sites/formalign/source/formalign/formalign/settings_admin.py
  /home/app_user/sites/formalign/conf.d/settings_admin.py
  )
  settings_admin_files.each do |f|
    describe file(f) do
      params = [
          %r(^from formalign.settings import \*$),
          %r(^\s+'USER': 'postgres',$),
          %r(^\s+'PASSWORD': "postgres_password",$),
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

  # uWSGI ini file should be present
  uwsgi_conf_files = %w(
  /home/app_user/sites/formalign/conf.d/formalign_uwsgi.ini
  /home/app_user/sites/formalign/source/formalign_uwsgi.ini
  )
  uwsgi_conf_files.each do |f|
    describe file(f) do
      params = [
          %r(^master-fifo\s+=\s+/tmp/formalign/fifo0$),
          %r(^# formalign_uwsgi\.ini file$),
          %r(^chdir = /home/app_user/sites/formalign/source/formalign$),
          %r(^module = formalign\.wsgi$),
          %r(^home = /home/app_user/\.envs/formalign$),
          %r(^uid = app_user$),
          %r(^gid = www-data$),
          %r(^processes = 2$),
          %r(^socket = /home/app_user/sites/formalign/sockets/formalign\.sock$),
          %r(^chmod-socket = 660$),
          %r(^daemonize = /var/log/uwsgi/formalign\.log$),
          %r(^safe-pidfile = /tmp/formalign-uwsgi-master\.pid$)
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
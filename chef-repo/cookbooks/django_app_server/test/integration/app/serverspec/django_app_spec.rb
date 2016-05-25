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

  describe file('/home/app_user/sites/django_base') do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'app_user' }
    it { should be_grouped_into 'www-data' }
    it { should be_mode 550 }
  end

  describe file('/home/app_user/sites/django_base/source') do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'app_user' }
    it { should be_grouped_into 'app_user' }
    it { should be_mode 500 }
  end

  # App should be installed
  describe file('/home/app_user/sites/django_base/source/django_base/manage.py') do
    it { should exist }
    it { should be_file }
    it { should be_owned_by 'app_user' }
    it { should be_grouped_into 'app_user' }
    it { should be_mode 400 }
  end

  # TODO: verify source/file and source/directory permissions

  # Install scripts should be present
  describe file('/home/app_user/sites/django_base/scripts') do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'app_user' }
    it { should be_grouped_into 'app_user' }
    it { should be_mode 500 }
  end

  files = [
      '/home/app_user/sites/django_base/scripts/install_django_app_trusty.py',
      '/home/app_user/sites/django_base/scripts/install_django_app_xenial.py'
  ]
  files.each do |f|
    describe file(f) do
      it { should exist }
      it { should be_file }
      it { should be_owned_by 'app_user' }
      it { should be_grouped_into 'app_user' }
      it { should be_mode 500 }
    end
  end

  # App log directory should be present
  describe file('/var/log/django_base') do
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

  # TODO: verify presence of venv and ownership and permissions

  # Config file for for installation scripts should be present
  describe file('/home/app_user/sites/django_base/scripts/install_django_app_conf.py') do
    params = [
        %r(^DEBUG = False$),
        %r(^APP_HOME = '/home/app_user/sites/django_base/source'$),
        %r(^APP_USER = 'app_user'$),
        %r(^GIT_REPO = 'https://github\.com/globz-eu/django_base\.git'$),
        %r(^VENV = '/home/app_user/\.envs/django_base'$),
        %r(^REQS_FILE = '/home/app_user/sites/django_base/source/django_base/requirements\.txt'$),
        %r(^SYS_DEPS_FILE = '/home/app_user/sites/django_base/source/django_base/system_dependencies\.txt'$),
        %r(^LOG_FILE = '/var/log/django_base/install\.log'$)
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

  # Static, media and conf.d directories for django app should be present
  describe file('/home/app_user/sites/django_base/static') do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'app_user' }
    it { should be_grouped_into 'www-data' }
    it { should be_mode 750 }
  end

  describe file('/home/app_user/sites/django_base/media') do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'app_user' }
    it { should be_grouped_into 'www-data' }
    it { should be_mode 750 }
  end

  describe file('/home/app_user/sites/django_base/conf.d') do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'app_user' }
    it { should be_grouped_into 'www-data' }
    it { should be_mode 750 }
  end

  # Sockets directory for uWSGI should be present
  describe file('/home/app_user/sites/django_base/sockets') do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'app_user' }
    it { should be_grouped_into 'www-data' }
    it { should be_mode 750 }
  end

  if os[:release] == '14.04'
    describe file('/home/app_user/.envs/django_base/lib/python3.4/django_base.pth') do
      it { should exist }
      it { should be_file }
      it { should be_owned_by 'app_user' }
      it { should be_grouped_into 'app_user' }
      it { should be_mode 644 }
      its(:content) { should match(/\/home\/app_user\/sites\/django_base\/source/)}
    end
  end

  if os[:release] == '16.04'
    describe file('/home/app_user/.envs/django_base/lib/python3.5/django_base.pth') do
      it { should exist }
      it { should be_file }
      it { should be_owned_by 'app_user' }
      it { should be_grouped_into 'app_user' }
      it { should be_mode 644 }
      its(:content) { should match(/\/home\/app_user\/sites\/django_base\/source/)}
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
  describe command ( '/home/app_user/.envs/django_base/bin/pip3 list' ) do
    packages = [
        /^Django \(1\.9\.5\)$/,
        /^numpy \(1\.11\.0\)$/,
        /^biopython \(1\.66\)$/,
        /^lxml \(3\.6\.0\)$/,
        /^psycopg2 \(2\.6\.1\)$/,
    ]
    packages.each do |p|
      its(:stdout) { should match(p)}
    end
  end

  # Django app configuration file should be present
  configuration_files = [
      '/home/app_user/sites/django_base/conf.d/configuration.py',
      '/home/app_user/sites/django_base/source/django_base/configuration.py'
  ]
  configuration_files.each do |f|
    describe file(f) do
      if os[:release] == '14.04'
        params = [
            %r(^SECRET_KEY = 'n\)#o5pw7kelvr982iol48tz--n#q!\*8681k3sv0\^\*q#-lddwv!'$),
            %r(ALLOWED_HOSTS = \['192\.168\.122\.11'\]$),
            %r(^\s+'PASSWORD': "db_user_password",$),
            %r(^DEBUG = False$),
            %r(^\s+'ENGINE': 'django\.db\.backends\.postgresql_psycopg2',$),
            %r(^\s+'NAME': 'django_base',$),
            %r(^\s+'USER': 'db_user',$),
            %r(^\s+'HOST': 'localhost',$),
            %r(^\s+'NAME': 'test_django_base',$)
        ]
      elsif os[:release] == '16.04'
        params = [
            %r(^SECRET_KEY = 'n\)#o5pw7kelvr982iol48tz--n#q!\*8681k3sv0\^\*q#-lddwv!'$),
            %r(ALLOWED_HOSTS = \['192\.168\.122\.12'\]$),
            %r(^\s+'PASSWORD': "db_user_password",$),
            %r(^DEBUG = False$),
            %r(^\s+'ENGINE': 'django\.db\.backends\.postgresql_psycopg2',$),
            %r(^\s+'NAME': 'django_base',$),
            %r(^\s+'USER': 'db_user',$),
            %r(^\s+'HOST': 'localhost',$),
            %r(^\s+'NAME': 'test_django_base',$)
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
  settings_admin_files = [
      '/home/app_user/sites/django_base/source/django_base/django_base/settings_admin.py',
      '/home/app_user/sites/django_base/conf.d/settings_admin.py'
  ]
  settings_admin_files.each do |f|
    describe file(f) do
      params = [
          %r(^from django_base.settings import \*$),
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
  describe file('/home/app_user/sites/django_base/source/django_base_uwsgi.ini') do
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
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
# Server Spec:: python

require 'spec_helper'

set :backend, :exec

describe package('python3') do
  it { should be_installed }
end

describe package('python3-pip') do
  it { should be_installed }
end

describe package('python3.4-dev') do
  it { should be_installed }
end

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

describe command ( 'pip3 list' ) do
  its(:stdout) { should match(/virtualenv/)}
  its(:stdout) { should match(/uWSGI/)}
end

describe command ( '/home/app_user/.envs/app_name/bin/pip3 list' ) do
  its(:stdout) { should match(/Django/)}
end

describe file('/home/app_user/.envs') do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by 'app_user' }
  it { should be_grouped_into 'app_user' }
  it { should be_mode 750 }
end

describe file('/home/app_user/.envs/app_name') do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by 'app_user' }
  it { should be_grouped_into 'app_user' }
  it { should be_mode 750 }
end

describe file('/home/app_user/.envs/app_name/lib/python3.4/app_name.pth') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'app_user' }
  it { should be_grouped_into 'app_user' }
  it { should be_mode 400 }
  its(:content) { should match(/\/home\/app_user\/sites\/app_name\/source/)}
end

describe file('/home/app_user/sites') do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by 'app_user' }
  it { should be_grouped_into 'www-data' }
  it { should be_mode 750 }
end

describe file('/home/app_user/sites/app_name') do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by 'app_user' }
  it { should be_grouped_into 'www-data' }
  it { should be_mode 750 }
end

describe file('/home/app_user/sites/app_name/source') do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by 'app_user' }
  it { should be_grouped_into 'app_user' }
  it { should be_mode 750 }
end

describe file('/home/app_user/sites/app_name/static') do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by 'app_user' }
  it { should be_grouped_into 'www-data' }
  it { should be_mode 750 }
end

describe file('/home/app_user/sites/app_name/source/manage.py') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'app_user' }
  it { should be_grouped_into 'app_user' }
  it { should be_mode 750 }
end

describe file('/home/app_user/sites/app_name/source/configuration.py') do
  params = [
      "SECRET_KEY = 'n)#o5pw7kelvr982iol48tz--n#q!*8681k3sv0^*q#-lddwv!'",
      "ALLOWED_HOSTS = ['192.168.1.81']",
      'PG_PASSWORD = "db_user_password"',
      'DEBUG = False',
      "'ENGINE': 'django.db.backends.postgresql_psycopg2'",
      "'NAME': 'app_name'",
      "'USER': 'db_user'",
      "'HOST': 'localhost'",
      "'NAME': 'test_app_name'"
  ]
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'app_user' }
  it { should be_grouped_into 'app_user' }
  it { should be_mode 400 }
  params.each do |p|
    its(:content) { should match(Regexp.escape(p))}
  end
end

describe command ( "su - app_user -c 'cd && .envs/app_name/bin/python sites/app_name/source/manage.py makemigrations'" ) do
  its(:stdout) { should match(/No changes detected/)}
end

describe command ( "su - app_user -c 'cd && .envs/app_name/bin/python sites/app_name/source/manage.py migrate'" ) do
  its(:stdout) { should match(/No migrations to apply\./)}
end

describe file('/home/app_user/sites/app_name/source/app_name_uwsgi.ini') do
  params = [
      'chdir = /home/app_user/sites/app_name/source',
      'module = app_name.wsgi',
      'home = /home/app_user/.envs/app_name',
      'processes = 2',
      'socket = /home/app_user/sites/app_name/sockets/app_name.sock',
      'chmod-socket = 660',
      'daemonize = /var/log/uwsgi/app_name.log',
      'master-fifo = /tmp/fifo0'
  ]
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'app_user' }
  it { should be_grouped_into 'app_user' }
  it { should be_mode 400 }
  params.each do |p|
    its(:content) { should match(Regexp.escape(p))}
  end
end
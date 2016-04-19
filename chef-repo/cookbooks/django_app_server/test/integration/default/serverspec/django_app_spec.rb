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

describe file('/home/app_user/sites/django_base/sockets') do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by 'app_user' }
  it { should be_grouped_into 'www-data' }
  it { should be_mode 750 }
end

describe file('/home/app_user/.envs/django_base/lib/python3.4/django_base.pth') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'app_user' }
  it { should be_grouped_into 'app_user' }
  it { should be_mode 400 }
  its(:content) { should match(/\/home\/app_user\/sites\/django_base\/source/)}
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

describe command ( '/home/app_user/.envs/django_base/bin/pip3 list' ) do
  packages = [
      'Django (1.9)',
      'numpy (1.11.0)',
      'biopython (1.66)',
      'lxml (3.5.0)',
  ]
  packages.each do |p|
    its(:stdout) { should match(Regexp.escape(p))}
  end
end

describe file('/home/app_user/sites/django_base/source/configuration.py') do
  params = [
      "SECRET_KEY = 'n)#o5pw7kelvr982iol48tz--n#q!*8681k3sv0^*q#-lddwv!'",
      "ALLOWED_HOSTS = ['192.168.1.81']",
      '"PASSWORD": "db_user_password"',
      'DEBUG = False',
      "'ENGINE': 'django.db.backends.postgresql_psycopg2'",
      "'NAME': 'django_base'",
      "'USER': 'db_user'",
      "'HOST': 'localhost'",
      "'NAME': 'test_django_base'"
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

describe file('/home/app_user/sites/django_base/source/django_base/settings_admin.py') do
  params = [
      'from django_base.settings import *',
      "'USER': 'postgres'",
      '"PASSWORD": "postgres_password"',
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

describe command ( "su - app_user -c 'cd && .envs/django_base/bin/python sites/django_base/source/manage.py makemigrations'" ) do
  its(:stdout) { should match(/No changes detected/)}
end

describe command ( "su - app_user -c 'cd && .envs/django_base/bin/python sites/django_base/source/manage.py migrate'" ) do
  its(:stdout) { should match(/No migrations to apply\./)}
end

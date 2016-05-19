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

describe package('git') do
  it { should be_installed }
end

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

describe file('/home/app_user/sites/django_base/source/django_base/manage.py') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'app_user' }
  it { should be_grouped_into 'app_user' }
  it { should be_mode 400 }
end

# describe file('/home/app_user/sites/django_base/static') do
#   it { should exist }
#   it { should be_directory }
#   it { should be_owned_by 'app_user' }
#   it { should be_grouped_into 'www-data' }
#   it { should be_mode 750 }
# end
#
# describe file('/home/app_user/sites/django_base/media') do
#   it { should exist }
#   it { should be_directory }
#   it { should be_owned_by 'app_user' }
#   it { should be_grouped_into 'www-data' }
#   it { should be_mode 750 }
# end
#
# describe file('/home/app_user/sites/django_base/sockets') do
#   it { should exist }
#   it { should be_directory }
#   it { should be_owned_by 'app_user' }
#   it { should be_grouped_into 'www-data' }
#   it { should be_mode 750 }
# end
#
# describe file('/home/app_user/.envs/django_base/lib/python3.4/django_base.pth') do
#   it { should exist }
#   it { should be_file }
#   it { should be_owned_by 'app_user' }
#   it { should be_grouped_into 'app_user' }
#   it { should be_mode 400 }
#   its(:content) { should match(/\/home\/app_user\/sites\/django_base\/source/)}
# end
#
# describe package('libxml2-dev') do
#   it { should be_installed }
# end
#
# describe package('libxslt1-dev') do
#   it { should be_installed }
# end
#
# describe package('zlib1g-dev') do
#   it { should be_installed }
# end
#
# describe package('python3-numpy') do
#   it { should be_installed }
# end
#
# describe command ( '/home/app_user/.envs/django_base/bin/pip3 list' ) do
#   packages = [
#       /^Django \(1\.9\.5\)$/,
#       /^numpy \(1\.11\.0\)$/,
#       /^biopython \(1\.66\)$/,
#       /^lxml \(3\.6\.0\)$/,
#       /^psycopg2 \(2\.6\.1\)$/,
#   ]
#   packages.each do |p|
#     its(:stdout) { should match(p)}
#   end
# end
#
# describe file('/home/app_user/sites/django_base/source/django_base/configuration.py') do
#   params = [
#       "SECRET_KEY = 'n)#o5pw7kelvr982iol48tz--n#q!*8681k3sv0^*q#-lddwv!'",
#       "ALLOWED_HOSTS = ['192.168.1.81']",
#       '"PASSWORD": "db_user_password"',
#       'DEBUG = False',
#       "'ENGINE': 'django.db.backends.postgresql_psycopg2'",
#       "'NAME': 'django_base'",
#       "'USER': 'db_user'",
#       "'HOST': 'localhost'",
#       "'NAME': 'test_django_base'"
#   ]
#   it { should exist }
#   it { should be_file }
#   it { should be_owned_by 'app_user' }
#   it { should be_grouped_into 'app_user' }
#   it { should be_mode 400 }
#   params.each do |p|
#     its(:content) { should match(Regexp.escape(p))}
#   end
# end
#
# describe file('/home/app_user/sites/django_base/source/django_base/django_base/settings_admin.py') do
#   params = [
#       'from django_base.settings import *',
#       "'USER': 'postgres'",
#       '"PASSWORD": "postgres_password"',
#   ]
#   it { should exist }
#   it { should be_file }
#   it { should be_owned_by 'app_user' }
#   it { should be_grouped_into 'app_user' }
#   it { should be_mode 400 }
#   params.each do |p|
#     its(:content) { should match(Regexp.escape(p))}
#   end
# end
#
# describe file('/home/app_user/sites/django_base/source/install_dependencies.py') do
#   it { should exist }
#   it { should be_file }
#   it { should be_owned_by 'app_user' }
#   it { should be_grouped_into 'app_user' }
#   it { should be_mode 500 }
#   its(:content) { should match(%r(^path = '/home/app_user/sites/django_base/source/django_base/system_dependencies\.txt'$))}
# end
#
# describe command ( 'cd /home/app_user/sites/django_base/source/django_base && /home/app_user/.envs/django_base/bin/python ./manage.py makemigrations --settings django_base.settings_admin' ) do
#   its(:stdout) { should match(/No changes detected/)}
# end
#
# describe command ( 'cd /home/app_user/sites/django_base/source/django_base && /home/app_user/.envs/django_base/bin/python ./manage.py migrate --settings django_base.settings_admin' ) do
#   # should return Connection refused since postgresql is not installed and database is not configured
#   its(:stderr) { should match(/could not connect to server: Connection refused/)}
# end

# describe file('/home/app_user/sites/django_base/source/django_base_uwsgi.ini') do
#   params = [
#       /^# django_base_uwsgi.ini file$/,
#       %r(^chdir\s+=\s+/home/app_user/sites/django_base/source/django_base$),
#       /^module\s+=\s+django_base\.wsgi$/,
#       %r(^home\s+=\s+/home/app_user/\.envs/django_base$),
#       /^uid\s+=\s+app_user$/,
#       /^gid\s+=\s+www-data$/,
#       /^processes\s+=\s+2$/,
#       %r(^socket = /home/app_user/sites/django_base/sockets/django_base\.sock$),
#       /^chmod-socket\s+=\s+660$/,
#       %r(^daemonize\s+=\s+/var/log/uwsgi/django_base\.log$),
#       %r(^master-fifo\s+=\s+/tmp/fifo0$)
#   ]
#   it { should exist }
#   it { should be_file }
#   it { should be_owned_by 'app_user' }
#   it { should be_grouped_into 'app_user' }
#   it { should be_mode 400 }
#   params.each do |p|
#     its(:content) { should match(p)}
#   end
# end
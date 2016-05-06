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
# Server Spec:: reinstall_app

require 'spec_helper'

set :backend, :exec

# converges successfully
describe file('/var/log/chef-kitchen/chef-client.log') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_mode 644 }
  its(:content) { should_not match(/ERROR/)}
  its(:content) { should_not match(/FATAL/)}
end

describe file('/home/app_user/sites/django_base/tmp') do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by 'app_user' }
  it { should be_grouped_into 'app_user' }
  it { should be_mode 750 }
end

describe file('/home/app_user/sites/django_base/tmp/configuration.py') do
  params = [
      "SECRET_KEY = 'n)#o5pw7kelvr982iol48tz--n#q!*8681k3sv0^*q#-lddwv!'",
      "ALLOWED_HOSTS = ['192.168.1.84']",
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

describe file('/home/app_user/sites/django_base/tmp/settings_admin.py') do
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

describe file('/home/app_user/sites/django_base/tmp/install_dependencies.py') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'app_user' }
  it { should be_grouped_into 'app_user' }
  it { should be_mode 500 }
  its(:content) { should match(%r(^path = '/home/app_user/sites/django_base/source/django_base/system_dependencies\.txt'$))}
end

describe file('/home/app_user/sites/django_base/tmp/django_base_uwsgi.ini') do
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

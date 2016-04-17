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

describe command ( 'pip3 list' ) do
  its(:stdout) { should match(/uWSGI/)}
end

describe file('/var/log/uwsgi') do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_mode 755 }
end

describe file('/home/app_user/sites/django_base/source/django_base_uwsgi.ini') do
  params = [
      'chdir = /home/app_user/sites/django_base/source',
      'module = django_base.wsgi',
      'home = /home/app_user/.envs/django_base',
      'processes = 2',
      'socket = /home/app_user/sites/django_base/sockets/django_base.sock',
      'chmod-socket = 660',
      'daemonize = /var/log/uwsgi/django_base.log',
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

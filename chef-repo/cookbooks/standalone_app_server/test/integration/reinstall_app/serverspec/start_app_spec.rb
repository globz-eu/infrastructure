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
# Cookbook:: standalone_app_server
# Server Spec:: start_app

require 'spec_helper'

set :backend, :exec

# manages migrations
describe command ( "su - app_user -c 'cd && .envs/django_base/bin/python sites/django_base/source/django_base/manage.py makemigrations'" ) do
  its(:stdout) { should match(/No changes detected/)}
end

describe command ( "su - app_user -c 'cd && .envs/django_base/bin/python sites/django_base/source/django_base/manage.py migrate'" ) do
  its(:stdout) { should match(/No migrations to apply\./)}
end

# runs app tests
describe file('/var/log/django_base') do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_mode 700 }
end

describe file('/var/log/django_base/test_results') do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_mode 700 }
end

describe command('ls /var/log/django_base/test_results | head -1 ') do
  its(:stdout) { should match(/^test_\d{2}-\d{2}-\d{2}-\d{6}\.log$/)}
end

describe command('cat $(ls /var/log/django_base/test_results | head -1) | grep FAILED') do
  its(:stdout) { should_not match(/FAILED/)}
end

# uwsgi is running
describe command ( 'pgrep uwsgi' ) do
  its(:stdout) { should match(/^\d+$/) }
end

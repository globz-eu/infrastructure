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
describe command ( "su - app_user -c 'cd && .envs/formalign/bin/python sites/formalign/source/formalign/manage.py makemigrations'" ) do
  its(:stdout) { should match(/No changes detected/)}
end

describe command ( "su - app_user -c 'cd && .envs/formalign/bin/python sites/formalign/source/formalign/manage.py migrate'" ) do
  its(:stdout) { should match(/No migrations to apply\./)}
end

# runs app tests
describe file('/var/log/formalign') do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_mode 755 }
end

describe file('/var/log/formalign/test_results') do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_mode 700 }
end

# Runs app tests
describe command('ls /var/log/formalign/test_results | tail -1 ') do
  its(:stdout) { should match(/^test_\d{8}-\d{6}\.log$/)}
end

describe command('cat $(ls /var/log/formalign/test_results | tail -1) | grep FAILED') do
  its(:stdout) { should_not match(/FAILED/)}
end

# nginx is running and site is enabled
describe file('/etc/nginx/sites-enabled/formalign.conf') do
  it { should exist }
  it { should be_symlink }
  it { should be_owned_by 'root'}
  it { should be_grouped_into 'root' }
  its(:content) { should match (/^# formalign.conf$/) }
end

describe file('/etc/nginx/sites-enabled/formalign_down.conf') do
  it { should_not exist }
end

describe service('nginx') do
  it { should be_enabled }
  it { should be_running }
end

# uwsgi is running
describe command ( 'pgrep uwsgi' ) do
  its(:stdout) { should match(/^\d+$/) }
end

# site is up
if os[:release] == '14.04'
  describe command('curl 192.168.1.85') do
    its(:stdout) {should match(%r(^\s+<title id="head-title">Formalign\.eu Home</title>$))}
  end
elsif os[:release] == '16.04'
  describe command('curl 192.168.1.86') do
    its(:stdout) {should match(%r(^\s+<title id="head-title">Formalign\.eu Home</title>$))}
  end
end

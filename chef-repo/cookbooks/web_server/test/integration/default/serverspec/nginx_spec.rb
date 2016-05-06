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
# Cookbook:: web_server
# Server Spec:: nginx


require 'serverspec'

set :backend, :exec

expected_rules = [
    %r{^\[(\s|\d)\d\]\s+22/tcp\s+ALLOW IN\s+Anywhere\s+$},
    %r{^\[(\s|\d)\d\]\s+80/tcp\s+ALLOW IN\s+Anywhere\s+$},
    %r{^\[(\s|\d)\d\]\s+22/tcp\s+\(v6\)\s+ALLOW IN\s+Anywhere\s+\(v6\)\s+$},
    %r{^\[(\s|\d)\d\]\s+80/tcp\s+\(v6\)\s+ALLOW IN\s+Anywhere\s+\(v6\)\s+$},
    %r{^\[(\s|\d)\d\]\s+22,53,80,443/tcp\s+ALLOW OUT\s+Anywhere\s+\(out\)$},
    %r{^\[(\s|\d)\d\]\s+53,67,68/udp\s+ALLOW OUT\s+Anywhere\s+\(out\)$},
    %r{^\[(\s|\d)\d\]\s+22,53,80,443/tcp\s+\(v6\)\s+ALLOW OUT\s+Anywhere\s+\(v6\)\s+\(out\)$},
    %r{^\[(\s|\d)\d\]\s+53,67,68/udp\s+\(v6\)\s+ALLOW OUT\s+Anywhere\s+\(v6\)\s+\(out\)$}
]

describe command( 'ufw status numbered' ) do
  its(:stdout) { should match(/Status: active/) }
  expected_rules.each do |r|
    its(:stdout) { should match(r) }
  end
end

describe package('nginx') do
  it { should be_installed }
end

describe service('nginx') do
  it { should be_enabled }
  # service should fail to restart since django_base.conf contains references to files that do not exist
  it { should_not be_running }
end

describe file('/etc/nginx/sites-available/django_base.conf') do
  params = [
      /^# django_base.conf$/,
      %r(^\s+server unix:///home/app_user/sites/django_base/sockets/django_base\.sock; # for a file socket$),
      /^\s+# server 127\.0\.0\.1:8001; # for a web port socket/,
      /^\s+listen\s+80;$/,
      /^\s+server_name\s+192\.168\.1\.81;$/,
      %r(^\s+alias /home/app_user/sites/django_base/media;),
      %r(^\s+alias /home/app_user/sites/django_base/static;),
      %r(^\s+include\s+/home/app_user/sites/django_base/source/django_base/uwsgi_params;$)
  ]
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_mode 400 }
  params.each do |p|
    its(:content) { should match(p) }
  end
end

describe file('/etc/nginx/sites-enabled/django_base.conf') do
  it { should exist }
  it { should be_symlink }
  it { should be_owned_by 'root'}
  it { should be_grouped_into 'root' }
  its(:content) { should match (/^# django_base.conf$/) }
end

describe file('/etc/nginx/sites-enabled/default') do
  it { should_not exist }
end

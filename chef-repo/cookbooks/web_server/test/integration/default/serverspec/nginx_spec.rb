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


require 'serverspec'

set :backend, :exec

expected_rules = [
    %r{ 22/tcp + ALLOW IN + Anywhere},
    %r{ 80/tcp + ALLOW IN + Anywhere},
    %r{ 22/tcp \(v6\) + ALLOW IN + Anywhere \(v6\)},
    %r{ 22,53,80,443/tcp + ALLOW OUT + Anywhere \(out\)},
    %r{ 53,67,68/udp + ALLOW OUT + Anywhere \(out\)},
    %r{ 22,53,80,443/tcp \(v6\) + ALLOW OUT + Anywhere \(v6\) \(out\)},
    %r{ 53,67,68/udp \(v6\) + ALLOW OUT + Anywhere \(v6\) \(out\)}
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
  it { should be_running }
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
      %r(^\s+include\s+/home/app_user/sites/django_base/source/uwsgi_params;$)
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

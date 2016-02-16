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

require 'spec_helper'

set :backend, :exec

expected_apt_key_list = [
    %r{pub\s+4096R/ACCC4CF8},
    %r{uid\s+PostgreSQL Debian Repository}
]

describe file('/etc/apt/sources.list.d/postgresql.list') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_mode 644 }
  its(:content) { should match %r{deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main 9.5}}
  its(:md5sum) { should eq 'e231145ff9780269cecde8603841186c' }
end

describe command( 'apt-key list' ) do
  expected_apt_key_list.each do |r|
    its(:stdout) { should match(r) }
  end
end

describe package('postgresql-9.5') do
  it { should be_installed }
end

describe package('postgresql-contrib-9.5') do
  it { should be_installed }
end

describe package('postgresql-client-9.5') do
  it { should be_installed }
end

describe package('postgresql-server-dev-9.5') do
  it { should be_installed }
end

describe service('postgresql') do
  it { should be_enabled }
  it { should be_running }
end

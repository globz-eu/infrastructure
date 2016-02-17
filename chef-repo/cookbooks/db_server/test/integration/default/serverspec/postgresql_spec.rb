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

describe file('/etc/apt/sources.list.d/apt.postgresql.org.list') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_mode 644 }
  its(:content) { should match %r{deb\s+"http://apt.postgresql.org/pub/repos/apt" trusty-pgdg main 9.5} }
  its(:md5sum) { should eq '473d8003a185a7e593299826ba983aaa' }
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

describe file('/etc/postgresql/9.5/main/pg_hba.conf') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'postgres' }
  it { should be_mode 600 }
  its(:content) { should match %r{local\s+all\s+postgres\s+ident} }
  its(:md5sum) { should eq '9996ac972ded78f610ebb788b0750059' }
end

describe command( 'sudo -u postgres -p vagrant psql -l' ) do
    its(:stdout) { should match(/ app_name  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | /) }
end

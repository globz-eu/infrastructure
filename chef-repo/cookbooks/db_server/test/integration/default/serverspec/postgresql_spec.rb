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

pg_hba = [
    %r{local\s+all\s+postgres\s+md5},
    %r{local\s+all\s+all\s+md5}
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
  pg_hba.each do |p|
    its(:content) { should match(p) }
  end
  its(:md5sum) { should eq '9996ac972ded78f610ebb788b0750059' }
end

# test that postgres user was created and can login
describe command( "export PGPASSWORD='postgres_password'; psql -U postgres -l" ) do
  its(:stdout) { should match(%r(\s*Name\s+|\s+Owner\s+|\s+Encoding\s+|\s+Collate)) }
end

# test that the user db_user was created
describe command("export PGPASSWORD='postgres_password'; psql -U postgres -c '\\du'") do
  its(:stdout) { should match(%r(\s*db_user\s+|\s+|\s+\{\})) }
end

# test that app database was created
describe command( "export PGPASSWORD='postgres_password'; psql -U postgres -l" ) do
  its(:stdout) { should match(
      %r(\s*django_base\s+|\s+postgres\s+|\s+UTF8\s+|\s+en_US.UTF-8\s+|\s+en_US.UTF-8\s+|\s+)
                              ) }
end

# test that db_user has the right privileges on app_database
describe command("export PGPASSWORD='postgres_password'; psql -U postgres -d django_base -c '\\ddp'") do
  its(:stdout) { should match(%r(\.*postgres\s+|\s+public\s+|\s+sequence\s+|\s+db_user=rU/postgres)) }
  its(:stdout) { should match(%r(\.*postgres\s+|\s+public\s+|\s+tab;e\s+|\s+db_user=arwd/postgres)) }
end

# test that db_user can login to app database
describe command( "export PGPASSWORD='db_user_password'; psql -U db_user -h localhost -d django_base -c '\\ddp'" ) do
  its(:stdout) { should match(%r(\.*postgres\s+|\s+public\s+|\s+sequence\s+|\s+db_user=rU/postgres)) }
end

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

if os[:family] == 'ubuntu'
  if os[:release] == '14.04'
    # apt repository for postgresql9.5 should be there
    describe file('/etc/apt/sources.list.d/apt.postgresql.org.list') do
      it { should exist }
      it { should be_file }
      it { should be_owned_by 'root' }
      it { should be_mode 644 }
      its(:content) { should match %r{deb\s+"http://apt.postgresql.org/pub/repos/apt" trusty-pgdg main 9.5} }
      its(:md5sum) { should eq '1749267b56d79a347cec31e0397f85c5' }
    end

    # apt key should be correct for postgresql9.5
    describe command( 'apt-key list' ) do
      expected_apt_key_list = [
          %r{pub\s+4096R/ACCC4CF8},
          %r{uid\s+PostgreSQL Debian Repository}
      ]
      expected_apt_key_list.each do |r|
        its(:stdout) { should match(r) }
      end
    end

    # postgresql9.5 and dev packages should be installed
    describe package('postgresql-9.5') do
      it { should be_installed }
    end

    describe package('postgresql-contrib-9.5') do
      it { should be_installed }
    end

    describe package('postgresql-client-9.5') do
      it { should be_installed }
    end

  elsif os[:release] == '16.04'
    # postgresql9.5 and dev packages should be installed
    describe package('postgresql') do
      it { should be_installed }
    end

    describe package('postgresql-contrib-9.5') do
      it { should be_installed }
    end
  end

  describe package('postgresql-server-dev-9.5') do
    it { should be_installed }
  end

  # postgresql should be running
  describe service('postgresql') do
    it { should be_enabled }
    it { should be_running }
  end

  # postgres should be configured for md5 authentication
  describe file('/etc/postgresql/9.5/main/pg_hba.conf') do
    pg_hba = [
        %r{local\s+all\s+postgres\s+ident},
        %r{local\s+all\s+all\s+md5}
    ]
    it { should exist }
    it { should be_file }
    it { should be_owned_by 'postgres' }
    it { should be_mode 600 }
    pg_hba.each do |p|
      its(:content) { should match(p) }
    end
    if os[:release] == '14.04'
      its(:md5sum) { should eq 'de65251e5d5011c6b746d98eed43207e' }
    elsif os[:release] == '16.04'
      its(:md5sum) { should eq 'f21a82388ac74e4919408bf8d5a1415b' }
    end
  end

  # test that postgres user was created and can login
  describe command( "export PGPASSWORD='postgres_password'; psql -U postgres -h localhost -l" ) do
    its(:stdout) { should match(%r(\s*Name\s+|\s+Owner\s+|\s+Encoding\s+|\s+Collate)) }
  end

  # test that the user db_user was created
  describe command("sudo -u postgres psql -c '\\du'") do
    its(:stdout) { should match(%r(\s*db_user\s+|\s+|\s+\{\})) }
  end

  # File structure for scripts should be present
  describe file('/home/db_user/sites') do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'db_user' }
    it { should be_grouped_into 'db_user' }
    it { should be_mode 500 }
  end

  describe file('/home/db_user/sites/django_base') do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'db_user' }
    it { should be_grouped_into 'db_user' }
    it { should be_mode 500 }
  end

  describe file('/home/db_user/sites/django_base/scripts') do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'db_user' }
    it { should be_grouped_into 'db_user' }
    it { should be_mode 500 }
  end

  scripts = ['createdb.py', 'servestatic.py', 'installdjangoapp.py']
  scripts.each do |s|
    describe file "/home/db_user/sites/django_base/scripts/#{s}" do
      it { should exist }
      it { should be_file }
      it { should be_owned_by 'db_user' }
      it { should be_grouped_into 'db_user' }
      it { should be_mode 500 }
    end
  end

  describe file '/home/db_user/sites/django_base/scripts/utilities/commandfileutils.py' do
    it { should exist }
    it { should be_file }
    it { should be_owned_by 'db_user' }
    it { should be_grouped_into 'db_user' }
    it { should be_mode 400 }
  end

  # Scripts dependencies should be present
  describe package('python3-pip') do
    it { should be_installed }
  end

  describe command ('pip3 list | grep psutil') do
    its(:stdout) { should match(/psutil\s+\(\d+\.\d+\.\d+\)/)}
  end

  # Config file for for installation scripts should be present
  describe file('/home/db_user/sites/django_base/scripts/conf.py') do
    params = [
        %r(^DIST_VERSION = '#{os[:release]}'$),
        %r(^DEBUG = 'DEBUG'$),
        %r(^NGINX_CONF = ''$),
        %r(^APP_HOME = ''$),
        %r(^APP_HOME_TMP = ''$),
        %r(^APP_USER = ''$),
        %r(^WEB_USER = ''$),
        %r(^WEBSERVER_USER = ''$),
        %r(^DB_USER = 'db_user'$),
        %r(^DB_ADMIN_USER = 'postgres'$),
        %r(^GIT_REPO = 'https://github\.com/globz-eu/django_base\.git'$),
        %r(^STATIC_PATH = ''$),
        %r(^MEDIA_PATH = ''$),
        %r(^UWSGI_PATH = ''$),
        %r(^VENV = ''$),
        %r(^REQS_FILE = ''$),
        %r(^SYS_DEPS_FILE = ''$),
        %r(^LOG_FILE = '/var/log/django_base/create_db\.log'$)
    ]
    it { should exist }
    it { should be_file }
    it { should be_owned_by 'db_user' }
    it { should be_grouped_into 'db_user' }
    it { should be_mode 400 }
    params.each do |p|
      its(:content) { should match(p)}
    end
  end

  # test that app database was created
  describe command( "sudo -u postgres psql -l" ) do
    its(:stdout) { should match(
      %r(\s*django_base\s+|\s+postgres\s+|\s+UTF8\s+|\s+en_US.UTF-8\s+|\s+en_US.UTF-8\s+|\s+)
                          ) }
  end

  # test that db_user has the right privileges on app_database
  describe command("sudo -u postgres psql -d django_base -c '\\ddp'") do
    its(:stdout) { should match(%r(\.*postgres\s+|\s+public\s+|\s+sequence\s+|\s+db_user=rU/postgres)) }
    its(:stdout) { should match(%r(\.*postgres\s+|\s+public\s+|\s+table\s+|\s+db_user=arwd/postgres)) }
  end

  # test that db_user can login to app database
  describe command( "export PGPASSWORD='db_user_password'; psql -U db_user -h localhost -d django_base -c '\\ddp'" ) do
    its(:stdout) { should match(%r(\.*postgres\s+|\s+public\s+|\s+sequence\s+|\s+db_user=rU/postgres)) }
  end
end

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
# Server Spec:: default

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

# manages postgresql server

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
  its(:md5sum) { should eq 'de65251e5d5011c6b746d98eed43207e' }
end

# test that postgres user was created and can login
describe command( "export PGPASSWORD='postgres_password'; psql -U postgres -h localhost -l" ) do
  its(:stdout) { should match(%r(\s*Name\s+|\s+Owner\s+|\s+Encoding\s+|\s+Collate)) }
end

# test that the user db_user was created
describe command("sudo -u postgres psql -c '\\du'") do
  its(:stdout) { should match(%r(\s*db_user\s+|\s+|\s+\{\})) }
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


# manages nginx server
describe command( 'ufw status numbered' ) do
  expected_rules = [
      %r{ 22/tcp + ALLOW IN + Anywhere},
      %r{ 80/tcp + ALLOW IN + Anywhere},
      %r{ 22/tcp \(v6\) + ALLOW IN + Anywhere \(v6\)},
      %r{ 22,53,80,443/tcp + ALLOW OUT + Anywhere \(out\)},
      %r{ 53,67,68/udp + ALLOW OUT + Anywhere \(out\)},
      %r{ 22,53,80,443/tcp \(v6\) + ALLOW OUT + Anywhere \(v6\) \(out\)},
      %r{ 53,67,68/udp \(v6\) + ALLOW OUT + Anywhere \(v6\) \(out\)}
  ]
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
end

describe service('nginx') do
  it { should be_running }
end

describe file('/etc/nginx/sites-available/django_base.conf') do
  params = [
      /^# django_base.conf$/,
      %r(^\s+server unix:///home/app_user/sites/django_base/sockets/django_base\.sock; # for a file socket$),
      /^\s+# server 127\.0\.0\.1:8001; # for a web port socket/,
      /^\s+listen\s+80;$/,
      /^\s+server_name\s+192\.168\.1\.84;$/,
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

# manages app_user
describe user( 'app_user' ) do
  it { should exist }
  it { should belong_to_group 'app_user' }
  it { should belong_to_group 'www-data' }
  it { should have_home_directory '/home/app_user' }
  it { should have_login_shell '/bin/bash' }
  its(:encrypted_password) { should match('$6$g7n0bpuYPHBI.$FVkbyH37IcBhDc000UcrGZ/u4n1f9JaEhLtBrT1VcAwKXL1sh9QDoTb3leMdazZVLQuv/w1FCBeqXX6GZGWid/') }
end

# manages app from git
describe package('git') do
  it { should be_installed }
end

describe file('/home/app_user/sites') do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by 'app_user' }
  it { should be_grouped_into 'www-data' }
  it { should be_mode 550 }
end

describe file('/home/app_user/sites/django_base') do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by 'app_user' }
  it { should be_grouped_into 'www-data' }
  it { should be_mode 550 }
end

describe file('/home/app_user/sites/django_base/source') do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by 'app_user' }
  it { should be_grouped_into 'app_user' }
  it { should be_mode 500 }
end

describe file('/home/app_user/sites/django_base/source/django_base/manage.py') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'app_user' }
  it { should be_grouped_into 'app_user' }
  it { should be_mode 400 }
end


# configures app
describe file('/home/app_user/sites/django_base/static') do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by 'app_user' }
  it { should be_grouped_into 'www-data' }
  it { should be_mode 750 }
end

describe file('/home/app_user/sites/django_base/media') do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by 'app_user' }
  it { should be_grouped_into 'www-data' }
  it { should be_mode 750 }
end

describe file('/home/app_user/sites/django_base/sockets') do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by 'app_user' }
  it { should be_grouped_into 'www-data' }
  it { should be_mode 750 }
end

describe file('/home/app_user/.envs/django_base/lib/python3.4/django_base.pth') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'app_user' }
  it { should be_grouped_into 'app_user' }
  it { should be_mode 400 }
  its(:content) { should match(/\/home\/app_user\/sites\/django_base\/source/)}
end

describe package('libxml2-dev') do
  it { should be_installed }
end

describe package('libxslt1-dev') do
  it { should be_installed }
end

describe package('zlib1g-dev') do
  it { should be_installed }
end

describe package('python3-numpy') do
  it { should be_installed }
end

describe command ( '/home/app_user/.envs/django_base/bin/pip3 list' ) do
  packages = [
      'Django (1.9.5)',
      'numpy (1.11.0)',
      'biopython (1.66)',
      'lxml (3.6.0)',
  ]
  packages.each do |p|
    its(:stdout) { should match(Regexp.escape(p))}
  end
end


describe file('/home/app_user/sites/django_base/source/django_base/configuration.py') do
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

describe file('/home/app_user/sites/django_base/source/django_base/django_base/settings_admin.py') do
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

describe file('/home/app_user/sites/django_base/source/install_dependencies.py') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'app_user' }
  it { should be_grouped_into 'app_user' }
  it { should be_mode 500 }
  its(:content) { should match(%r(^path = '/home/app_user/sites/django_base/source/django_base/system_dependencies\.txt'$))}
end

# manages python environment
describe package('python3.4') do
  it { should be_installed }
end

describe file('/usr/bin/python3.4') do
  it { should exist }
  it { should be_file }
end

describe command ( 'pip3 -V' ) do
  pip3_version = 'pip 8.1.1 from /usr/local/lib/python3.4/dist-packages (python 3.4)'
  its(:stdout) { should match(Regexp.escape(pip3_version))}
end

describe package('python3.4-dev') do
  it { should be_installed }
end

describe file('/home/app_user/.envs') do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by 'app_user' }
  it { should be_grouped_into 'app_user' }
  it { should be_mode 500 }
end

describe file('/home/app_user/.envs/django_base') do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by 'app_user' }
  it { should be_grouped_into 'app_user' }
  it { should be_mode 500 }
end

describe file('/home/app_user/.envs/django_base/bin') do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by 'app_user' }
  it { should be_grouped_into 'app_user' }
  it { should be_mode 755 }
end

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

# configures uwsgi
describe file('/home/app_user/sites/django_base/source/django_base_uwsgi.ini') do
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

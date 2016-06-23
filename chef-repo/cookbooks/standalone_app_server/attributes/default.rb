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
# Attributes:: default

default['install_scripts']['users'] = []
default['install_scripts']['git']['app_repo'] = 'https://github.com/globz-eu/django_base.git'

default['poise-python']['install_python2'] = false

default['django_app_server']['git']['app_repo'] = false
default['django_app_server']['git']['scripts_repo'] = 'https://github.com/globz-eu/scripts.git'
default['django_app_server']['django_app']['debug'] = 'False'
default['django_app_server']['django_app']['allowed_host'] = 'localhost'
default['django_app_server']['django_app']['engine'] = 'django.db.backends.postgresql_psycopg2'
default['django_app_server']['django_app']['db_host'] = 'localhost'
default['django_app_server']['uwsgi']['processes'] = '2'
default['django_app_server']['uwsgi']['socket'] = 'unix'

default['apt']['compile_time_update'] = true
default['postgresql']['version'] = '9.5'
default['postgresql']['enable_pgdg_apt'] = true
default['postgresql']['dir'] = '/etc/postgresql/9.5/main'
default['postgresql']['client']['packages'] = ['postgresql-server-dev-9.5', 'postgresql-client-9.5']
default['postgresql']['server']['packages'] = ['postgresql-server-dev-9.5', 'postgresql-9.5']
default['postgresql']['server']['service_name'] = 'postgresql'
default['postgresql']['contrib']['packages'] = ['postgresql-contrib-9.5']
default['postgresql']['pg_hba'] = [
    {
        :comment => '# Database administrative login by Unix domain socket',
        :type => 'local',
        :db => 'all',
        :user => 'postgres',
        :addr => nil,
        :method => 'ident'
    },
    {
        :comment => '# "local" is for Unix domain socket connections only',
        :type => 'local',
        :db => 'all',
        :user => 'all',
        :addr => nil,
        :method => 'md5'
    },
    {
        :comment => '# IPv4 local connections:',
        :type => 'host',
        :db => 'all',
        :user => 'all',
        :addr => '127.0.0.1/32',
        :method => 'md5'
    },
    {
        :comment => '# IPv6 local connections:',
        :type => 'host',
        :db => 'all',
        :user => 'all',
        :addr => '::1/128',
        :method => 'md5'
    }
]

default['db_server']['postgresql']['db_name'] = false


default['web_server']['nginx']['app_name'] = 'django_base'
default['web_server']['nginx']['server_name'] = '192.168.1.82'

default['basic_node']['firewall']['web_server'] = true

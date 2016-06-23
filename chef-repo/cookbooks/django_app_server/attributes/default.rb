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
# Cookbook Name:: django_app_server

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

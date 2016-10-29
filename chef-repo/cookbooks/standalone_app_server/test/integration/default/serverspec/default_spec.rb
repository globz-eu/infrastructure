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

app_name = 'django_base'
ips = {'14.04' => '192.168.1.86', '16.04' => '192.168.1.87'}
https = false

require 'default'

# Cookbook:: db_server
# Server Spec:: db_user

require 'db_user'

# Cookbook:: db_server
# Server Spec:: postgresql

require 'postgresql'
postgresql_spec(app_name)

# Cookbook:: db_server
# Server Spec:: redis

require 'redis'

# Cookbook:: web_server
# Spec:: web_user

require 'web_user'

# Cookbook:: web_server
# Server Spec:: nginx

require 'nginx'
nginx_spec(app_name, ips, https, site_down: false)

# Cookbook:: django_app_server
# Server Spec:: app_user

require 'app_user'

# Cookbook Name:: django_app_server
# Server Spec:: python

require 'python'

# Cookbook Name:: django_app_server
# Server Spec:: django_app

require 'django_app'
django_app_spec(app_name, ips)

# Cookbook Name:: django_app_server
# Server Spec:: uwsgi

require 'uwsgi'

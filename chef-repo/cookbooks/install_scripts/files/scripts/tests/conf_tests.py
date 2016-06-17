"""
=====================================================================
Django app deployment scripts
Copyright (C) 2016 Stefan Dieterle
e-mail: golgoths@yahoo.fr

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
=====================================================================
"""

import os

__author__ = 'Stefan Dieterle'

TEST_DIR = '/tmp/scripts_test'
FIFO_DIR = '/tmp/app_name'

DIST_VERSION = '16.04'
DEBUG = 'DEBUG'
NGINX_CONF = '/tmp/scripts_test/etc/nginx'
APP_HOME = '/tmp/scripts_test/app_user/sites/app_name/source'
APP_HOME_TMP = '/tmp/scripts_test/web_user/sites/app_name/source'
APP_USER = 'app_user'
WEB_USER = 'web_user'
WEBSERVER_USER = 'www-data'
DB_USER = 'db_user'
DB_ADMIN_USER = 'postgres'
GIT_REPO = 'https://github.com/globz-eu/app_name.git'
STATIC_PATH = '/tmp/scripts_test/web_user/sites/app_name/static_files'
MEDIA_PATH = '/tmp/scripts_test/web_user/sites/app_name/media_files'
UWSGI_PATH = '/tmp/scripts_test/web_user/sites/app_name/uwsgi'
DOWN_PATH = '/tmp/scripts_test/web_user/sites/app_name/down'
VENV = '/tmp/scripts_test/app_user/.envs/app_name'
REQS_FILE = os.path.abspath(
    os.path.join(
        os.path.dirname(os.path.dirname(__file__)),
        'test_files/install_system_dependencies/requirements.txt'
    )
)
SYS_DEPS_FILE = os.path.abspath(
    os.path.join(
        os.path.dirname(os.path.dirname(__file__)),
        'test_files/install_system_dependencies/system_dependencies.txt'
    )
)
LOG_FILE = os.path.abspath(os.path.join(os.path.dirname(os.path.dirname(__file__)), 'log/tests.log'))

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

example configuration file
"""

import os

__author__ = 'Stefan Dieterle'


DIST_VERSION = '14.04'
DEBUG = False
APP_HOME = '/tmp/source'
APP_USER = 'app_user'
GIT_REPO = 'https://github.com/globz-eu/app_name.git'
VENV = '/tmp/.envs/app_name'
REQS_FILE = os.path.abspath(
    os.path.join(
        os.path.dirname(__file__),
        'test_files/install_system_dependencies/requirements.txt'
    )
)
SYS_DEPS_FILE = os.path.abspath(
    os.path.join(
        os.path.dirname(__file__),
        'test_files/install_system_dependencies/system_dependencies.txt'
    )
)
LOG_FILE = os.path.abspath(os.path.join(os.path.dirname(__file__), 'log/sys_deps.log'))

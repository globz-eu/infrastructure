"""
=====================================================================
Chef server infrastructure
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

DIST_VERSION = '16.04'
LOG_LEVEL = 'DEBUG'
TEST_DIR = '/tmp/scripts_test'
LOG_FILE = os.path.abspath(os.path.join(os.path.dirname(os.path.dirname(__file__)), 'log/tests.log'))
APP_HOME = os.path.join(TEST_DIR, 'app_user', 'sites', 'app_name', 'source')
DOWNLOAD_FOLDER = os.path.join(TEST_DIR, 'chef-server')
METADATA_FILE = os.path.abspath(
    os.path.join(
        os.path.dirname(os.path.dirname(__file__)),
        'test_files/chef_server_metadata'
    )
)
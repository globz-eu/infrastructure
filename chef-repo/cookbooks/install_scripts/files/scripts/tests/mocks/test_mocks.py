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
import re
import shutil
import subprocess
from unittest.mock import MagicMock
from tests.runandlogtest import RunAndLogTest
from tests.conf_tests import APP_HOME_TMP, DIST_VERSION, APP_HOME, VENV, GIT_REPO
import tests.mocks.commandfileutils_mocks as mocks
from tests.helpers import Alternate
from tests.mocks.commandfileutils_mocks import own_app_mock, check_process_mock
from tests.mocks.installdjangoapp_mocks import clone_app_mock, add_app_to_path_mock, copy_config_mock

__author__ = 'Stefan Dieterle'


class CommandMockTests(RunAndLogTest):
    """
    tests CommandFileUtils methods mocks
    """

    def setUp(self):
        RunAndLogTest.setUp(self)

    def tearDown(self):
        RunAndLogTest.tearDown(self)
        if os.path.exists(APP_HOME_TMP):
            shutil.rmtree(APP_HOME_TMP)

    def test_own_app_mock(self):
        own_app_mock('path', 'owner', 'group')
        self.log('INFO: changed ownership of path to owner:group')

    def test_check_process_mock(self):
        ret_list = [True, False, False, True]
        mocks.alt_bool = Alternate(ret_list)
        ret = []
        for i in range(len(ret_list)):
            ret.append(check_process_mock('process'))
        self.assertEqual(ret_list, ret, ret)


class InstallMockTests(RunAndLogTest):
    """
    tests InstallDjangoApp methods mocks
    """

    def setUp(self):
        RunAndLogTest.setUp(self)
        self.git_repo = GIT_REPO
        self.app_home = APP_HOME
        p = re.compile('https://github.com/[\w\-]+/(\w+)\.git')
        self.app_name = p.match(self.git_repo).group(1)
        self.venv = VENV

    def tearDown(self):
        RunAndLogTest.tearDown(self)
        if os.path.exists(APP_HOME_TMP):
            shutil.rmtree(APP_HOME_TMP)

    def test_add_app_to_path_mock(self):
        """
        tests that add_app_to_path_mock writes app_home to app pth file
        """
        if DIST_VERSION == '14.04':
            python_version = 'python3.4'
        elif DIST_VERSION == '16.04':
            python_version = 'python3.5'
        pth_path = os.path.join(self.venv, 'lib', python_version)
        run = add_app_to_path_mock(self.app_home)
        with open(os.path.join(pth_path, '%s.pth' % self.app_name)) as pth:
            pth_list = [l for l in pth]
        self.assertEqual(0, run, run)
        self.assertEqual([self.app_home], pth_list, pth_list)

    def test_copy_config_mock(self):
        """
        tests that copy_config_mock creates the right directories
        """
        run = copy_config_mock(self.app_home)
        self.assertEqual(0, run, run)
        self.assertTrue(os.path.exists(os.path.join(self.app_home, self.app_name, self.app_name)))

    def test_clone_app_mock(self):
        """
        tests clone_app_mock creates media and static files
        """
        if DIST_VERSION == '14.04':
            subprocess.check_call = MagicMock()
        else:
            if DIST_VERSION == '16.04':
                subprocess.run = MagicMock()
        clone_app_mock(APP_HOME_TMP)
        static_files = [
            os.path.join(APP_HOME_TMP, 'app_name/static/static_file'),
            os.path.join(APP_HOME_TMP, 'app_name/media/media_file'),
            os.path.join(APP_HOME_TMP, 'app_name/uwsgi_params'),
            os.path.join(APP_HOME_TMP, 'app_name/static/site_down/index.html'),
        ]
        for static_file in static_files:
            self.assertTrue(os.path.isfile(static_file), static_file)

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
import shutil
import stat
from unittest import TestCase
from tests.helpers import make_test_dir, remove_test_dir, Alternate
from tests.conf_tests import TEST_DIR

__author__ = 'Stefan Dieterle'


class HelpersTest(TestCase):
    def setUp(self):
        try:
            shutil.rmtree(TEST_DIR)
        except (PermissionError, FileNotFoundError):
            pass

    def test_make_test_dir(self):
        make_test_dir()
        self.assertTrue(os.path.exists(TEST_DIR))
        self.assertTrue(os.path.isdir(TEST_DIR))

    def test_make_test_dir_handles_already_existing(self):
        os.makedirs(TEST_DIR, exist_ok=True)
        make_test_dir()
        self.assertTrue(os.path.exists(TEST_DIR))
        self.assertTrue(os.path.isdir(TEST_DIR))

    def test_remove_test_dir(self):
        os.makedirs(TEST_DIR, exist_ok=True)
        remove_test_dir()
        self.assertFalse(os.path.exists(TEST_DIR))

    def test_remove_test_dir_handles_file_not_found_errors(self):
        remove_test_dir()
        self.assertFalse(os.path.exists(TEST_DIR))

    def test_remove_test_dir_handles_permission_errors(self):
        os.makedirs(TEST_DIR)
        os.chmod(TEST_DIR, stat.S_IWUSR)
        remove_test_dir()
        self.assertFalse(os.path.exists(TEST_DIR))

    def test_remove_test_dir_handles_nested_permission_errors(self):
        os.makedirs(os.path.join(TEST_DIR, 'dir1', 'dir2', 'dir3'))
        os.chmod(os.path.join(TEST_DIR, 'dir1', 'dir2'), stat.S_IWUSR)
        remove_test_dir()
        self.assertFalse(os.path.exists(TEST_DIR))


class AlternateTest(TestCase):
    def test_alternate(self):
        ret = [True, False, 'bla', 'blu']
        alt = Alternate(ret)
        alt_ret = []
        for i in range(len(ret)):
            alt_ret.append(alt('some_arg'))
        self.assertEqual(ret, alt_ret, alt_ret)
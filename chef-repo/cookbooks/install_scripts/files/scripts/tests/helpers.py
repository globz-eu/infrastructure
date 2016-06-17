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
from tests.conf_tests import TEST_DIR, FIFO_DIR

__author__ = 'Stefan Dieterle'


def make_test_dir():
    os.makedirs(TEST_DIR, exist_ok=True)


def remove_test_dir():
    for test_path in [TEST_DIR, FIFO_DIR]:
        if os.path.isdir(test_path):
            try:
                shutil.rmtree(test_path)
            except PermissionError:
                os.chmod(test_path, stat.S_IRUSR | stat.S_IWUSR | stat.S_IXUSR)
                try:
                    shutil.rmtree(test_path)
                except PermissionError:
                    for root, dirs, files in os.walk(test_path):
                        for name in dirs:
                            os.chmod(os.path.join(root, name), stat.S_IRUSR | stat.S_IWUSR | stat.S_IXUSR)
                    shutil.rmtree(test_path)
        else:
            pass


class Alternate:
    """
    returns elements in ret_list in sequence each time called.
    """
    def __init__(self, ret_list):
        self.index = 0
        self.ret_list = ret_list

    def __call__(self, *args, **kwargs):
        ret = self.ret_list[self.index]
        self.index += 1
        return ret

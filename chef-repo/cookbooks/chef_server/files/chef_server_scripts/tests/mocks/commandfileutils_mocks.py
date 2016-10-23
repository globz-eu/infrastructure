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

from tests.helpers import Alternate
from tests.conf_tests import DIST_VERSION, LOG_FILE, LOG_LEVEL
from utilities.commandfileutils import CommandFileUtils

__author__ = 'Stefan Dieterle'

alt_bool = Alternate([])


def check_process_mock(process):
    global alt_bool
    return alt_bool(process)


def own_app_mock(path, owner, group):
    cfu = CommandFileUtils(DIST_VERSION, LOG_FILE, LOG_LEVEL)
    cfu.write_to_log('changed ownership of %s to %s:%s' % (path, owner, group), 'INFO')

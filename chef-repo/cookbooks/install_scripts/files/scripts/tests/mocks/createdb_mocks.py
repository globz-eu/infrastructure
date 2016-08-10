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

import re
import sys
import datetime
import subprocess
from subprocess import CalledProcessError
from tests.conf_tests import DB_ADMIN_USER, GIT_REPO, LOG_FILE, DIST_VERSION

__author__ = 'Stefan Dieterle'


def run_command_mock(cmd, msg, cwd=None, out=None, log_error=True):
    git_repo = GIT_REPO
    p = re.compile('https://github.com/[\w\-]+/(\w+)\.git')
    db_name = p.match(git_repo).group(1)
    if DIST_VERSION == '14.04':
        run = subprocess.check_call
        check = False
    elif DIST_VERSION == '16.04':
        run = subprocess.run
        check = True
    if check:
        kwargs = dict(check=True)
    else:
        kwargs = {}
    try:
        if out:
            with open(out, 'a') as log:
                kwargs.update(dict(cwd=cwd, stdout=log, stderr=log))
                try:
                    run(cmd, **kwargs)
                    now = datetime.datetime.utcnow()
                    log.write('%s %s: %s\n' % (now.strftime('%Y-%m-%d %H:%M:%S.%f')[:-3], 'INFO', msg))
                except CalledProcessError:
                    if 'CREATE DATABASE %s;' % db_name in cmd:
                        db_exists_msg = 'ERROR:  database "%s" already exists\n' % db_name
                    elif 'DROP DATABASE %s;' % db_name in cmd:
                        db_exists_msg = 'ERROR:  database "%s" does not exist\n' % db_name
                    log.write(db_exists_msg)
                    raise CalledProcessError(returncode=1, cmd=cmd)
    except CalledProcessError as error:
        if log_error:
            err_msg = '%s exited with exit code %s' % (' '.join(error.cmd), str(error.returncode))
            with open(out, 'a') as log:
                now = datetime.datetime.utcnow()
                log.write('%s %s: %s\n' % (now.strftime('%Y-%m-%d %H:%M:%S.%f')[:-3], 'ERROR', err_msg))
        sys.exit(1)
    return 0

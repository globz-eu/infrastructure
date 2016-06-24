#! /usr/bin/python3
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
from optparse import OptionParser
from utilities.commandfileutils import CommandFileUtils
from conf import DIST_VERSION, LOG_FILE, DB_USER, DB_ADMIN_USER, GIT_REPO

__author__ = 'Stefan Dieterle'


class CreateDB(CommandFileUtils):
    def __init__(
            self, dist_version, log_file, log_level, db_user, db_admin_user,
            git_repo='https://github.com/globz-eu/django_base.git'
    ):
        CommandFileUtils.__init__(self, dist_version, log_file, log_level)
        self.git_repo = git_repo
        p = re.compile('https://github.com/[\w\-]+/(\w+)\.git')
        self.db_name = p.match(self.git_repo).group(1)
        self.db_user = db_user
        self.db_admin_user = db_admin_user

    def create_db(self):
        run = []
        cmds = [
            {
                'cmd': ['sudo', '-u', self.db_admin_user, 'psql', '-c', 'CREATE DATABASE %s;' % self.db_name],
                'msg': 'created database %s' % self.db_name,
            },
            {
                'cmd': [
                    'sudo', '-u', self.db_admin_user, 'psql', '-d', self.db_name, '-c',
                    'ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO'
                    ' %s;' % self.db_user
                ],
                'msg': 'granted default privileges on tables to %s' % self.db_user,
            },
            {
                'cmd': [
                    'sudo', '-u', self.db_admin_user, 'psql', '-d', self.db_name, '-c',
                    'ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, USAGE ON SEQUENCES TO %s;' % self.db_user
                ],
                'msg': 'granted default privileges on sequences to %s' % self.db_user
            }
        ]
        try:
            run.append(self.run_command(cmds[0]['cmd'], cmds[0]['msg'], out=self.log_file, log_error=False))
            for c in cmds[1:]:
                run.append(self.run_command(c['cmd'], c['msg']))
        except SystemExit:
            with open(self.log_file) as log:
                last = ''
                for l in log:
                    last = l
            if last == 'ERROR:  database "%s" already exists\n' % self.db_name:
                self.logging('skipped database creation, \'%s\' already exists' % self.db_name, 'INFO')
                run.append(0)
            else:
                self.logging('create_db exited with error', 'ERROR')
                sys.exit(1)
        for r in run:
            if r != 0:
                return r
        return 0

    def drop_db(self):
        cmd = ['sudo', '-u', self.db_admin_user, 'psql', '-c', 'DROP DATABASE %s;' % self.db_name]
        msg = 'dropped database %s' % self.db_name
        try:
            run = self.run_command(cmd, msg, out=self.log_file, log_error=False)
        except SystemExit:
            with open(self.log_file) as log:
                last = ''
                for l in log:
                    last = l
            if last == 'ERROR:  database "%s" does not exist\n' % self.db_name:
                self.logging('skipped drop database, \'%s\' does not exist' % self.db_name, 'INFO')
                run = 0
            else:
                self.logging('create_db exited with error', 'ERROR')
                sys.exit(1)
        return run


def main():
    run = []
    usage = "usage: %prog [options] arg"
    parser = OptionParser(usage)
    parser.add_option('-c', '--create', dest='create', action='store_true',
                      help='create: creates database and manages default privileges', default=False)
    parser.add_option('-l', '--log-level', dest='log_level',
                      help='log-level: DEBUG, INFO, ERROR, FATAL', default='INFO')
    parser.add_option('-x', '--drop', dest='drop', action='store_true',
                      help='drop: drops database', default=False)
    parser.add_option('-r', '--reset', dest='reset', action='store_true',
                      help='reset: drops database, recreates it and manages default privileges', default=False)
    (options, args) = parser.parse_args()
    if len(args) > 2:
        parser.error('incorrect number of arguments')
    createdb = CreateDB(
        DIST_VERSION, LOG_FILE, options.log_level, DB_USER, DB_ADMIN_USER,
        git_repo=GIT_REPO
    )
    if options.create:
        create = createdb.create_db()
        run.append(create)
    if options.drop:
        drop = createdb.drop_db()
        run.append(drop)
    if options.reset:
        drop = createdb.drop_db()
        run.append(drop)
        create = createdb.create_db()
        run.append(create)
    for r in run:
        if r != 0:
            sys.exit(1)
    sys.exit(0)


if __name__ == '__main__':
    main()

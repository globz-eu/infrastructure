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
import subprocess
from subprocess import CalledProcessError
from unittest import mock
from unittest.mock import call
from tests.runandlogtest import RunAndLogTest
from tests.conf_tests import GIT_REPO, DB_USER, DB_ADMIN_USER
from tests.mocks.createdb_mocks import run_command_mock
import dbserver
from dbserver import CreateDB

__author__ = 'Stefan Dieterle'


class DBTest(RunAndLogTest):
    def setUp(self):
        RunAndLogTest.setUp(self)
        self.git_repo = GIT_REPO
        p = re.compile('https://github.com/[\w\-]+/(\w+)\.git')
        self.db_name = p.match(self.git_repo).group(1)
        self.db_user = DB_USER
        self.db_admin_user = DB_ADMIN_USER


class CreateDBTest(DBTest):
    """
    tests CreateDB methods
    """
    def setUp(self):
        DBTest.setUp(self)

    def test_create_db(self):
        createdb = CreateDB(self.dist_version, self.log_file, self.log_level, self.db_user, self.db_admin_user,
                            git_repo=self.git_repo)
        cmds = [
            ['sudo', '-u', self.db_admin_user, 'psql', '-c', 'CREATE DATABASE %s;' % self.db_name],
            [
                'sudo', '-u', self.db_admin_user, 'psql', '-d', self.db_name, '-c',
                'ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO'
                ' %s;' % self.db_user
             ],
            [
                'sudo', '-u', self.db_admin_user, 'psql', '-d', self.db_name, '-c',
                'ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, USAGE ON SEQUENCES TO %s;' % self.db_user
            ]
        ]
        msgs = [
            'created database %s' % self.db_name,
            'granted default privileges on tables to %s' % self.db_user,
            'granted default privileges on sequences to %s' % self.db_user
        ]
        func = 'create_db'
        args = ()
        self.run_success(cmds, msgs, func, createdb.create_db, args)

    @mock.patch.object(CreateDB, 'run_command', side_effect=run_command_mock)
    def test_create_db_handles_already_existing_database(self, run_command_mock):
        cmd = [
                    'sudo', '-u', self.db_admin_user, 'psql', '-c', 'CREATE DATABASE %s;' % self.db_name
                ]
        if self.dist_version == '14.04':
            subprocess.check_call.side_effect = CalledProcessError(
                returncode=1, cmd=cmd
            )
        else:
            if self.dist_version == '16.04':
                subprocess.run.side_effect = CalledProcessError(
                    returncode=1, cmd=cmd
                )
        createdb = CreateDB(self.dist_version, self.log_file, self.log_level, self.db_user, self.db_admin_user,
                            git_repo=self.git_repo)
        try:
            run = createdb.create_db()
            self.assertTrue(run == 0, run)
        except SystemExit as error:
            self.assertFalse(error.code == 1, '%s exited with: %s' % ('create_db', str(error)))
        self.assertEqual(
            [call(cmd, 'created database app_name', log_error=False, out=self.log_file)],
            run_command_mock.mock_calls,
            run_command_mock.mock_calls
        )
        self.log('INFO: skipped database creation, \'%s\' already exists' % self.db_name)

    def test_drop_db(self):
        createdb = CreateDB(self.dist_version, self.log_file, self.log_level, self.db_user, self.db_admin_user,
                            git_repo=self.git_repo)
        cmd = ['sudo', '-u', self.db_admin_user, 'psql', '-c', 'DROP DATABASE %s;' % self.db_name]
        msg = 'dropped database %s' % self.db_name
        func = 'drop_db'
        args = ()
        self.run_success([cmd], [msg], func, createdb.drop_db, args)

    @mock.patch.object(CreateDB, 'run_command', side_effect=run_command_mock)
    def test_drop_db_handles_no_db_case(self, run_command_mock):
        cmd = [
                    'sudo', '-u', self.db_admin_user, 'psql', '-c', 'DROP DATABASE %s;' % self.db_name
                ]
        if self.dist_version == '14.04':
            subprocess.check_call.side_effect = CalledProcessError(
                returncode=1, cmd=cmd
            )
        else:
            if self.dist_version == '16.04':
                subprocess.run.side_effect = CalledProcessError(
                    returncode=1, cmd=cmd
                )
        createdb = CreateDB(self.dist_version, self.log_file, self.log_level, self.db_user, self.db_admin_user,
                            git_repo=self.git_repo)
        try:
            run = createdb.drop_db()
            self.assertTrue(run == 0, run)
        except SystemExit as error:
            self.assertFalse(error.code == 1, '%s exited with: %s' % ('create_db', str(error)))
        self.assertEqual(
            [call(cmd, 'dropped database app_name', log_error=False, out=self.log_file)],
            run_command_mock.mock_calls,
            run_command_mock.mock_calls
        )
        self.log('INFO: skipped drop database, \'%s\' does not exist' % self.db_name)


class CreateDBMain(DBTest):
    """
    tests createdb main()
    """
    def setUp(self):
        DBTest.setUp(self)

    def test_main_create(self):
        """
        tests main with parameter -c
        """
        sys.argv = ['dbserver', '-c', '-l', 'DEBUG']
        dbserver.DIST_VERSION = self.dist_version
        try:
            dbserver.main()
        except SystemExit as sysexit:
            self.assertEqual('0', str(sysexit), 'main returned: ' + str(sysexit))
        msgs = [
            'INFO: created database %s' % self.db_name,
            'INFO: granted default privileges on tables to %s' % self.db_user,
            'INFO: granted default privileges on sequences to %s' % self.db_user
        ]
        for m in msgs:
            self.log(m)

    def test_main_drop(self):
        """
        tests main with parameter -c
        """
        sys.argv = ['dbserver', '-x', '-l', 'DEBUG']
        dbserver.DIST_VERSION = self.dist_version
        try:
            dbserver.main()
        except SystemExit as sysexit:
            self.assertEqual('0', str(sysexit), 'main returned: ' + str(sysexit))
        msgs = [
            'INFO: dropped database %s' % self.db_name,
        ]
        for m in msgs:
            self.log(m)

    def test_main_reset(self):
        """
        tests main with parameter -c
        """
        sys.argv = ['dbserver', '-r', '-l', 'DEBUG']
        dbserver.DIST_VERSION = self.dist_version
        try:
            dbserver.main()
        except SystemExit as sysexit:
            self.assertEqual('0', str(sysexit), 'main returned: ' + str(sysexit))
        msgs = [
            'INFO: dropped database %s' % self.db_name,
            'INFO: created database %s' % self.db_name,
            'INFO: granted default privileges on tables to %s' % self.db_user,
            'INFO: granted default privileges on sequences to %s' % self.db_user
        ]
        for m in msgs:
            self.log(m)

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

from unittest import TestCase
from unittest.mock import call
from unittest import mock
import os
import shutil
import stat
import datetime
from utilities.commandfileutils import CommandFileUtils
from tests.conf_tests import DIST_VERSION, DEBUG, APP_HOME, LOG_FILE
from tests.runandlogtest import RunAndLogTest
from tests.mocks.commandfileutils_mocks import own_app_mock
from tests.helpers import remove_test_dir

__author__ = 'Stefan Dieterle'


class RunCommandTest(TestCase):
    """
    tests RunCommand methods
    """
    def setUp(self):
        self.dist_version = DIST_VERSION
        self.log_file = LOG_FILE
        self.log_level = DEBUG
        self.app_home = APP_HOME
        if os.path.exists(self.log_file):
            os.remove(self.log_file)
        remove_test_dir()

    def log(self, message, test=True):
        with open(self.log_file) as log:
            log_list = [l[24:] for l in log]
            if test:
                self.assertTrue('%s\n' % message in log_list, log_list)
            else:
                self.assertFalse('%s\n' % message in log_list, log_list)

    def test_run_command(self):
        """
        tests run_and_log runs given command, exits on error and writes to log
        """
        cmd = ['ls', '-la']
        msg = 'successfully ran command'
        runlog = CommandFileUtils(self.dist_version, self.log_file, self.log_level)
        args = (cmd, msg)
        runlog.run_command(*args)
        self.log('INFO: %s' % msg)

    def test_run_command_exits_on_error(self):
        """
        tests run_and_log runs given command, exits on error and writes to log
        """
        cmd = ['ls', 'fjlskhgtioeb.bla']
        msg = 'successfully ran command'
        runlog = CommandFileUtils(self.dist_version, self.log_file, self.log_level)
        args = (cmd, msg)
        try:
            runlog.run_command(*args)
            self.fail('command did not raise error')
        except SystemExit:
            self.log('ERROR: ls fjlskhgtioeb.bla exited with exit code 2')

    def test_run_command_exits_on_error_and_does_not_log_when_log_error_is_false(self):
        """
        tests run_and_log runs given command, exits on error and does not write to log when log_error is false
        """
        cmd = ['ls', 'fjlskhgtioeb.bla']
        msg = 'successfully ran command'
        runlog = CommandFileUtils(self.dist_version, self.log_file, self.log_level)
        args = (cmd, msg)
        try:
            runlog.run_command(*args, log_error=False)
            self.fail('command did not raise error')
        except SystemExit:
            with open(self.log_file) as log:
                log_content = log.readlines()
            self.assertFalse('ERROR: ls fjlskhgtioeb.bla exited with exit code 2' in log_content, log_content)


class CommandFileUtilsTest(RunAndLogTest):
    """
    Tests CommandFileUtils
    """
    def setUp(self):
        RunAndLogTest.setUp(self)
        self.app_home = APP_HOME
        if self.dist_version == '14.04':
            self.python_version = 'python3.4'
        elif self.dist_version == '16.04':
            self.python_version = 'python3.5'

    def log(self, message, test=True):
        with open(self.log_file) as log:
            log_list = [l[24:] for l in log]
            if test:
                self.assertTrue('%s\n' % message in log_list, log_list)
            else:
                self.assertFalse('%s\n' % message in log_list, log_list)

    def test_commandfileutils_exits_on_unknown_dist_version(self):
        try:
            CommandFileUtils('Invalid_dist_version', self.log_file, self.log_level)
        except SystemExit as error:
            self.assertEqual(1, error.code, 'CommandFileUtils exited with: %s' % str(error))
            self.log('FATAL: distribution not supported')

    def test_logging(self):
        """
        tests that logging writes messages to log
        """
        runlog = CommandFileUtils(self.dist_version, self.log_file, 'DEBUG')
        msgs = [
            ['debug message', 'DEBUG'],
            ['info message', 'INFO'],
            ['error message', 'ERROR'],
            ['fatal message', 'FATAL']
        ]
        for m, ll in msgs:
            runlog.logging(m, ll)
            self.log('%s: %s' % (ll, m))

    def test_logging_adds_timestamp_to_message(self):
        """
        tests that logging adds the current time to messages
        """
        runlog = CommandFileUtils(self.dist_version, self.log_file, 'DEBUG')
        msgs = [
            ['debug message', 'DEBUG'],
            ['info message', 'INFO'],
            ['error message', 'ERROR'],
            ['fatal message', 'FATAL']
        ]
        now = datetime.datetime.utcnow()
        for m, ll in msgs:
            runlog.logging(m, ll)
        with open(self.log_file) as log:
            log_list = [l[:19] for l in log]
            for l in log_list:
                self.assertEqual(now.strftime('%Y-%m-%d %H:%M:%S'), l, l)

    def test_logging_exits_when_log_level_is_not_specified(self):
        """
        tests that logging exits when log level is not specified or is invalid
        """
        runlog = CommandFileUtils(self.dist_version, self.log_file, 'DEBUG')
        msgs = [
            ['debug message', 'IMPORTANT'],
            ['info message', False],
        ]
        for m, ll in msgs:
            try:
                runlog.logging(m, ll)
            except SystemExit as error:
                self.assertEqual(1, error.code, '%s exited with: %s' % ('logging', str(error)))
            self.log('ERROR: log level "%s" is not specified or not valid' % ll)

    def test_logging_only_logs_messages_of_appropriate_log_level(self):
        """
        tests that logging only writes messages with appropriate log level to log
        """
        runlog = CommandFileUtils(self.dist_version, self.log_file, 'ERROR')
        msgs_log = [
            ['error message', 'ERROR'],
            ['fatal message', 'FATAL']
        ]
        msgs_no_log = [
            ['debug message', 'DEBUG'],
            ['info message', 'INFO'],
        ]
        for m, ll in msgs_log:
            runlog.logging(m, ll)
            self.log('%s: %s' % (ll, m))
        for m, ll in msgs_no_log:
            runlog.logging(m, ll)
            self.log('%s: %s' % (ll, m), test=False)

    def test_run_command(self):
        """
        tests run_and_log runs given command, exits on error and writes to log
        """
        cmd = ['ls', '-la']
        msg = 'successfully ran command'
        func = 'run_and_log'
        runlog = CommandFileUtils(self.dist_version, self.log_file, self.log_level)
        args = (cmd, msg)
        self.run_success([cmd], ['%s' % msg], func, runlog.run_command, args)
        self.run_error(cmd, func, runlog.run_command, args)

    def test_walktree(self):
        app_home_nested_file = os.path.join(self.app_home, 'app_name', 'file')
        os.makedirs(os.path.join(self.app_home, 'app_name'))
        with open(app_home_nested_file, 'w') as file:
            file.write('some text')
        runlog = CommandFileUtils(self.dist_version, self.log_file, self.log_level)
        runlog.walktree(self.app_home, runlog.logging, ('INFO', ), runlog.logging, ('INFO', ))
        paths = ['/tmp/scripts_test/app_user/sites/app_name/source/app_name',
                 '/tmp/scripts_test/app_user/sites/app_name/source/app_name/file']
        for p in paths:
            self.log('INFO: %s' % p)

    def test_walktree_exits_when_it_encounters_permission_error(self):
        """
        tests that walktree exits when it encounters a permission error while walking
        """
        runlog = CommandFileUtils(self.dist_version, self.log_file, self.log_level)
        try:
            runlog.walktree('/etc', os.path.isfile, (), os.listdir, ())
        except SystemExit as error:
            self.assertEqual(1, error.code, '%s exited with: %s' % ('walktree', str(error)))
        self.log('ERROR: Permission denied on: /etc/cups/ssl')

    def test_permissions_recursive(self):
        """
        tests permissions assigns permissions recursively and writes to log
        """
        test_permissions = [
            ['500', '700', '-r-x------', 'drwx------'],
            ['400', '500', '-r--------', 'dr-x------'],
            ['550', '770', '-r-xr-x---', 'drwxrwx---'],
            ['440', '550', '-r--r-----', 'dr-xr-x---'],
            ['644', '755', '-rw-r--r--', 'drwxr-xr-x'],
            ['755', '755', '-rwxr-xr-x', 'drwxr-xr-x']
        ]
        app_home_nested_file = os.path.join(self.app_home, 'app_name', 'file')

        runlog = CommandFileUtils(self.dist_version, self.log_file, self.log_level)

        for i in test_permissions:
            os.makedirs(os.path.join(self.app_home, 'app_name'))
            with open(app_home_nested_file, 'w') as file:
                file.write('some text')

            runlog.permissions(self.app_home, i[0], i[1], recursive=True)
            app_home_files = []
            app_home_dirs = []
            for root, dirs, files in os.walk(self.app_home):
                for name in files:
                    app_home_files.append(os.path.join(root, name))
                for name in dirs:
                    app_home_dirs.append(os.path.join(root, name))
                app_home_dirs.append(self.app_home)
            for a in app_home_files:
                self.assertEqual(i[2], stat.filemode(os.stat(a).st_mode), stat.filemode(os.stat(a).st_mode))
            for a in app_home_dirs:
                self.assertEqual(i[3], stat.filemode(os.stat(a).st_mode), stat.filemode(os.stat(a).st_mode))

            self.log('INFO: changed permissions of %s files to %s and directories to %s' % (
                self.app_home, i[0], i[1]
            ))

            os.chmod(self.app_home, stat.S_IRUSR | stat.S_IWUSR | stat.S_IXUSR)
            for root, dirs, files in os.walk(self.app_home):
                for name in dirs:
                    os.chmod(os.path.join(root, name), stat.S_IRUSR | stat.S_IWUSR | stat.S_IXUSR)
            shutil.rmtree(self.app_home)

    def test_permissions_non_recursive(self):
        """
        tests permissions assigns permissions recursively and writes to log
        """
        test_permissions = [
            [{'path': '/tmp/scripts_test/app_user/sites/app_name/source', 'dir_permissions': '500'}, 'dr-x------'],
            [{'path': '/tmp/scripts_test/app_user/sites/app_name/source/app_name', 'dir_permissions': '770'}, 'drwxrwx---'],
            [{'path': '/tmp/scripts_test/app_user/sites/app_name/source/app_name/file', 'file_permissions': '400'}, '-r--------'],
        ]
        app_home_nested_file = os.path.join(self.app_home, 'app_name', 'file')

        runlog = CommandFileUtils(self.dist_version, self.log_file, self.log_level)

        for i in test_permissions:
            os.makedirs(os.path.join(self.app_home, 'app_name'))
            with open(app_home_nested_file, 'w') as file:
                file.write('some text')

            runlog.permissions(**i[0])

            self.assertEqual(i[1], stat.filemode(os.stat(i[0]['path']).st_mode), stat.filemode(os.stat(i[0]['path']).st_mode))
            if os.path.isdir(i[0]['path']):
                self.log('INFO: changed permissions of %s to %s' % (i[0]['path'], i[0]['dir_permissions']))
            elif os.path.isfile(i[0]['path']):
                self.log('INFO: changed permissions of %s to %s' % (i[0]['path'], i[0]['file_permissions']))

            os.chmod(self.app_home, stat.S_IRUSR | stat.S_IWUSR | stat.S_IXUSR)
            for root, dirs, files in os.walk(self.app_home):
                for name in dirs:
                    os.chmod(os.path.join(root, name), stat.S_IRUSR | stat.S_IWUSR | stat.S_IXUSR)
            shutil.rmtree(self.app_home)

    @mock.patch.object(CommandFileUtils, 'own', side_effect=own_app_mock)
    def test_own_manages_ownership(self, own_app_mock):
        """
        tests that own manages ownership and writes to log.
        """
        app_home_nested_file = os.path.join(self.app_home, 'app_name', 'file')
        os.makedirs(os.path.join(self.app_home, 'app_name'))
        with open(app_home_nested_file, 'w') as file:
            file.write('some text')
        user = 'app_user'
        group = 'app_user'
        runlog = CommandFileUtils(self.dist_version, self.log_file, self.log_level)

        runlog.own(self.app_home, user, group)

        self.assertEqual([call(self.app_home, user, group)], own_app_mock.mock_calls, own_app_mock.mock_calls)

        self.log('INFO: changed ownership of %s to %s:%s' % (self.app_home, user, user))

    def test_check_process(self):
        """
        tests that check_process returns True when process is running and False otherwise
        """
        runlog = CommandFileUtils(self.dist_version, self.log_file, self.log_level)

        proc = runlog.check_process('python')
        self.assertTrue(proc, '%s process is running: %s' % ('python', proc))
        proc = runlog.check_process('SomeVeryUnlikelyProcessName')
        self.assertFalse(proc, proc)

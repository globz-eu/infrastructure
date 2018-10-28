from unittest import TestCase
from unittest.mock import call
from unittest import mock
import os
import re
import shutil
import stat
import datetime
from utilities.commandfileutils import CommandFileUtils
from tests.conf_tests import DIST_VERSION, LOG_FILE, TEST_DIR, LOG_LEVEL
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
        self.log_level = LOG_LEVEL
        if os.path.exists(self.log_file):
            os.remove(self.log_file)
        remove_test_dir()

    def log(self, message, test=True):
        """
        tests the presence or absence of a message or regex in the log file
        :param message: message to test
        :param test: tests presence (True) or absence (False)
        """
        with open(self.log_file) as log:
            log_list = [l[20:] for l in log]
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
        self.test_dir = TEST_DIR
        if self.dist_version == '14.04':
            self.python_version = 'python3.4'
        elif self.dist_version == '16.04':
            self.python_version = 'python3.5'

    def test_commandfileutils_exits_on_unknown_dist_version(self):
        try:
            CommandFileUtils('Invalid_dist_version', self.log_file, self.log_level)
        except SystemExit as error:
            self.assertEqual(1, error.code, 'CommandFileUtils exited with: %s' % str(error))
            self.log('CRITICAL: distribution not supported')

    def test_write_to_log(self):
        """
        tests that write_to_log writes messages to log
        """
        runlog = CommandFileUtils(self.dist_version, self.log_file, 'DEBUG')
        msgs = [
            ['debug message', 'DEBUG'],
            ['info message', 'INFO'],
            ['warning message', 'WARNING'],
            ['error message', 'ERROR'],
            ['critical message', 'CRITICAL']
        ]
        for m, ll in msgs:
            runlog.write_to_log(m, ll)
            self.log('%s: %s' % (ll, m))

    def test_write_sequencially_to_log(self):
        """
        tests that write_to_log writes all messages to log
        """
        runlog = CommandFileUtils(self.dist_version, self.log_file, 'DEBUG')
        msgs = [
            ['debug message', 'DEBUG'],
            ['info message', 'INFO'],
            ['warning message', 'WARNING'],
            ['error message', 'ERROR'],
            ['critical message', 'CRITICAL']
        ]
        for m, ll in msgs:
            runlog.write_to_log(m, ll)
        for m, ll in msgs:
            self.log('%s: %s' % (ll, m))

    def test_write_to_log_adds_timestamp_to_message(self):
        """
        tests that write_to_log adds the current time to messages
        """
        runlog = CommandFileUtils(self.dist_version, self.log_file, 'DEBUG')
        msgs = [
            ['debug message', 'DEBUG'],
            ['info message', 'INFO'],
            ['warning message', 'WARNING'],
            ['error message', 'ERROR'],
            ['critical message', 'CRITICAL']
        ]
        now = datetime.datetime.utcnow()
        for m, ll in msgs:
            runlog.write_to_log(m, ll)
        with open(self.log_file) as log:
            log_list = [l[:19] for l in log][-5:]
            for l in log_list:
                self.assertEqual(now.strftime('%Y-%m-%d %H:%M:%S'), l, l)

    def test_write_to_log_exits_when_log_level_is_not_specified(self):
        """
        tests that write_to_log uses default log level (DEBUG) when level is not specified and exits when log level is
        invalid
        """
        runlog = CommandFileUtils(self.dist_version, self.log_file, 'DEBUG')
        msgs = [
            ['warning message', 'WARNING'],
            ['other warning message', 'WARNING'],
            ['debug message', 'IMPORTANT'],
            ['info message', 'INFO'],
            ['default info message', False],
        ]
        for m, ll in msgs:
            try:
                runlog.write_to_log(m, ll)
                self.log('%s: %s' % (ll, m))
            except SystemExit as error:
                self.assertEqual(1, error.code, '%s exited with: %s' % ('write_to_log', str(error)))
                self.log('ERROR: log level "%s" is not specified or not valid' % ll)

    def test_write_to_log_only_logs_messages_of_appropriate_log_level(self):
        """
        tests that write_to_log only writes messages with appropriate log level to log
        """
        runlog = CommandFileUtils(self.dist_version, self.log_file, 'ERROR')
        msgs_log = [
            ['error message', 'ERROR'],
            ['CRITICAL message', 'CRITICAL']
        ]
        msgs_no_log = [
            ['debug message', 'DEBUG'],
            ['info message', 'INFO'],
        ]
        for m, ll in msgs_log:
            runlog.write_to_log(m, ll)
            self.log('%s: %s' % (ll, m))
        for m, ll in msgs_no_log:
            runlog.write_to_log(m, ll)
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
        app_home_nested_file = os.path.join(self.test_dir, 'dir', 'file')
        os.makedirs(os.path.join(self.test_dir, 'dir'))
        with open(app_home_nested_file, 'w') as file:
            file.write('some text')
        runlog = CommandFileUtils(self.dist_version, self.log_file, self.log_level)
        runlog.walktree(self.test_dir, runlog.write_to_log, ('INFO', ), runlog.write_to_log, ('INFO', ))
        paths = ['/tmp/scripts_test/dir',
                 '/tmp/scripts_test/dir/file']
        for p in paths:
            self.log('INFO: %s' % p)

    def test_walktree_with_no_file_function(self):
        app_home_nested_file = os.path.join(self.test_dir, 'dir', 'file')
        os.makedirs(os.path.join(self.test_dir, 'dir'))
        with open(app_home_nested_file, 'w') as file:
            file.write('some text')
        runlog = CommandFileUtils(self.dist_version, self.log_file, self.log_level)
        runlog.walktree(self.test_dir, d_callback=runlog.write_to_log, d_args=('INFO', ))
        paths = ['/tmp/scripts_test/dir']
        for p in paths:
            self.log('INFO: %s' % p)
            self.log('ERROR:', test=False, regex=True)

    def test_walktree_with_no_file_function_args(self):
        app_home_nested_file = os.path.join(self.test_dir, 'dir', 'file')
        os.makedirs(os.path.join(self.test_dir, 'dir'))
        with open(app_home_nested_file, 'w') as file:
            file.write('some text')
        runlog = CommandFileUtils(self.dist_version, self.log_file, self.log_level)
        runlog.walktree(self.test_dir, f_callback=runlog.write_to_log)
        paths = ['/tmp/scripts_test/dir/file']
        for p in paths:
            self.log('DEBUG: %s' % p)

    def test_walktree_with_no_directory_function(self):
        app_home_nested_file = os.path.join(self.test_dir, 'dir', 'file')
        os.makedirs(os.path.join(self.test_dir, 'dir'))
        with open(app_home_nested_file, 'w') as file:
            file.write('some text')
        runlog = CommandFileUtils(self.dist_version, self.log_file, self.log_level)
        runlog.walktree(self.test_dir, f_callback=runlog.write_to_log, f_args=('INFO', ))
        paths = ['/tmp/scripts_test/dir/file']
        for p in paths:
            self.log('INFO: %s' % p)
            self.log('ERROR:', test=False, regex=True)

    def test_walktree_with_no_directory_function_args(self):
        app_home_nested_file = os.path.join(self.test_dir, 'dir', 'file')
        os.makedirs(os.path.join(self.test_dir, 'dir'))
        with open(app_home_nested_file, 'w') as file:
            file.write('some text')
        runlog = CommandFileUtils(self.dist_version, self.log_file, self.log_level)
        runlog.walktree(self.test_dir, d_callback=runlog.write_to_log)
        paths = ['/tmp/scripts_test/dir']
        for p in paths:
            self.log('DEBUG: %s' % p)

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
        app_home_nested_file = os.path.join(self.test_dir, 'dir', 'file')

        runlog = CommandFileUtils(self.dist_version, self.log_file, self.log_level)

        for i in test_permissions:
            os.makedirs(os.path.join(self.test_dir, 'dir'))
            with open(app_home_nested_file, 'w') as file:
                file.write('some text')

            runlog.permissions(self.test_dir, i[0], i[1], recursive=True)
            app_home_files = []
            app_home_dirs = []
            for root, dirs, files in os.walk(self.test_dir):
                for name in files:
                    app_home_files.append(os.path.join(root, name))
                for name in dirs:
                    app_home_dirs.append(os.path.join(root, name))
                app_home_dirs.append(self.test_dir)
            for a in app_home_files:
                self.assertEqual(i[2], stat.filemode(os.stat(a).st_mode), stat.filemode(os.stat(a).st_mode))
            for a in app_home_dirs:
                self.assertEqual(i[3], stat.filemode(os.stat(a).st_mode), stat.filemode(os.stat(a).st_mode))

            self.log('INFO: changed permissions of %s files to %s and directories to %s' % (
                self.test_dir, i[0], i[1]
            ))

            os.chmod(self.test_dir, stat.S_IRUSR | stat.S_IWUSR | stat.S_IXUSR)
            for root, dirs, files in os.walk(self.test_dir):
                for name in dirs:
                    os.chmod(os.path.join(root, name), stat.S_IRUSR | stat.S_IWUSR | stat.S_IXUSR)
            shutil.rmtree(self.test_dir)

    def test_permissions_non_recursive(self):
        """
        tests permissions assigns permissions recursively and writes to log
        """
        test_permissions = [
            [{'path': '/tmp/scripts_test', 'dir_permissions': '500'}, 'dr-x------'],
            [{'path': '/tmp/scripts_test/dir', 'dir_permissions': '770'},
             'drwxrwx---'],
            [{'path': '/tmp/scripts_test/dir/file', 'file_permissions': '400'},
             '-r--------'],
        ]
        app_home_nested_file = os.path.join(self.test_dir, 'dir', 'file')

        runlog = CommandFileUtils(self.dist_version, self.log_file, self.log_level)

        for i in test_permissions:
            os.makedirs(os.path.join(self.test_dir, 'dir'))
            with open(app_home_nested_file, 'w') as file:
                file.write('some text')

            runlog.permissions(**i[0])

            self.assertEqual(i[1], stat.filemode(os.stat(i[0]['path']).st_mode), stat.filemode(os.stat(i[0]['path']).st_mode))
            if os.path.isdir(i[0]['path']):
                self.log('INFO: changed permissions of %s to %s' % (i[0]['path'], i[0]['dir_permissions']))
            elif os.path.isfile(i[0]['path']):
                self.log('INFO: changed permissions of %s to %s' % (i[0]['path'], i[0]['file_permissions']))

            os.chmod(self.test_dir, stat.S_IRUSR | stat.S_IWUSR | stat.S_IXUSR)
            for root, dirs, files in os.walk(self.test_dir):
                for name in dirs:
                    os.chmod(os.path.join(root, name), stat.S_IRUSR | stat.S_IWUSR | stat.S_IXUSR)
            shutil.rmtree(self.test_dir)

    def test_check_pending_returns_correct_list(self):
        """
        tests that check_pending only returns directories for pending or acceptance tests
        """
        sample_dirs = ['/bla/pending_tests', '/bli/blo/acceptance_tests', '/bla/blup/some_other_dir']
        expected_dirs = ['/bla/pending_tests', '/bli/blo/acceptance_tests']
        cfu = CommandFileUtils(self.dist_version, self.log_file, self.log_level)
        for s in sample_dirs:
            cfu.check_pending(s)
        self.assertEqual(expected_dirs, cfu.pending_dirs, cfu.pending_dirs)

    def test_get_pending_dirs_returns_dirs_with_pending_tests(self):
        """
        tests that get_pending_dirs returns a list of directory paths for pending tests
        """
        os.makedirs(os.path.join(self.test_dir, 'dir', 'acceptance_tests'), exist_ok=True)
        os.makedirs(os.path.join(self.test_dir, 'dir', 'dir', 'functional_tests', 'pending_tests'), exist_ok=True)
        os.makedirs(os.path.join(self.test_dir, 'dir', 'base', 'unit_tests', 'pending_tests'), exist_ok=True)
        cfu = CommandFileUtils(self.dist_version, self.log_file, self.log_level)
        pending_dirs = cfu.get_pending_dirs(self.test_dir, 'dir')
        expected_pending_dirs = [
            os.path.join('.', 'acceptance_tests'),
            os.path.join('.', 'base', 'unit_tests', 'pending_tests'),
            os.path.join('.', 'dir', 'functional_tests', 'pending_tests'),
        ]
        self.assertEqual(expected_pending_dirs, pending_dirs, pending_dirs)

    @mock.patch.object(CommandFileUtils, 'own', side_effect=own_app_mock)
    def test_own_manages_ownership(self, own_app_mock):
        """
        tests that own manages ownership and writes to log.
        """
        app_home_nested_file = os.path.join(self.test_dir, 'dir', 'file')
        os.makedirs(os.path.join(self.test_dir, 'dir'))
        with open(app_home_nested_file, 'w') as file:
            file.write('some text')
        user = 'app_user'
        group = 'app_user'
        runlog = CommandFileUtils(self.dist_version, self.log_file, self.log_level)

        runlog.own(self.test_dir, user, group)

        self.assertEqual([call(self.test_dir, user, group)], own_app_mock.mock_calls, own_app_mock.mock_calls)

        self.log('INFO: changed ownership of %s to %s:%s' % (self.test_dir, user, user))

    def test_check_process(self):
        """
        tests that check_process returns True when process is running and False otherwise
        """
        runlog = CommandFileUtils(self.dist_version, self.log_file, self.log_level)

        proc = runlog.check_process('python')
        self.assertTrue(proc, '%s process is running: %s' % ('python', proc))
        proc = runlog.check_process('SomeVeryUnlikelyProcessName')
        self.assertFalse(proc, proc)


class WriteToLogTest(TestCase):
    """
    Tests write_to_log functionality in TestCase situation (when log file is deleted between tests)
    """
    def setUp(self):
        self.dist_version = DIST_VERSION
        self.log_file = LOG_FILE
        if os.path.isfile(self.log_file):
            os.remove(self.log_file)

    def log(self, message, test=True, regex=False):
        """
        tests the presence or absence of a message or regex in the log file
        :param message: message to test
        :param test: tests presence (True) or absence (False)
        :param regex: tests using regex if True
        """
        with open(self.log_file) as log:
            log_list = [l[20:] for l in log]
            if test:
                if regex:
                    matches = [l for l in log_list if re.match(message, l)]
                    self.assertTrue(matches, '%s not found' % message)
                else:
                    self.assertTrue('%s\n' % message in log_list, 'message: \'%s\', log_list: %s' % (message, log_list))
            else:
                if regex:
                    matches = [l for l in log_list if re.match(message, l)]
                    self.assertFalse(matches, '"%s" found in %s' % (message, matches))
                else:
                    self.assertFalse('%s\n' % message in log_list, log_list)

    def test_basic_functionality(self):
        """
        tests basic logging functionality
        """
        runlog = CommandFileUtils(self.dist_version, self.log_file, 'DEBUG')
        msgs = [
            ['debug message', 'DEBUG'],
            ['info message', 'INFO'],
            ['warning message', 'WARNING'],
            ['error message', 'ERROR'],
            ['critical message', 'CRITICAL']
        ]
        for m, ll in msgs:
            runlog.write_to_log(m, ll)
        for m, ll in msgs:
            self.log('%s: %s' % (ll, m))

    def test_level_functionality(self):
        """
        tests logging functionality when log level is higher than DEBUG
        """
        runlog = CommandFileUtils(self.dist_version, self.log_file, 'INFO')
        msgs = [
            ['debug message', 'DEBUG'],
            ['info message', 'INFO'],
            ['warning message', 'WARNING'],
            ['error message', 'ERROR'],
            ['critical message', 'CRITICAL']
        ]
        for m, ll in msgs:
            runlog.write_to_log(m, ll)
        for m, ll in msgs[1:]:
            self.log('%s: %s' % (ll, m))
        self.log('%s: %s' % (msgs[0][1], msgs[0][0]), test=False)

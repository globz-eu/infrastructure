import os
import re
import subprocess
from subprocess import CalledProcessError
from unittest import TestCase
from unittest.mock import MagicMock
from tests.conf_tests import DIST_VERSION, LOG_FILE, LOG_LEVEL, CELERY_PID_PATH
from tests.helpers import remove_test_dir

__author__ = 'Stefan Dieterle'


class RunAndLogTest(TestCase):
    def setUp(self):
        self.dist_version = DIST_VERSION
        self.log_file = LOG_FILE
        self.log_level = LOG_LEVEL
        self.celery_pid_path = CELERY_PID_PATH
        if self.dist_version == '14.04':
            self.run = subprocess.check_call
            subprocess.check_call = MagicMock()
        elif self.dist_version == '16.04':
            self.run = subprocess.run
            subprocess.run = MagicMock()
        if os.path.isfile(self.log_file):
            os.remove(self.log_file)
        remove_test_dir()

    def tearDown(self):
        if self.dist_version == '14.04':
            subprocess.check_call = self.run
        else:
            if self.dist_version == '16.04':
                subprocess.run = self.run

    def run_success(self, cmds, msg, tested_function, func, call_args):
        """
        test helper, tests that function runs command, writes to log and returns 0
        """
        run = func(*call_args)
        if self.dist_version == '14.04':
            calls = [args for args, kwargs in subprocess.check_call.call_args_list]
        elif self.dist_version == '16.04':
            calls = [args for args, kwargs in subprocess.run.call_args_list]
        cmds_ret = [(c,) for c in cmds]
        self.assertEqual(0, run, tested_function + ' returned: ' + str(run))
        for cmd in cmds_ret:
            self.assertTrue(cmd in calls, '%s not in %s' % (cmd, calls))
        for m in msg:
            self.log('INFO: ' + m)

    def run_error(self, cmd, tested_function, func, args):
        """
        test helper, tests that function exits on error and writes to log
        """
        if self.dist_version == '14.04':
            subprocess.check_call.side_effect = CalledProcessError(returncode=1, cmd=cmd)
        else:
            if self.dist_version == '16.04':
                subprocess.run.side_effect = CalledProcessError(returncode=1, cmd=cmd)
        try:
            func(*args)
        except SystemExit as error:
            self.assertEqual(1, error.code, tested_function + ' exited with: ' + str(error))
        self.log('ERROR: %s exited with exit code 1' % ' '.join(cmd))

    def run_cwd(self, cwd, tested_function, func, call_args):
        run = func(*call_args)
        if self.dist_version == '14.04':
            args, kwargs = subprocess.check_call.call_args
        if self.dist_version == '16.04':
            args, kwargs = subprocess.run.call_args
        cmd_args = {'cwd': cwd}
        self.assertEqual(0, run, tested_function + ' returned: ' + str(run))
        self.assertEqual(cmd_args['cwd'], kwargs['cwd'], '%s not found for %s in %s' % (cwd, tested_function, kwargs))

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

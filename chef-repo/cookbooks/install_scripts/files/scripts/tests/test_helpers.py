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
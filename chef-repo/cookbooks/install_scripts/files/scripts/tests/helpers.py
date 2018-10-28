import os
import shutil
import stat
from tests.conf_tests import TEST_DIR

__author__ = 'Stefan Dieterle'


def make_test_dir():
    os.makedirs(TEST_DIR, exist_ok=True)


def remove_test_dir():
    if os.path.isdir(TEST_DIR):
        try:
            shutil.rmtree(TEST_DIR)
        except PermissionError:
            os.chmod(TEST_DIR, stat.S_IRUSR | stat.S_IWUSR | stat.S_IXUSR)
            try:
                shutil.rmtree(TEST_DIR)
            except PermissionError:
                for root, dirs, files in os.walk(TEST_DIR):
                    for name in dirs:
                        os.chmod(os.path.join(root, name), stat.S_IRUSR | stat.S_IWUSR | stat.S_IXUSR)
                shutil.rmtree(TEST_DIR)
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

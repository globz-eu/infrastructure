import os
import shutil
import stat
from tests.conf_tests import TEST_DIR


def make_test_dir():
    os.makedirs(TEST_DIR, exist_ok=True)


def remove_test_dir():
    for test_path in [TEST_DIR]:
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

import os
import re
from tests.test_commandfileutils import RunAndLogTest
import requests_mock
from install import InstallFromURL
from tests.conf_tests import DOWNLOAD_FOLDER, METADATA_FILE


class InstallTest(RunAndLogTest):
    """
    Tests chef server installation commands
    """

    def setUp(self):
        RunAndLogTest.setUp(self)
        self.download_folder = DOWNLOAD_FOLDER
        self.url = 'https://omnitruck.chef.io/stable/chef_server/metadata'

    @requests_mock.Mocker()
    def test_retrieve_metadata_file(self, m):
        """
        tests that retrieve_metadata processes the metadata as expected
        """
        # mock https://omnitruck.chef.io/stable/chef_server/metadata response
        with open(METADATA_FILE) as metadata_file:
            metadata_text = ''.join([l for l in metadata_file])
        m.get(
            'https://omnitruck.chef.io/stable/chef_server/metadata?v=&p=ubuntu&pv=16.04&m=x86_64',
            text=metadata_text, status_code=200
        )

        install = InstallFromURL(metadata_url=self.url, download_folder=self.download_folder, log_file=self.log_file)
        i = install.retrieve_metadata()
        self.assertEqual(200, i['status_code'], i['status_code'])
        self.assertTrue(os.path.isdir(self.download_folder), 'download folder does not exist')
        url_pattern = re.compile(r'^https://packages\.chef\.io/files/stable/chef-server/'
                                 r'\d{1,2}\.\d{1,2}\.\d{1,2}/'
                                 r'ubuntu/16.04/chef-server-core_\d{1,2}\.\d{1,2}\.\d{1,2}-1_amd64\.deb$')
        self.assertTrue(re.match(url_pattern, i['url']), i['url'])
        self.assertTrue(i['sha256'], 'sha256 field was not populated')
        self.assertTrue(os.path.isfile(os.path.join(self.download_folder, 'chef-server.sha256')))
        with open(os.path.join(self.download_folder, 'chef-server.sha256')) as package_file:
            pckg_file_list = [l for l in package_file]
        self.assertEqual(
            ['d7ede7eda83ed7229fc2f0115f7bdc6dcd8fab3c61db08666765febd52622ec0\tchef-server.deb\n'],
            pckg_file_list
        )
        self.log('INFO: successfully retrieved metadata for chef-server.deb')

    def test_install_chef_server_downloads_and_installs_chef_server(self):
        """
        tests that install_chef_server downloads, checks sha256 of and installs chef-server package
        """
        install = InstallFromURL(metadata_url=self.url, download_folder=self.download_folder, log_file=self.log_file)
        cmds = [
            [
                'wget',
                'https://packages.chef.io/files/stable/'
                'chef-server/12.9.1/ubuntu/16.04/chef-server-core_12.9.1-1_amd64.deb',
                '-O',
                'chef-server.deb'
            ],
            [
                'sha256sum', '-c', 'chef-server.sha256', '2>&1', '|', 'grep', 'OK'
            ],
            [
                'dpkg', '-i', 'chef-server.deb'
            ]
        ]
        cwd = self.download_folder
        msg = ['successfully downloaded chef-server', 'sha256sum verified', 'successfully installed chef-server package']
        func = 'install_chef-server'
        self.run_success(cmds, msg, func, install.install_chef_server, ())
        self.run_cwd(cwd, func, install.install_chef_server, ())

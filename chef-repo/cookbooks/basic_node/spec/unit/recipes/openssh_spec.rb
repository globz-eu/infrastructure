# =====================================================================
# Web app infrastructure for Django project
# Copyright (C) 2016 Stefan Dieterle
# e-mail: golgoths@yahoo.fr
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# =====================================================================

require 'spec_helper'

describe 'basic_node::ssh' do
  context 'When all attributes are default, on an Ubuntu 14.04 platform' do
    let(:chef_run) do
      runner = ChefSpec::ServerRunner.new(platform: 'ubuntu', version: '14.04')
      runner.converge(described_recipe)
    end

    let(:secret_path) { '../../../.chef/encrypted_data_bag_secret' }
    let(:secret) { 'secret' }
    let(:fake_password) { 'sample_password' }
    let(:admin_key_data_bag_item) do
      { password: fake_password }
    end

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(secret_path).and_return('true')

      allow(IO).to receive(:read).and_call_original
      allow(IO).to receive(:read).with(secret_path).and_return(secret)

      allow(Chef::EncryptedDataBagItem).to receive(:load).with('keys', 'node_admin_key', secret).and_return(admin_key_data_bag_item)
    end

    it 'installs the openssl-server package' do
      expect(chef_run).to install_package( 'openssl-server' )
    end

    it 'starts the ssh service' do
      expect(chef_run).to start_service( 'ssh' )
    end

    it 'enables the ssh service' do
      expect(chef_run).to enable_service( 'ssh' )
    end

    it 'appends or creates the authorized_keys file' do
      expect(chef_run).to create_template_if_missing('/home/admin/.ssh/authorized_keys').with(
                                                                                       owner: default['basic_node']['admin_user']['node_admin'],
                                                                                       mode: '0640',
                                                                                       source: 'authorized_keys',
                                                                                       variables: { admin_key: admin_key_data_bag_item['key']}
      )
    end

    it 'creates the sshd_config file' do
      expect(chef_run).to create_template_if_missing('/etc/ssh/sshd_config').with(
                                                                            owner: 'root',
                                                                            mode: '0644',
                                                                            source: 'sshd_config',
                                                                            variables: {
                                                                                permit_root_login: default['openssh']['sshd']['permit_root_login'],
                                                                                password_autentication: default['openssh']['sshd']['password_autentication'],
                                                                                pubkey_authentication: default['openssh']['sshd']['pubkey_authentication'],
                                                                                rsa_authentication: default['openssh']['sshd']['rsa_authentication'],
                                                                            }
      )
    end
  end
end
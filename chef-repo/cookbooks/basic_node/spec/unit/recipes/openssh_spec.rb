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

describe 'basic_node::openssh' do
  context 'When all attributes are default, on an Ubuntu 14.04 platform' do
    include ChefVault::TestFixtures.rspec_shared_context(true)
    let(:chef_run) do
      runner = ChefSpec::ServerRunner.new(platform: 'ubuntu', version: '14.04')
      runner.converge(described_recipe)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'installs the openssh-server package' do
      expect(chef_run).to install_package( 'openssh-server' )
    end

    it 'starts the ssh service' do
      expect(chef_run).to start_service( 'ssh' )
    end

    it 'enables the ssh service' do
      expect(chef_run).to enable_service( 'ssh' )
    end

    it 'creates the admin user .ssh directory' do
      expect(chef_run).to create_directory("/home/#{chef_run.node['basic_node']['admin_user']['node_admin']}/.ssh")
    end

    it 'appends or creates the authorized_keys file' do
      expect(chef_run).to create_template("/home/#{chef_run.node['basic_node']['admin_user']['node_admin']}/.ssh/authorized_keys").with(
         owner: chef_run.node['basic_node']['admin_user']['node_admin'],
         mode: '0640',
         source: 'authorized_keys.erb',
         variables: { admin_key: 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApPVju50vJyXJ0jYxn0PqauzbVLUqyV9aS/ezFjwD4AIQGBmYL9sl4FZxZMA2mNyWtJWeauLF+SyoUhg95JYBEfLYFJOH3mufl2V/SCwavkDqGnbepyrTRHXRkG6etNaaKEbbDoWdqxHo1eQVhjX8sR4slnIjQffgm8/pxOw3R30ilB1NfT73wtrVBGE/ryPloRRp1A16uBxO+5Fnac28LlHwHZXKXrbV8GeiWNTyE/RC+32NXHbOtZkBGc3jKVShCZ4+iKuU1wUGhMjdwUa4Jwmp0VKh8OlH6HkoErg2JLIrbSloz4Z769UkG8fPCb0DG04C0a79yU3w81n1GaqkjQIDAQAB'}
      )
    end

    it 'creates the sshd_config file' do
      expect(chef_run).to create_template('/etc/ssh/sshd_config').with(
        owner: 'root',
        mode: '0644',
        source: 'sshd_config.erb',
        variables: {
            permit_root_login: chef_run.node['openssh']['sshd']['permit_root_login'],
            password_authentication: chef_run.node['openssh']['sshd']['password_authentication'],
            pubkey_authentication: chef_run.node['openssh']['sshd']['pubkey_authentication'],
            rsa_authentication: chef_run.node['openssh']['sshd']['rsa_authentication'],
            allowed_users: chef_run.node['basic_node']['admin_user']['node_admin']
        }
      )
    end
  end
end
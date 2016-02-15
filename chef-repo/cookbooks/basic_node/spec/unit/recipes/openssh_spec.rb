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
      expect{ chef_run }.to_not raise_error
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
      expect(chef_run).to create_directory('/home/node_admin/.ssh')
    end

    it 'appends or creates the authorized_keys file' do
      expect(chef_run).to create_template('/home/node_admin/.ssh/authorized_keys').with(
         owner: 'node_admin',
         mode: '0640',
         source: 'authorized_keys.erb',
         variables: {
             admin_key: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDV6LFiLYnDGQu/DFgMcuAD1BAqQp9cjKM5872hHS4d3tIeT5kcW7jUhEkJqo5OFtmPChdI4IchlzkuOzUHvNAuwgUkbhp0HSXDUiXCUDJLTkBsCg7iYIBEmqQF/xPHYvYoMmJxx4nS6SuXh9iYAHanGmEnVQtAChzbkEsARGhOG9CpUnqz7v+35qymNeEaj2Imw7ItQTh3WFZRzD+vaAh5+tmgE2JvjiGWt5NQa/5E91VOOj9hfzMzArGoCVDfTmdReyMYHKpVH3vb4uRfXU9/aewPj8ue1VJ25FbA3Z1vb9bjWAF4qwvJpXhWWY3rZeBD2cL4i5uLfDa2uBjb3JmdBR71oD/OiomJWfdC9zKjQTh8FGt32GQxFi35jUthBV2gIiyxAuFkBjyTnXoTXMUtjUoTl6KIwBuOoEvEA337IwyPT7yb4mFbK5giV4KwlXmX8Ju/sL9NYq8Dku95ZtLlz4wyaY2SF8RDPh8GsB/EVE/UYvlOSOZvYYKZkRCHWMGTVHUUmOWlq7UUPD8Pl3hUFaVAHzeRTumeXC3jhntVW1wRpIYDSXvdVzurfxpMrmvA+HQUxxHm17Kj5aq47Zoh2vZWsIUyPpsHv/mmvumZSoeCw+0b302XvSVYTy7j73amvewB4UJFI14ocnSH0jAE+axn7PYJr1WB6QB14FE2Bw== admin@adminPC',
         })
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
            allowed_users: 'node_admin'
        }
      )
    end
  end
end
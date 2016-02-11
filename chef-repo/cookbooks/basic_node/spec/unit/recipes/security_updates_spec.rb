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

describe 'basic_node::security_updates' do
  context 'When all attributes are default, on an Ubuntu 14.04 platform' do
    include ChefVault::TestFixtures.rspec_shared_context(true)
    let(:chef_run) do
      runner = ChefSpec::ServerRunner.new(platform: 'ubuntu', version: '14.04')
      runner.converge(described_recipe)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'installs the unattended-upgrades package' do
      expect(chef_run).to install_package('unattended-upgrades')
    end

    it 'manages the 50unattended-upgrades file' do
      expect(chef_run).to create_template('/etc/apt/apt.conf.d/50unattended-upgrades').with(
        owner: 'root',
        mode: '0644',
        variables: { admin_email: 'admin@example.com' }
      )
    end

    it 'manages the 10periodic file' do
      expect(chef_run).to create_file('/etc/apt/apt.conf.d/10periodic')
    end

    it 'installs the apticron package' do
      expect(chef_run).to install_package('apticron')
    end

    it 'manages the apticron.conf file' do
      expect(chef_run).to create_template('/etc/apticron/apticron.conf').with(
        owner: 'root',
        mode: '0644',
        variables: { admin_email: 'admin@example.com' }
      )
    end
  end
end
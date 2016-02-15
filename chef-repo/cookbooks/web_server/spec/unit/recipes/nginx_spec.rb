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

describe 'web_server::nginx' do
  context 'When all attributes are default, on an Ubuntu 14.04 platform' do
    include ChefVault::TestFixtures.rspec_shared_context(true)
    let(:chef_run) do
      runner = ChefSpec::ServerRunner.new(platform: 'ubuntu', version: '14.04')
      runner.converge(described_recipe)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'installs the nginx package' do
      expect(chef_run).to install_package( 'nginx' )
    end

    it 'starts the nginx service' do
      expect(chef_run).to start_service( 'nginx' )
    end

    it 'enables the nginx service' do
      expect(chef_run).to enable_service( 'nginx' )
    end

    it 'creates firewall rules' do
      expect( chef_run ).to create_firewall_rule('http')
    end
  end
end

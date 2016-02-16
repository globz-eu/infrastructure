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
#
# Cookbook Name:: db_server
# Spec:: postgresql

require 'spec_helper'

describe 'db_server::postgresql' do
  context 'When all attributes are default, on an Ubuntu 14.04 platform' do
    include ChefVault::TestFixtures.rspec_shared_context(true)
    let(:chef_run) do
      runner = ChefSpec::ServerRunner.new(platform: 'ubuntu', version: '14.04')
      runner.converge(described_recipe)
    end

    before do
      stub_command(/ls \/.*\/recovery.conf/).and_return(false)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'installs the "postgresql-9.5 postgresql-contrib-9.5 postgresql-client-9.5 postgresql-server-9.5 postgresql-server-dev-9.5" package' do
      expect(chef_run).to install_package('postgresql-9.5')
      expect(chef_run).to install_package('postgresql-contrib-9.5')
      expect(chef_run).to install_package('postgresql-client-9.5')
      expect(chef_run).to install_package('postgresql-server-dev-9.5')
      expect(chef_run).to install_package('postgresql-server-9.5')
    end

    it 'starts the postgresql service' do
      expect(chef_run).to start_service( 'postgresql' )
    end

    it 'enables the postgresql service' do
      expect(chef_run).to enable_service( 'postgresql' )
    end

  end
end
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
  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe)}

  it 'installs the openssl-server package' do
    expect(chef_run).to install_package( 'openssl-server' )
  end

  it 'starts the ssh service' do
    expect(chef_run).to start_service( 'ssh' )
  end

  it 'enables the ssh service' do
    expect(chef_run).to enable_service( 'ssh' )
  end

  it 'creates appends or creates the authorized_keys file' do
    expect(chef_run).to create_file_if_missing('/home/admin/.ssh/authorized_keys').with(
                                                                                     user: 'admin'
    )
  end
end
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

describe 'basic_node::admin_user' do
  context 'When all attributes are default, on an Ubuntu 14.04 platform' do
    let(:chef_run) do
      runner = ChefSpec::ServerRunner.new(platform: 'ubuntu', version: '14.04')
      runner.converge(described_recipe)
    end

    let(:secret_path) { '/etc/chef/encrypted_data_bag_secret' }
    let(:secret) { 'secret' }
    let(:fake_password) { 'sample_password' }
    # let(:admin_password_data_bag_item) do
    #   { password: fake_password }
    let(:node_admin_password) do
      { password: fake_password }
    end

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(secret_path).and_return('true')

      allow(IO).to receive(:read).and_call_original
      allow(IO).to receive(:read).with(secret_path).and_return(secret)

      allow(Chef::EncryptedDataBagItem).to receive(:load).with('basic_node', 'node_admin', secret).and_return(node_admin_password)
      # allow(ChefVault::Item).to receive(:load).with('basic_node', 'node_admin').and_return(node_admin_password)
    end

    it 'creates the admin user' do
      expect(chef_run).to create_user(chef_run.node['basic_node']['admin_user']['node_admin']).with(
                                                  home: '/home/' + chef_run.node['basic_node']['admin_user']['node_admin'],
                                                  shell: '/bin/bash',
                                                  password: node_admin_password['password']
      )
    end

    it 'adds admin to group sudo' do
      expect(chef_run).to manage_group('sudo').with(
                                                  append: true,
                                                  members: chef_run.node['basic_node']['admin_user']['node_admin']
      )
    end
  end
end
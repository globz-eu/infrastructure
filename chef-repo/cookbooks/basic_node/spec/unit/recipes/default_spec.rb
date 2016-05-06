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
# Cookbook Name:: basic_node
# Spec:: default
#

require 'spec_helper'

describe 'basic_node::default' do
  ['14.04', '16.04'].each do |version|
    context "When all attributes are default, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        runner = ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version)
        runner.converge(described_recipe)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'installs the unattended-upgrades package' do
        expect(chef_run).to install_package('unattended-upgrades')
      end

      it 'does not install the bsd-mailx package' do
        expect(chef_run).to_not install_package('bsd-mailx')
      end

      it 'manages the 50unattended-upgrades file' do
        expect(chef_run).to create_template('/etc/apt/apt.conf.d/50unattended-upgrades').with(
            owner: 'root',
            group: 'root',
            mode: '0644'
        )
      end

      it 'manages the 20auto-upgrades file' do
        expect(chef_run).to create_template('/etc/apt/apt.conf.d/20auto-upgrades').with(
            owner: 'root',
            group: 'root',
            mode: '0644'
        )
      end

    end
  end
end

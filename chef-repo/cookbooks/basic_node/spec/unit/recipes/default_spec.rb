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
  %w(14.04 16.04).each do |version|
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

      it 'includes the expected recipes' do
        recipes = %w(
          chef-vault
          apt::default
          apt::unattended-upgrades
          basic_node::mail
          basic_node::admin_user
          basic_node::openssh
          basic_node::security_updates
          basic_node::firewall
          basic_node::ntp
        )
        recipes.each do |r|
          expect(chef_run).to include_recipe(r)
        end
      end

      it 'does not include the remote_unlock recipe' do
        expect(chef_run).to_not include_recipe('basic_node::remote_unlock')
      end

    end
  end
end

describe 'basic_node::default' do
  %w(14.04 16.04).each do |version|
    context "When remote_unlock encryption is true, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version) do |node|
          node.set['basic_node']['remote_unlock']['encryption'] = true
        end.converge(described_recipe)
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

      it 'includes the expected recipes' do
        recipes = %w(
          chef-vault
          apt::default
          apt::unattended-upgrades
          basic_node::mail
          basic_node::admin_user
          basic_node::openssh
          basic_node::security_updates
          basic_node::firewall
          basic_node::ntp
          basic_node::remote_unlock
        )
        recipes.each do |r|
          expect(chef_run).to include_recipe(r)
        end
      end

    end
  end
end

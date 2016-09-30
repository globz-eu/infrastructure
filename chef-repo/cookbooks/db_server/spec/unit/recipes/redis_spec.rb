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
# Spec:: redis

require 'spec_helper'

describe 'db_server::redis' do
  ['14.04', '16.04'].each do |version|
    context "When all attributes are default, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version).converge(described_recipe)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'includes the expected recipes' do
        expect(chef_run).to include_recipe('chef-vault')
      end

      it 'adds the repository for redis' do
        expect(chef_run).to_not add_apt_repository('redis-server').with({
                                                                        repo_name: 'ppa:chris-lea/redis-server'
                                                                    })
      end

      it 'installs the redis-server package' do
        expect(chef_run).to_not install_package('redis-server')
      end
    end
  end
end

describe 'db_server::redis' do
  ['14.04', '16.04'].each do |version|
    context "When all install redis is true, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version) do |node|
          node.set['db_server']['redis']['install'] = true
        end.converge(described_recipe)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'includes the expected recipes' do
        expect(chef_run).to include_recipe('chef-vault')
        expect(chef_run).to include_recipe('apt')
      end

      it 'adds the repository for redis' do
        expect(chef_run).to add_apt_repository('redis-server').with({
            repo_name: 'redis-server',
            uri: 'ppa:chris-lea/redis-server',
            deb_src: true
                                                                    })
      end

      it 'installs the redis-server package' do
        expect(chef_run).to install_package('redis-server')
      end
    end
  end
end
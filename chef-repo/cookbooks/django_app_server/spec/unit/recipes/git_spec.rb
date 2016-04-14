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
# Cookbook Name:: django_app_server
# Spec:: git
#

require 'spec_helper'

describe 'django_app_server::git' do
  context 'When all attributes are default, on an Ubuntu 14.04 platform' do
    include ChefVault::TestFixtures.rspec_shared_context(true)
    let(:chef_run) do
      runner = ChefSpec::ServerRunner.new(platform: 'ubuntu', version: '14.04')
      runner.converge(described_recipe)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'installs the git package' do
      expect( chef_run ).to install_package('git')
    end

    it 'creates the /home/app_user/sites directory' do
      expect(chef_run).to create_directory('/home/app_user/sites').with(
          owner: 'app_user',
          group: 'www-data',
          mode: '0750',
      )
    end

    it 'creates the /home/app_user/sites/app_name directory' do
      expect(chef_run).to create_directory('/home/app_user/sites/app_name').with(
          owner: 'app_user',
          group: 'www-data',
          mode: '0750',
      )
    end

    it 'creates the /home/app_user/sites/app_name/source directory' do
      expect(chef_run).to create_directory('/home/app_user/sites/app_name/source').with(
          owner: 'app_user',
          group: 'www-data',
          mode: '0750',
      )
    end

    it 'clones or syncs the django app' do
      expect( chef_run ).to sync_git('/home/app_user/sites/app_name/source').with(repository: 'https://github.com/globz-eu/django_base.git')
    end
  end
end

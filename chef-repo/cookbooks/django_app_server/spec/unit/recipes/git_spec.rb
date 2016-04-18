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
      runner = ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04')
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
          mode: '0550',
      )
    end

    it 'creates the /home/app_user/sites/django_base directory' do
      expect(chef_run).to create_directory('/home/app_user/sites/django_base').with(
          owner: 'app_user',
          group: 'www-data',
          mode: '0550',
      )
    end

    it 'creates the /home/app_user/sites/django_base/source directory' do
      expect(chef_run).to create_directory('/home/app_user/sites/django_base/source').with(
          owner: 'app_user',
          group: 'app_user',
          mode: '0500',
      )
    end

    it 'clones or syncs the django app' do
      expect( chef_run ).to sync_git('/home/app_user/sites/django_base/source').with(repository: 'https://github.com/globz-eu/django_base.git')
    end

    it 'changes ownership of the django app to app_user:app_user' do
      expect(chef_run).to run_execute('chown -R app_user:app_user /home/app_user/sites/django_base/source')
    end

    it 'changes permissions for all files in django app to 0400' do
      expect(chef_run).to run_execute('find /home/app_user/sites/django_base/source -type f -exec chmod 0400 {} +')
    end

    it 'changes permissions for all directories in django app to 0500' do
      expect(chef_run).to run_execute('find /home/app_user/sites/django_base/source -type d -exec chmod 0500 {} +')
    end
  end
end

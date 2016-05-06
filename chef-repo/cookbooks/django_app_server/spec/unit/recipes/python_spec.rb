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
# Spec:: python

require 'spec_helper'

describe 'django_app_server::python' do
  context 'When all attributes are default, on an Ubuntu 14.04 platform' do
    include ChefVault::TestFixtures.rspec_shared_context(true)
    let(:chef_run) do
      runner = ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04')
      runner.converge(described_recipe)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'creates a python 3.4 runtime' do
      expect(chef_run).to install_python_runtime('3.4')
    end

    # TODO move to django_app and replace by script
    # it 'creates the venv file structure' do
    #   expect(chef_run).to create_directory('/home/app_user/.envs').with({
    #       owner: 'app_user',
    #       group: 'app_user',
    #       mode: '0500'
    #                                                                     })
    #   expect(chef_run).to create_directory('/home/app_user/.envs/django_base').with({
    #       owner: 'app_user',
    #       group: 'app_user',
    #       mode: '0500'
    #                                                                     })
    # end
    #
    # it 'creates a venv' do
    #   expect(chef_run).to create_python_virtualenv('/home/app_user/.envs/django_base').with({
    #       python: '/usr/bin/python3.4'
    #                                                                                        })
    # end
    #
    # it 'installs python3-numpy' do
    #   expect(chef_run).to install_package('python3-numpy')
    # end
    #
    # it 'installs the numpy python package' do
    #   expect(chef_run).to install_python_package('numpy').with({version: '1.11.0'})
    # end
    #
    # it 'changes ownership of the venv to app_user:app_user' do
    #   expect(chef_run).to run_execute('chown -R app_user:app_user /home/app_user/.envs/django_base')
    # end

  end
end

describe 'django_app_server::python' do
  describe 'django_app_server::python' do
    context 'When all attributes are default, on an Ubuntu 16.04 platform' do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '16.04').converge(described_recipe)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'installs python3.5-dev and python3-pip' do
        expect(chef_run).to install_package(['python3.5-dev', 'python3-pip'])
      end
    end
  end
end
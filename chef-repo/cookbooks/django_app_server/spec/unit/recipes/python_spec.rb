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

def common
  it 'converges successfully' do
    expect { chef_run }.to_not raise_error
  end

  it 'updates pip3' do
    expect(chef_run).to run_bash('update_pip').with(
        code: 'pip3 install --upgrade pip',
        user: 'root'
    )
  end
end

describe 'django_app_server::python' do
  context 'When all attributes are default, on an Ubuntu 14.04 platform' do
    include ChefVault::TestFixtures.rspec_shared_context(true)
    let(:chef_run) do
      runner = ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04')
      runner.converge(described_recipe)
    end

    before do
      stub_command('pip list | grep virtualenv').and_return(false)
    end

    common

    it 'creates a python 3.4 runtime' do
      expect(chef_run).to install_python_runtime('3.4')
    end

    it 'installs virtualenv' do
      expect(chef_run).to run_bash('install_virtualenv').with(

      )
    end
  end
end

describe 'django_app_server::python' do
  context 'When all attributes are default, on an Ubuntu 16.04 platform' do
    include ChefVault::TestFixtures.rspec_shared_context(true)
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '16.04').converge(described_recipe)
    end

    common

    it 'installs python3.5-dev and python3-pip' do
      expect(chef_run).to install_package(['python3.5-dev', 'python3-pip', 'python3-venv'])
    end
  end
end

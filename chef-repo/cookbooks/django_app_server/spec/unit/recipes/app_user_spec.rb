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
# Cookbook:: django_app_server
# Spec:: app_user

require 'spec_helper'

describe 'django_app_server::app_user' do
  context 'When all attributes are default, on an Ubuntu 14.04 platform' do
    include ChefVault::TestFixtures.rspec_shared_context(true)
    let(:chef_run) do
      runner = ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04')
      runner.converge(described_recipe)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'creates the admin user' do
      expect(chef_run).to create_user('app_user').with(
          home: '/home/app_user',
          shell: '/bin/bash',
          password: '$6$g7n0bpuYPHBI.$FVkbyH37IcBhDc000UcrGZ/u4n1f9JaEhLtBrT1VcAwKXL1sh9QDoTb3leMdazZVLQuv/w1FCBeqXX6GZGWid/'
      )
    end

    it 'adds app_user to group www-data' do
      expect(chef_run).to manage_group('www-data').with(
          append: true,
          members: ['app_user']
      )
    end
  end
end

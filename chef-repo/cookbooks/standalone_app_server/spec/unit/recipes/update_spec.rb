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
# Cookbook Name:: standalone_app_server
# Server Spec:: update

require 'spec_helper'

describe 'standalone_app_server::update' do
  ['14.04', '16.04'].each do |version|
    context "When all parameters are default, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version).converge(described_recipe)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'runs server_down' do
        expect( chef_run ).to run_bash('server_down').with(
           cwd: '/home/web_user/sites/django_base/scritps',
           code: './webserver.py -s down',
           user: 'root'
        )
      end

      it 'runs remove_app' do
        expect( chef_run ).to run_bash('server_down').with(
            cwd: '/home/app_user/sites/django_base/scritps',
            code: './djangoapp.py -x',
            user: 'root'
        )
      end

      it 'resets the database' do
        expect( chef_run ).to run_bash('db_reset').with(
            cwd: '/home/db_user/sites/django_base/scripts',
            code: './dbserver.py -r',
            user: 'root'
        )
      end

      it 'runs reinstall_app' do
        expect( chef_run ).to run_bash('reinstall_app').with(
            cwd: '/home/app_user/sites/django_base/scritps',
            code: './djangoapp.py -imt -u start',
            user: 'root'
        )
      end

      it 'runs server_up' do
        expect( chef_run ).to run_bash('server_down').with(
            cwd: '/home/web_user/sites/django_base/scritps',
            code: './webserver.py -s up',
            user: 'root'
        )
      end
    end
  end
end
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
# Server Spec:: django_app

require 'spec_helper'

describe 'django_app_server::django_app' do
  context 'When all attributes are default, on an Ubuntu 14.04 platform' do
    include ChefVault::TestFixtures.rspec_shared_context(true)
    let(:chef_run) do
      runner = ChefSpec::ServerRunner.new(platform: 'ubuntu', version: '14.04')
      runner.converge(described_recipe)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'creates the directory structure for the app static files' do
      expect(chef_run).to create_directory('/home/app_user/sites/django_base/static').with(
          owner: 'app_user',
          group: 'www-data',
          mode: '0750',
      )
      expect(chef_run).to create_directory('/home/app_user/sites/django_base/media').with(
          owner: 'app_user',
          group: 'www-data',
          mode: '0750',
      )
    end

    it 'adds the app path to the python path' do
      expect(chef_run).to create_template('/home/app_user/.envs/django_base/lib/python3.4/django_base.pth').with(
          owner: 'app_user',
          group: 'app_user',
          mode: '0400',
          source: 'app_name.pth.erb',
          variables: {
              app_path: '/home/app_user/sites/django_base/source',
          })
    end

    it 'adds the configuration file' do
      expect(chef_run).to create_template('/home/app_user/sites/django_base/source/configuration.py').with(
          owner: 'app_user',
          group: 'app_user',
          mode: '0400',
          source: 'configuration.py.erb',
          variables: {
              secret_key: 'n)#o5pw7kelvr982iol48tz--n#q!*8681k3sv0^*q#-lddwv!',
              debug: 'False',
              allowed_host: 'localhost',
              engine: 'django.db.backends.postgresql_psycopg2',
              app_name: 'django_base',
              db_user: 'db_user',
              db_user_password: 'db_user_password',
              db_host: 'localhost'
          })
      expect(chef_run).to render_file('/home/app_user/sites/django_base/source/configuration.py')
    end

    it 'adds the admin settings file' do
      expect(chef_run).to create_template('/home/app_user/sites/django_base/source/django_base/settings_admin.py').with(
          owner: 'app_user',
          group: 'app_user',
          mode: '0400',
          source: 'settings_admin.py.erb',
          variables: {
              secret_key: 'n)#o5pw7kelvr982iol48tz--n#q!*8681k3sv0^*q#-lddwv!',
              debug: 'False',
              allowed_host: 'localhost',
              engine: 'django.db.backends.postgresql_psycopg2',
              app_name: 'django_base',
              installed_apps: "'django_base'",
              db_admin_user: 'postgres',
              db_admin_password: 'postgres_password',
              db_host: 'localhost'
          })
        expect(chef_run).to render_file('/home/app_user/.envs/django_base/lib/python3.4/django_base.pth')
    end



    it 'adds the python script for installing system dependencies' do
      expect(chef_run).to create_template('/home/app_user/sites/django_base/source/install_dependencies.py').with(
          owner: 'app_user',
          group: 'app_user',
          mode: '0500',
          source: 'install_dependencies.py.erb',
          variables: {
              dep_file_path: '/home/app_user/sites/django_base/source/system_dependencies.txt'
          })
      expect(chef_run).to render_file('/home/app_user/.envs/django_base/lib/python3.4/django_base.pth')
    end

    it 'runs the install_dependencies script' do
      expect(chef_run).to run_bash('install_dependencies').with({
          cwd: '/home/app_user/sites/django_base/source',
          code: './install_dependencies.py',
          user: 'root'
          })
    end

    it 'installs python packages from requirements.txt' do
      expect(chef_run).to run_bash('install_requirements').with({
          cwd: '/home/app_user/sites/django_base/source',
          code: '/home/app_user/.envs/django_base/bin/pip3 install -r ./requirements.txt',
          user: 'root'
          })
    end

  end
end
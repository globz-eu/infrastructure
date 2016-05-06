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
# Cookbook:: standalone_app_server
# Spec:: start_app

require 'spec_helper'

describe 'standalone_app_server::start_app' do
  context 'When all attributes are default, on an Ubuntu 14.04 platform' do
    include ChefVault::TestFixtures.rspec_shared_context(true)
    let(:chef_run) do
      runner = ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04')
      runner.converge(described_recipe)
    end

    before do
      stub_command(/ls \/.*\/recovery.conf/).and_return(false)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    # manages migrations
    it 'manages migrations' do
      expect(chef_run).to run_bash('migrate').with({
                cwd: '/home/app_user/sites/django_base/source/django_base',
                code: '/home/app_user/.envs/django_base/bin/python ./manage.py migrate --settings django_base.settings_admin',
                user: 'root'
            })
    end

    # runs app tests
    it 'creates test log file structure' do
      expect(chef_run).to create_directory('/var/log/django_base').with({
          owner: 'root',
          group: 'root',
          mode: '0700'
                                                                        })
      expect(chef_run).to create_directory('/var/log/django_base/test_results').with({
          owner: 'root',
          group: 'root',
          mode: '0700'
                                                                        })
    end

    it 'runs app tests' do
      expect(chef_run).to run_bash('test_app').with({
                cwd: '/home/app_user/sites/django_base/source/django_base',
                code: '/home/app_user/.envs/django_base/bin/python ./manage.py test --settings django_base.settings_admin &> /var/log/django_base/test_results/test_$(date +"%d-%m-%y-%H%M%S").log',
                user: 'root'
             })
    end

    it 'launches uwsgi' do
      expect(chef_run).to run_bash('start_uwsgi').with({
          cwd: '/home/app_user/sites/django_base/source',
          code: 'uwsgi --ini ./django_base_uwsgi.ini ',
          user: 'root'
                                                       })
    end
  end
end

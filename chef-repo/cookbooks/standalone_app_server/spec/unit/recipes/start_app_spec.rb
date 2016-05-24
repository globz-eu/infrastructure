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
  ['14.04', '16.04'].each do |version|
    context "When app name is specified, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version) do |node|
          node.set['django_app_server']['django_app']['app_name'] = 'django_base'
        end.converge('web_server::nginx', described_recipe)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'includes the chef-vault recipe' do
        expect(chef_run).to include_recipe('chef-vault')
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

      it 'disables the app down site' do
        expect(chef_run).to delete_file('/etc/nginx/sites-enabled/django_base_down.conf')
      end

      it 'enables app site in nginx' do
        expect(chef_run).to create_link('/etc/nginx/sites-enabled/django_base.conf').with(
                    owner: 'root',
                    group: 'root',
                    to: '/etc/nginx/sites-available/django_base.conf',
        )
      end

      it 'notifies nginx to restart' do
        django_base_enabled = chef_run.link('/etc/nginx/sites-enabled/django_base.conf')
        expect(django_base_enabled).to notify('service[nginx]').to(:restart).immediately
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
end

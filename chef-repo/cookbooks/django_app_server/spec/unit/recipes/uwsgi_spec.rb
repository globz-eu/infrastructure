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

describe 'django_app_server::uwsgi' do
  context 'When all attributes are default, on an Ubuntu 14.04 platform' do
    include ChefVault::TestFixtures.rspec_shared_context(true)
    let(:chef_run) do
      runner = ChefSpec::ServerRunner.new(platform: 'ubuntu', version: '14.04')
      runner.converge(described_recipe)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'creates the /var/log/uwsgi directory' do
      expect(chef_run).to create_directory('/var/log/uwsgi').with(
          owner: 'root',
          group: 'root',
          mode: '0755',
      )
    end

    it 'adds the django_base_uwsgi.ini file' do
      expect(chef_run).to create_template('/home/app_user/sites/django_base/source/django_base_uwsgi.ini').with(
          owner: 'app_user',
          group: 'app_user',
          mode: '0400',
          source: 'app_name_uwsgi.ini.erb',
          variables: {
              app_name: 'django_base',
              app_user: 'app_user',
              processes: '2',
              socket: '/home/app_user/sites/django_base/sockets/django_base.sock',
              chmod_socket: 'chmod-socket = 660',
              log_file: '/var/log/uwsgi/django_base.log',
              pid_file: '/tmp/django_base-uwsgi-master.pid'
          })
      expect(chef_run).to render_file('/home/app_user/sites/django_base/source/django_base_uwsgi.ini')
    end

  end
end
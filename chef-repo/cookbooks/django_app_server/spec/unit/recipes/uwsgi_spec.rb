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
# Spec:: uwsgi

require 'spec_helper'

describe 'django_app_server::uwsgi' do
  context 'When all attributes are default, on an Ubuntu 14.04 platform' do
    include ChefVault::TestFixtures.rspec_shared_context(true)
    let(:chef_run) do
      runner = ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04')
      runner.converge(described_recipe)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'installs the uwsgi python package' do
      expect(chef_run).to install_python_package('uwsgi').with({python: '/usr/bin/python3.4'})
    end

    it 'creates the /var/log/uwsgi directory' do
      expect(chef_run).to create_directory('/var/log/uwsgi').with(
          owner: 'root',
          group: 'root',
          mode: '0755',
      )
    end

    it 'adds the django_base_uwsgi.ini file' do
      params = [
          /^# django_base_uwsgi.ini file$/,
          %r(^chdir\s+=\s+/home/app_user/sites/django_base/source$),
          /^module\s+=\s+django_base\.wsgi$/,
          %r(^home\s+=\s+/home/app_user/\.envs/django_base$),
          /^uid\s+=\s+app_user$/,
          /^gid\s+=\s+www-data$/,
          /^processes\s+=\s+2$/,
          %r(^socket = /home/app_user/sites/django_base/sockets/django_base\.sock$),
          /^chmod-socket\s+=\s+660$/,
          %r(^daemonize\s+=\s+/var/log/uwsgi/django_base\.log$),
          %r(^master-fifo\s+=\s+/tmp/fifo0$)
      ]
      expect(chef_run).to create_template('/home/app_user/sites/django_base/source/django_base_uwsgi.ini').with(
          owner: 'app_user',
          group: 'app_user',
          mode: '0400',
          source: 'app_name_uwsgi.ini.erb',
          variables: {
              app_name: 'django_base',
              app_user: 'app_user',
              web_user: 'www-data',
              processes: '2',
              socket: '/home/app_user/sites/django_base/sockets/django_base.sock',
              chmod_socket: 'chmod-socket = 660',
              log_file: '/var/log/uwsgi/django_base.log',
              pid_file: '/tmp/django_base-uwsgi-master.pid'
          })
      params.each do |p|
        expect(chef_run).to render_file('/home/app_user/sites/django_base/source/django_base_uwsgi.ini').with_content(p)
      end

    end

  end
end
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
  ['14.04', '16.04'].each do |version|
    context "When app name and git repo are specified, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04') do |node|
          node.set['django_app_server']['django_app']['app_name'] = 'django_base'
          node.set['django_app_server']['git']['git_repo'] = 'https://github.com/globz-eu/django_base.git'
        end.converge(described_recipe)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'installs the uwsgi python package' do
        expect(chef_run).to run_bash('uwsgi').with(
                   code: 'pip3 install uwsgi',
                   user: 'root'
        )
      end

      it 'creates the /var/log/uwsgi directory' do
        expect(chef_run).to create_directory('/var/log/uwsgi').with(
            owner: 'root',
            group: 'root',
            mode: '0755',
        )
      end
    end
  end
end
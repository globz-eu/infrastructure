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
# Spec:: default

require 'spec_helper'

describe 'standalone_app_server::default' do
  ['14.04', '16.04'].each do |version|
    context "When app name is specified, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version) do |node|
          node.set['django_app_server']['git']['app_repo'] = 'https://github.com/globz-eu/django_base.git'
          node.set['web_server']['git']['app_repo'] = 'https://github.com/globz-eu/django_base.git'
          node.set['db_server']['postgresql']['db_name'] = 'django_base'
        end.converge(described_recipe)
      end

      before do
        stub_command(/ls \/.*\/recovery.conf/).and_return(false)
        stub_command("pip3 list | grep uWSGI").and_return(false)
        stub_command("sudo -u postgres psql -c '\\du' | grep db_user").and_return(false)
        stub_command("ls /home/app_user/sites/django_base/scripts").and_return(false)
        stub_command("pip list | grep virtualenv").and_return(false)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'includes the correct recipes' do
        expect(chef_run).to include_recipe('chef-vault')
        expect(chef_run).to include_recipe('apt::default')
        expect(chef_run).to include_recipe('install_scripts::user')
        expect(chef_run).to include_recipe('db_server::default')
        expect(chef_run).to include_recipe('django_app_server::default')
        expect(chef_run).to include_recipe('web_server::default')
        expect(chef_run).to include_recipe('standalone_app_server::start_app')
      end
    end
  end
end

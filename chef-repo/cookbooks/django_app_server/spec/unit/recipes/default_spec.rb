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
# Spec:: default

require 'spec_helper'

describe 'django_app_server::default' do
  ['14.04', '16.04'].each do |version|
    context "When all attributes are default, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        runner = ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version)
        runner.converge(described_recipe)
      end

      before do
        stub_command('pip list | grep virtualenv').and_return(false)
        stub_command("pip3 list | grep uWSGI").and_return(false)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'includes the expected recipes' do
        expect(chef_run).to include_recipe('chef-vault')
        expect(chef_run).to include_recipe('apt::default')
        expect(chef_run).to include_recipe('install_scripts::user')
        expect(chef_run).to include_recipe('install_scripts::scripts')
        expect(chef_run).to include_recipe('django_app_server::python')
        expect(chef_run).to include_recipe('django_app_server::uwsgi')
        expect(chef_run).to include_recipe('django_app_server::django_app')
      end
    end
  end
end

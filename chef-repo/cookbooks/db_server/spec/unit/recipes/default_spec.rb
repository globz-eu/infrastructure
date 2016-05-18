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
# Cookbook Name:: db_server
# Spec:: default

require 'spec_helper'

describe 'db_server::default' do
  ['14.04', '16.04'].each do |version|
    context "When all attributes are default, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version).converge(described_recipe)
        stub_command("ls /var/lib/postgresql/9.5/main/recovery.conf").and_return('')
      end

      before do
        stub_command(/ls \/.*\/recovery.conf/).and_return(false)
      end
    end
  end
end

describe 'db_server::default' do
  ['14.04', '16.04'].each do |version|
    context "When node['db_server']['postgresql']['db_name'] = django_base, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version) do |node|
          node.set['db_server']['postgresql']['db_name'] = 'django_base'
        end.converge(described_recipe)
        stub_command("ls /var/lib/postgresql/9.5/main/recovery.conf").and_return('')
      end

      before do
        stub_command(/ls \/.*\/recovery.conf/).and_return(false)
        stub_command("sudo -u postgres psql -c '\\l' | grep django_base").and_return(false)
        stub_command("sudo -u postgres psql -c '\\du' | grep db_user").and_return(false)
        stub_command("sudo -u postgres psql -d django_base -c '\\ddp' | egrep 'table.*db_user'").and_return(false)
        stub_command("sudo -u postgres psql -d django_base -c '\\ddp' | egrep 'sequence.*db_user'").and_return(false)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end
    end
  end
end

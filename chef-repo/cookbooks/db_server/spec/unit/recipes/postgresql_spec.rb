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
# Spec:: postgresql

require 'spec_helper'

describe 'db_server::postgresql' do
  context 'When all attributes are default, on an Ubuntu 14.04 platform' do
    include ChefVault::TestFixtures.rspec_shared_context(true)
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04') do |node|  # , step_into: ['postgresql_database']
        node.set['db_server']['postgresql']['db_name'] = 'django_base'
      end.converge(described_recipe)
    end

    before do
      stub_command(/ls \/.*\/recovery.conf/).and_return(false)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'installs the "postgresql-9.5 postgresql-contrib-9.5 postgresql-client-9.5 postgresql-server-9.5 postgresql-server-dev-9.5" package' do
      expect(chef_run).to install_package('postgresql-9.5')
      expect(chef_run).to install_package('postgresql-contrib-9.5')
      expect(chef_run).to install_package('postgresql-client-9.5')
      expect(chef_run).to install_package('postgresql-server-dev-9.5')
    end

    it 'starts the postgresql service' do
      expect(chef_run).to start_service( 'postgresql' )
    end

    it 'enables the postgresql service' do
      expect(chef_run).to enable_service( 'postgresql' )
    end

    it 'renders the pg_hba file' do
      pg_auth = [
          /local\s+all\s+postgres\s+ident/,
          /local\s+all\s+all\s+md5/,
          %r(host\s+all\s+all\s+127\.0\.0\.1/32\s+md5),
          %r(host\s+all\s+all\s+::1/128\s+md5)
      ]
      pg_auth.each do |p|
        expect(chef_run).to render_file('/etc/postgresql/9.5/main/pg_hba.conf').with_content(p)
      end
    end

    it 'runs default privilege grant code' do
      expect(chef_run).to_not run_bash('grant_default_db').with({
        code: "sudo -u postgres psql -d django_base -c 'ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO db_user;'",
        user: 'root'
                                                                                })
      expect(chef_run).to_not run_bash('grant_default_seq').with({
        code: "sudo -u postgres psql -d django_base -c 'ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, USAGE ON SEQUENCES TO db_user;'",
        user: 'root'
                                                                                })
    end

  end
end
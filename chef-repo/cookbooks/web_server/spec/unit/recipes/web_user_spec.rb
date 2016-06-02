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
# Cookbook:: django_app_server
# Spec:: web_user

require 'spec_helper'

describe 'web_server::web_user' do
  ['14.04', '16.04'].each do |version|
    context "When app user is specified, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04').converge(described_recipe)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'creates the web user' do
        expect(chef_run).to create_user('web_user').with(
            home: '/home/web_user',
            shell: '/bin/bash',
            password: '$6$yVU4DyvxK$eA6SgYYkMjB11XavwzqLAvCfEuhYKmxElVHmxq/OszdU31ZjfukGZtJivTwwyHMt8DmiFv9NDvHRCWBNCcwKK.'
        )
      end

      it 'adds web_user to group www-data' do
        expect(chef_run).to manage_group('www-data').with(
            append: true,
            members: ['web_user']
        )
      end
    end
  end
end

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
# Cookbook:: db_server
# Spec:: db_user

require 'spec_helper'

describe 'db_server::db_user' do
  ['14.04', '16.04'].each do |version|
    context "When app user is specified, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version).converge(described_recipe)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'includes the expected recipes' do
        expect(chef_run).to include_recipe('chef-vault')
      end

      it 'creates the database user' do
        expect(chef_run).to create_user('db_user').with(
            home: '/home/db_user',
            shell: '/bin/bash',
            password: '$6$xKJVG30L$GN..e105dLVkI5JElirjwif2VoZtMldkCvbgRmFJAU4tC1KbRkMjEJIkkEREtvbcv38HFPARVc6cWV7YoEbxR/'
        )
      end
    end
  end
end
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
# Cookbook:: install_scripts
# Spec:: user

require 'spec_helper'

describe 'install_scripts::user' do
  ['14.04', '16.04'].each do |version|
    context "When all attributes are default, on an Ubuntu #{version} platform" do
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version).converge(described_recipe)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'does not create a user' do
        expect(chef_run).to_not create_user('user')
      end
    end
  end
end

describe 'install_scripts::user' do
  ['14.04', '16.04'].each do |version|
    context "When user name, password and group are specified, on an Ubuntu #{version} platform" do
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version) do |node|
          node.set['install_scripts']['users'] = [{
            :user => 'user',
            :password => '$6$YPpcwnaZtxEObrRR$RpqD1RgLVHOrr0BbAmVocf.6/yIU5.mW.hr.sm./xvwheoa9xBO6td71PUczQKfcaAcE1U2c3o0mOMb8ufvr5/',
            :groups => ['www-data'],
                                                  }]
        end.converge(described_recipe)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'creates the user' do
        expect(chef_run).to create_user('user').with(
            home: '/home/user',
            shell: '/bin/bash',
            password: '$6$YPpcwnaZtxEObrRR$RpqD1RgLVHOrr0BbAmVocf.6/yIU5.mW.hr.sm./xvwheoa9xBO6td71PUczQKfcaAcE1U2c3o0mOMb8ufvr5/'
        )
      end

      it 'adds user to group www-data' do
        expect(chef_run).to manage_group('www-data').with(
            append: true,
            members: ['user']
        )
      end
    end
  end
end

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
# Cookbook Name:: web_server
# Spec:: default


require 'spec_helper'

describe 'web_server::default' do
  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe)}

  it 'installs the nginx package' do
    expect(chef_run).to install_package( 'nginx' )
  end

  it 'starts the nginx service' do
    expect(chef_run).to start_service( 'nginx' )
  end

  it 'enables the nginx service' do
    expect(chef_run).to enable_service( 'nginx' )
  end

end

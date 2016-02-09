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


require 'spec_helper'

set :backend, :exec

describe user( $node['basic_node']['admin_user']['node_admin'] ) do
  it { should exist }
end

describe user( $node['basic_node']['admin_user']['node_admin'] ) do
  it { should belong_to_group 'sudo' }
end

describe user( $node['basic_node']['admin_user']['node_admin'] ) do
  it { should have_home_directory '/home/' + $node['basic_node']['admin_user']['node_admin'] }
end

describe user( $node['basic_node']['admin_user']['node_admin'] ) do
  it { should have_login_shell '/bin/bash' }
end

describe user( $node['basic_node']['admin_user']['node_admin'] ) do
  its(:encrypted_password) { should match(/^\$6\$.{16}\$.{86}$/) }
end

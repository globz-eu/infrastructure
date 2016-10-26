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
# Server Spec:: db_user

require 'spec_helper'

set :backend, :exec

describe user( 'db_user' ) do
  it { should exist }
  it { should belong_to_group 'db_user' }
  it { should belong_to_group 'db_user' }
  it { should have_home_directory '/home/db_user' }
  it { should have_login_shell '/bin/bash' }
  its(:encrypted_password) { should match('$6$xKJVG30L$GN..e105dLVkI5JElirjwif2VoZtMldkCvbgRmFJAU4tC1KbRkMjEJIkkEREtvbcv38HFPARVc6cWV7YoEbxR/') }
end
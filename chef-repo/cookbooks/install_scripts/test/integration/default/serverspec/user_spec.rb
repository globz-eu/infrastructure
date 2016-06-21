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

set :backend, :exec

describe user( 'user' ) do
  it { should exist }
  it { should belong_to_group 'user' }
  it { should belong_to_group 'user' }
  it { should have_home_directory '/home/user' }
  it { should have_login_shell '/bin/bash' }
  its(:encrypted_password) {
    should match(
       '$6$YPpcwnaZtxEObrRR$RpqD1RgLVHOrr0BbAmVocf.6/yIU5.mW.hr.sm./xvwheoa9xBO6td71PUczQKfcaAcE1U2c3o0mOMb8ufvr5/'
           )
  }
end

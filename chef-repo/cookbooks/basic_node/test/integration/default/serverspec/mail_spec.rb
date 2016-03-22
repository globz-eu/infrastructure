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

expected_rules = [
    %r{ 587/tcp + ALLOW OUT + Anywhere \(out\)},
    %r{ 587/tcp \(v6\) + ALLOW OUT + Anywhere \(v6\) \(out\)}
]

describe file('//etc/ssmtp/ssmtp.conf') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_mode 644 }
  its(:md5sum) { should eq 'b949ecbfacb2e1e26b41faae5f2f25c3' }
  it { should contain 'FromLineOverride=YES' }
  it { should contain 'AuthUser=admin@example.com' }
  it { should contain 'AuthPass=password' }
  it { should contain 'mailhub=smtp.mail.com:587' }
  it { should contain 'UseSTARTTLS=YES' }
end

describe command( 'ufw status numbered' ) do
  its(:stdout) { should match(/Status: active/) }
  expected_rules.each do |r|
    its(:stdout) { should match(r) }
  end
end
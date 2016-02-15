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
    %r{ 22/tcp + ALLOW IN + Anywhere},
    %r{ 22/tcp \(v6\) + ALLOW IN + Anywhere \(v6\)},
    %r{ 22,53,80,443/tcp + ALLOW OUT + Anywhere \(out\)},
    %r{ 53,67,68/udp + ALLOW OUT + Anywhere \(out\)},
    %r{ 22,53,80,443/tcp \(v6\) + ALLOW OUT + Anywhere \(v6\) \(out\)},
    %r{ 53,67,68/udp \(v6\) + ALLOW OUT + Anywhere \(v6\) \(out\)}
]

describe command( 'ufw status numbered' ) do
  its(:stdout) { should match(/Status: active/) }
  expected_rules.each do |r|
    its(:stdout) { should match(r) }
  end
end
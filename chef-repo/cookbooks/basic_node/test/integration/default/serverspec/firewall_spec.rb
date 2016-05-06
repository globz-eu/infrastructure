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
    %r{\s+22/tcp\s+ALLOW IN\s+Anywhere},
    %r{\s+80/tcp\s+ALLOW IN\s+Anywhere},
    %r{\s+22/tcp\s+\(v6\)\s+ALLOW IN\s+Anywhere\s+\(v6\)},
    %r{\s+22,53,80,443/tcp\s+ALLOW OUT\s+Anywhere\s+\(out\)},
    %r{\s+53,67,68/udp\s+ALLOW OUT\s+Anywhere\s+\(out\)},
    %r{\s+22,53,80,443/tcp\s+\(v6\)\s+ALLOW OUT\s+Anywhere\s+\(v6\)\s+\(out\)},
    %r{\s+53,67,68/udp\s+\(v6\)\s+ALLOW OUT\s+Anywhere\s+\(v6\)\s+\(out\)}
]

describe command( 'ufw status verbose' ) do
  its(:stdout) { should match(/Status: active/) }
  its(:stdout) { should match(%r{Default: deny \(incoming\), deny \(outgoing\), disabled \(routed\)}) }
end

describe command( 'ufw status numbered' ) do
  its(:stdout) { should match(/Status: active/) }
  expected_rules.each do |r|
    its(:stdout) { should match(r) }
  end
end
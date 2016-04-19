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
# Cookbook Name:: basic_node
# Recipe:: firewall

include_recipe 'firewall::default'

firewall_rule 'min_out_tcp' do
  protocol :tcp
  direction :out
  command :allow
  port [22,53,80,443]
end

firewall_rule 'min_out_udp' do
  protocol :udp
  direction :out
  command :allow
  port [53,67,68]
end

firewall_rule 'ssh' do
  protocol :tcp
  direction :in
  command :allow
  port 22
end

if node['basic_node']['firewall']['mail']
  firewall_rule 'mail' do
    protocol :tcp
    direction :out
    command :allow
    port 587
  end
end

if node['basic_node']['firewall']['web_server']
  firewall_rule 'http' do
    protocol :tcp
    direction :in
    command :allow
    port 80
  end
end
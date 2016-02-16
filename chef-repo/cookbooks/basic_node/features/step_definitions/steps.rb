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

require 'sshkit'
require 'sshkit/dsl'

When(/^an admin with the user name "(.*?)" opens a SSH session to a node with the IP "(.*?)"$/) do | user_name, ip |
  @ip = ip
  @user_name = user_name
  SSHKit::Backend::Netssh.configure do |ssh|
    ssh.connection_timeout = 30
    ssh.ssh_options = {
        user: @user_name,
        keys: [File.join(File.dirname(__FILE__), '../../test/integration/fixtures/files/id_rsa')],
        forward_agent: true,
        auth_methods: ['publickey']
    }
  end
  on @ip do
    %x('ssh-keygen -f "/home/golg/.ssh/known_hosts" -R #{@ip}')
    $whoami_output = capture(:whoami)
  end
end

Then(/^the admin should be logged in to the node$/) do
  expect($whoami_output).to eq(@user_name)
end

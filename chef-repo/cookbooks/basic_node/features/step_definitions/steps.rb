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

# Cookbook:: web_server
# Server Spec:: web_user

require 'spec_helper'

set :backend, :exec

describe user( 'web_user' ) do
  it { should exist }
  it { should belong_to_group 'web_user' }
  it { should belong_to_group 'www-data' }
  it { should have_home_directory '/home/web_user' }
  it { should have_login_shell '/bin/bash' }
  its(:encrypted_password) { should match('$6$yVU4DyvxK$eA6SgYYkMjB11XavwzqLAvCfEuhYKmxElVHmxq/OszdU31ZjfukGZtJivTwwyHMt8DmiFv9NDvHRCWBNCcwKK.') }
end

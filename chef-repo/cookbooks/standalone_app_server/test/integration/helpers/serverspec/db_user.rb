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
require 'spec_helper'

set :backend, :exec

describe user( 'node_admin' ) do
  it { should exist }
end

describe user( 'node_admin' ) do
  it { should belong_to_group 'sudo' }
  it { should belong_to_group 'adm' }
  it { should_not belong_to_group 'cdrom' }
  it { should_not belong_to_group 'dip' }
  it { should_not belong_to_group 'plugdev' }
  it { should_not belong_to_group 'lpadmin' }
  it { should_not belong_to_group 'sambashare' }
end

describe user( 'node_admin' ) do
  it { should have_home_directory '/home/node_admin' }
end

describe user( 'node_admin' ) do
  it { should have_login_shell '/bin/bash' }
end

describe user( 'node_admin' ) do
  its(:encrypted_password) { should match('$6$oWrcKQHI2UL$rrFuhMmBnMpw102eOdNzBWibU7BnQyaT3031KiPpz8VqOqzLbIBiC.wpY8Uw4Z3n3LsgtfxpqaN5b9LuVGCfX.') }
end

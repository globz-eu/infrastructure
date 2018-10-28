require 'spec_helper'

set :backend, :exec

describe package('apticron') do
  it { should be_installed}
end

describe file('/etc/apticron/apticron.conf') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_mode 644 }
  its(:md5sum) { should eq '691ea29ddf3b609777f1c60a2cd42f0c' }
  its(:content) { should match(/^EMAIL="admin@example\.com"/) }
end

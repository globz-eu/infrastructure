require 'spec_helper'

set :backend, :exec

expected_rules = [
    %r{\s+587/tcp\s+ALLOW OUT\s+Anywhere\s+\(out\)},
    %r{\s+587/tcp\s+\(v6\)\s+ALLOW OUT\s+Anywhere\s+\(v6\)\s+\(out\)}
]

describe package('ssmtp') do
  it { should be_installed }
end

describe package('mailutils') do
  it { should be_installed }
end

describe file('/etc/ssmtp/ssmtp.conf') do
  ssmtp_conf = [
      /^FromLineOverride=YES/,
      /^AuthUser=admin@example\.com/,
      /^AuthPass=password/,
      /^mailhub=smtp\.mail\.com:587/,
      /^UseSTARTTLS=YES/
  ]
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_mode 644 }
  its(:md5sum) { should eq 'e023388b69a2079eeff4e27ce6f94cb3' }
  ssmtp_conf.each do |s|
    its(:content) { should match(s) }
  end
end

describe command( 'ufw status numbered' ) do
  its(:stdout) { should match(/Status: active/) }
  expected_rules.each do |r|
    its(:stdout) { should match(r) }
  end
end
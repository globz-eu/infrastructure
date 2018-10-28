require 'spec_helper'

set :backend, :exec

if os[:family] == 'ubuntu'
  if os[:release] == '14.04'
    # apt repository for postgresql9.5 should be there
    describe file('/etc/apt/sources.list.d/apt.postgresql.org.list') do
      it { should exist }
      it { should be_file }
      it { should be_owned_by 'root' }
      it { should be_mode 644 }
      its(:content) { should match %r{deb\s+"http://apt.postgresql.org/pub/repos/apt" trusty-pgdg main 9.5} }
      its(:md5sum) { should eq '1749267b56d79a347cec31e0397f85c5' }
    end

    # apt key should be correct for postgresql9.5
    describe command( 'apt-key list' ) do
      expected_apt_key_list = [
          %r{pub\s+4096R/ACCC4CF8},
          %r{uid\s+PostgreSQL Debian Repository}
      ]
      expected_apt_key_list.each do |r|
        its(:stdout) { should match(r) }
      end
    end

    # postgresql9.5 and dev packages should be installed
    describe package('postgresql-9.5') do
      it { should be_installed }
    end

    describe package('postgresql-contrib-9.5') do
      it { should be_installed }
    end

    describe package('postgresql-client-9.5') do
      it { should be_installed }
    end

  elsif os[:release] == '16.04'
    # postgresql9.5 and dev packages should be installed
    describe package('postgresql') do
      it { should be_installed }
    end

    describe package('postgresql-contrib-9.5') do
      it { should be_installed }
    end
  end

  describe package('postgresql-server-dev-9.5') do
    it { should be_installed }
  end

  # postgresql should be running
  describe service('postgresql') do
    it { should be_enabled }
    it { should be_running }
  end

  # postgres should be configured for md5 authentication
  describe file('/etc/postgresql/9.5/main/pg_hba.conf') do
    pg_hba = [
        %r{local\s+all\s+postgres\s+ident},
        %r{local\s+all\s+all\s+md5}
    ]
    it { should exist }
    it { should be_file }
    it { should be_owned_by 'postgres' }
    it { should be_mode 600 }
    pg_hba.each do |p|
      its(:content) { should match(p) }
    end
    if os[:release] == '14.04'
      its(:md5sum) { should eq 'de65251e5d5011c6b746d98eed43207e' }
    elsif os[:release] == '16.04'
      its(:md5sum) { should eq 'f21a82388ac74e4919408bf8d5a1415b' }
    end
  end

  # test that postgres user was created and can login
  describe command( "export PGPASSWORD='postgres_password'; psql -U postgres -h localhost -l" ) do
    its(:stdout) { should match(%r(\s*Name\s+|\s+Owner\s+|\s+Encoding\s+|\s+Collate)) }
  end
end

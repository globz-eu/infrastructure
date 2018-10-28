require 'spec_helper'

describe 'basic_node::mail' do
  ['14.04', '16.04'].each do |version|
    context "When all attributes are default, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        runner = ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version)
        runner.converge(described_recipe)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'installs the ssmtp package' do
        expect(chef_run).to install_package( 'ssmtp' )
      end

      it 'installs the mailutils package' do
        expect(chef_run).to install_package( 'mailutils' )
      end

      it 'manages the ssmtp.conf file' do
        ssmtp_conf = [
            /^FromLineOverride=YES/,
            /^AuthUser=admin@example\.com/,
            /^AuthPass=password/,
            /^mailhub=smtp\.mail\.com:587/,
            /^UseSTARTTLS=YES/
        ]
        expect(chef_run).to create_template('/etc/ssmtp/ssmtp.conf').with(
            owner: 'root',
            group: 'root',
            mode: '0644',
            variables: {
                auth_user: 'admin@example.com',
                password: 'password',
                mail_hub: 'smtp.mail.com',
                TLS: 'YES',
                port: '587'
            }
        )
        ssmtp_conf.each do |s|
          expect(chef_run).to render_file('/etc/ssmtp/ssmtp.conf').with_content(s)
        end
      end
    end
  end
end

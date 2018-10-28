# Cookbook Name:: basic_node
# Spec:: firewall

require 'spec_helper'

describe 'basic_node::firewall' do
  ['14.04', '16.04'].each do |version|
    context "When all attributes are default, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version) do |node|
          node.set['basic_node']['firewall']['web_server'] = 'http'
        end.converge(described_recipe)
      end

      it 'converges successfully' do
        expect{ chef_run }.to_not raise_error
      end

      it 'enables the firewall' do
        expect( chef_run ).to install_firewall('default')
      end

      it 'creates firewall rules' do
        expect( chef_run ).to create_firewall_rule('min_out_tcp')
        expect( chef_run ).to create_firewall_rule('min_out_udp')
        expect( chef_run ).to create_firewall_rule('ssh')
      end

      it 'creates mail firewall rule' do
        expect( chef_run ).to create_firewall_rule('mail')
      end

      it 'creates http firewall rule' do
        expect( chef_run ).to create_firewall_rule('http')
      end
    end
  end
end

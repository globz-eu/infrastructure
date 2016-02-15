require 'spec_helper'

set :backend, :exec

expected_rules = [
    %r{Default: deny \(incoming\), deny \(outgoing\), disabled \(routed\)},
    ]

describe command( 'ufw status verbose' ) do
  its(:stdout) { should match(/Status: active/) }
  expected_rules.each do |r|
    its(:stdout) { should match(r) }
  end
end

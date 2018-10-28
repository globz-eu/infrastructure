# Cookbook Name:: basic_node
# Recipe:: firewall

include_recipe 'firewall::default'

firewall_rule 'min_out_tcp' do
  protocol :tcp
  direction :out
  command :allow
  port [22,53,80,443]
end

firewall_rule 'min_out_udp' do
  protocol :udp
  direction :out
  command :allow
  port [53,67,68]
end

firewall_rule 'ssh' do
  protocol :tcp
  direction :in
  command :allow
  port 22
end

firewall_rule 'mail' do
  protocol :tcp
  direction :out
  command :allow
  port 587
  only_if {node['basic_node']['firewall']['mail']}
end

firewall_rule 'http' do
  protocol :tcp
  direction :in
  command :allow
  port 80
  only_if {node['basic_node']['firewall']['web_server'].include? 'http'}
end

firewall_rule 'https' do
  protocol :tcp
  direction :in
  command :allow
  port 443
  only_if {node['basic_node']['firewall']['web_server'].include? 'https'}
end

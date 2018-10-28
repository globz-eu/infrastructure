# Use for public network
Vagrant.configure(2) do |config|
  config.vm.provision 'shell', inline: <<-SHELL
    route add default gw 192.168.1.1 eth2
    route del default eth0
    ip route change to default dev eth2 via 192.168.1.1
  SHELL
end

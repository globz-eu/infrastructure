package 'ntp'

service 'ntp' do
  action [:start, :enable]
end
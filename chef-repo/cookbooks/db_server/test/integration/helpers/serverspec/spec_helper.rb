require 'serverspec'
require 'pathname'
require 'net/http'
require 'net/smtp'
require 'json'

if (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM).nil?
  set :backend, :exec
else
  set :backend, :cmd
  set :os, family: 'windows'
end

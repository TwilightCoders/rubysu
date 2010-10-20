require 'drb/drb'
require 'fileutils'
require 'sudo'

socket = ARGV[0]

owner = ARGV[1]

uri = "drbunix:#{socket}"

DRb.start_service(uri, Sudo::Proxy.new) 

FileUtils.chown owner, 0, socket
FileUtils.chmod 0600, socket

DRb.thread.join



require 'drb/drb'
require 'sudo'

uri = ARGV[0] 

DRb.start_service(uri, Sudo::Proxy.new) 

DRb.thread.join



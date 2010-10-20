require 'drb/drb'
require 'fileutils'
require 'sudo/support/object'
require 'sudo/examples/abc'
require 'sudo'

URI="druby://localhost:8787" 

DRb.start_service(URI, Sudo::Proxy.new) 

DRb.thread.join



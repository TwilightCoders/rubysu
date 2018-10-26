module Sudo

  VERSION       = '0.1.0'
  ROOTDIR       = File.expand_path File.join File.dirname(__FILE__), '../..'
  LIBDIR        = File.join ROOTDIR, 'lib'
  SERVER_SCRIPT = File.join ROOTDIR, 'libexec/server.rb'
  SUDO_CMD      = ENV['rvm_path'] ? 'rvmsudo' : 'sudo'

  RuntimeError = Class.new(RuntimeError)

end

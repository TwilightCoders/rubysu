module Sudo

  VERSION       = '0.0.2.1'
  ROOTDIR       = File.expand_path File.join File.dirname(__FILE__), '../..'
  LIBDIR        = File.join ROOTDIR, 'lib'
  SERVER_SCRIPT = File.join ROOTDIR, 'libexec/server.rb'

  class RuntimeError  < RuntimeError; end

end

require 'drb/drb'
require 'sudo/support/kernel'
require 'sudo/support/object'
require 'sudo/support/process'
require 'sudo/wrapper'

module Sudo

  VERSION       = '0.0.1'
  ROOTDIR       = File.expand_path File.join File.dirname(__FILE__), '..'
  LIBDIR        = File.join ROOTDIR, 'lib'
  SERVER_SCRIPT = File.join ROOTDIR, 'libexec/server.rb'

  class RuntimeError  < RuntimeError; end

  module DSL
    def sudo_start(*args, &blk)
      @__default_sudo_wrapper = Sudo::Wrapper.new(*args, &blk).start!
    end
    def sudo_stop
      @__default_sudo_wrapper.stop!
    end
    def sudo(object)
      @__default_sudo_wrapper[object]
    end
  end

  class MethodProxy
    def initialize(object, proxy)
      @object = object
      @proxy = proxy
    end
    def method_missing(method=:self, *args, &blk)
      @proxy.proxy @object, method, *args, &blk
    end
  end

  class Proxy
    def proxy(object, method=:self, *args, &blk) 
      object.send method, *args, &blk
    end
  end

end

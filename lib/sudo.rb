require 'drb/drb'
require 'sudo/support/kernel'
require 'sudo/support/object'

begin
  DRb.current_server
rescue DRb::DRbServerNotFound
  DRb.start_service
end

module Sudo

  ROOTDIR       = File.expand_path File.join File.dirname(__FILE__), '..'
  LIBDIR        = File.join ROOTDIR, 'lib'
  SERVER_SCRIPT = File.join ROOTDIR, 'libexec/server.rb'

  class SudoFailed < RuntimeError; end

  class Wrapper

    class WrapperClosed < RuntimeError; end

    class << self
      alias open new
    end

    def initialize(ruby_opts='') 
      @open, @proxy = false, nil
      @socket = "/tmp/rubysu-#{rand(100000)}"
      server_uri = "drbunix:#{@socket}"

      # just to check if we can sudo; and we'll receive a sudo token
      raise SudoFailed unless system "sudo ruby -e ''"
      
      @server_pid = Process.spawn(
        "sudo ruby -I#{LIBDIR} #{ruby_opts} #{SERVER_SCRIPT} #{@socket} #{Process.uid}"
      )
      if wait_for(:timeout => 1){File.exists? @socket}
        @open = true
        @proxy = DRbObject.new_with_uri(server_uri)
        if block_given?
          yield self
          close
        end
      else
        raise RuntimeError, "Couldn't create DRb socket!" 
      end
    end

    def open?; @open; end

    def closed?; !@open; end

    def [](object)
      if @open
        MethodProxy.new object, @proxy
      else
        raise WrapperClosed, "Wrapper closed"
      end
    end
    
    def close
      if closed?
        raise WrapperClosed, "Wrapper already closed"
      else
        @proxy = nil
        @open = false
        system "sudo kill #{@server_pid}"
      end
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

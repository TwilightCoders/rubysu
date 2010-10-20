require 'drb/drb'
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

  class Wrapper

    class WrapperClosed < RuntimeError; end

    class << self
      alias open new
    end

    def initialize(ruby_opts='') 
      @socket = "/tmp/rubysu-#{rand(100000)}"
      server_uri = "drbunix:#{@socket}"
      @server_pid = Process.spawn(
        "sudo ruby -I#{LIBDIR} #{ruby_opts} #{SERVER_SCRIPT} #{@socket} #{Process.uid}"
      )
      loop do 
        if File.exists? @socket
          break
        else 
          # print '.'
          sleep(0.02)
        end
      end
      #at_exit{@server_thread.join}
      @open = true
      @proxy = DRbObject.new_with_uri(server_uri)
      if block_given?
        yield self
        close
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

require 'drb/drb'
require 'sudo/support/kernel'
require 'sudo/support/object'
require 'sudo/support/process'

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
      @proxy = nil
      @socket = "/tmp/rubysu-#{Process.pid}-#{object_id}" 
      server_uri = "drbunix:#{@socket}"

      # just to check if we can sudo; and we'll receive a sudo token
      raise SudoFailed unless system "sudo ruby -e ''"
      
      @server_pid = spawn( 
"sudo ruby -I#{LIBDIR} #{ruby_opts} #{SERVER_SCRIPT} #{@socket} #{Process.uid}"
      )
      at_exit do 
        if @server_pid and Process.exists? @server_pid
          system "sudo kill     #{@server_pid}"   or
          system "sudo kill -9  #{@server_pid}"
        end
      end

      if wait_for(:timeout => 1){File.exists? @socket}
        @proxy = DRbObject.new_with_uri(server_uri)
        if block_given?
          yield self
          close
        end
      else
        raise RuntimeError, "Couldn't create DRb socket!" 
      end
    end

    def open?  
      @server_pid and @proxy
    end

    def closed?; not open?; end

    def [](object)
      if open?
        MethodProxy.new object, @proxy
      else
        raise WrapperClosed, "Wrapper closed"
      end
    end
    
    def close
      @proxy = nil
      @server_pid = nil if system "sudo kill #{@server_pid}"
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

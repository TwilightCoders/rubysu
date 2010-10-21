require 'drb/drb'
require 'sudo/support/kernel'
require 'sudo/support/object'
require 'sudo/support/process'

begin
  DRb.current_server
rescue DRb::DRbServerNotFound
  DRb.start_service
end

module SudoMixin
  module Sudo
  end
  def sudo(object)
    @__default_sudo_wrapper[object]
  end
end

module Sudo

  ROOTDIR       = File.expand_path File.join File.dirname(__FILE__), '..'
  LIBDIR        = File.join ROOTDIR, 'lib'
  SERVER_SCRIPT = File.join ROOTDIR, 'libexec/server.rb'

  class RuntimeError  < RuntimeError; end

  module DSL
    def sudo_start(*args, &blk)
      @__default_sudo_wrapper = Sudo::Wrapper.new(*args, &blk)
    end
    def sudo_stop
      @__default_sudo_wrapper.close
    end
    def sudo(object)
      @__default_sudo_wrapper[object]
    end
  end

  class Wrapper

    class RuntimeError            < RuntimeError;   end
    class SudoFailed              < RuntimeError;   end
    class WrapperClosed           < RuntimeError;   end
    class SocketStillExists       < RuntimeError;   end
    class SudoProcessStillExists  < RuntimeError;   end
    class NoValidSocket           < RuntimeError;   end
    class SocketNotFound          < NoValidSocket;  end
    class NoValidSudoPid          < RuntimeError;   end
    class SudoProcessNotFound     < NoValidSudoPid; end

    class << self
      alias open new
    end

    def initialize(ruby_opts='') 
      @open = false
      @proxy = nil
      @socket = "/tmp/rubysu-#{Process.pid}-#{object_id}" 
      server_uri = "drbunix:#{@socket}"

      # just to check if we can sudo; and we'll receive a sudo token
      raise SudoFailed unless system "sudo ruby -e ''"
      
      @sudo_pid = spawn( 
"sudo ruby -I#{LIBDIR} #{ruby_opts} #{SERVER_SCRIPT} #{@socket} #{Process.uid}"
      )
      at_exit{close}

      if wait_for(:timeout => 1){File.exists? @socket}
        @proxy = DRbObject.new_with_uri(server_uri)
        @open = true if @proxy
        if block_given?
          yield self
          close
        end
      else
        raise RuntimeError, "Couldn't create DRb socket #{@socket}"  
      end
    end

    def open?; @open; end

    def closed?; not open?; end

    def properly_closed?
      if closed?
        raise SocketStillExists       if 
            (@socket and File.exists? @socket)
        raise SudoProcessStillExists  if 
            (@sudo_pid and Process.exists? @sudo_pid)
        return true
      end # otherwise return nil (as "Not Applicable")
    end

    def properly_open?
     if open?
       begin
         raise SocketNotFound unless File.exists? @socket
       rescue TypeError
         raise NoValidSocket, "@socket = #{@socket.inspect}" 
       end
       begin
         raise SudoProcessNotFound unless Process.exists? @sudo_pid
       rescue TypeError
         raise NoValidSudoPid, "@sudo_pid = #{@sudo_pid.inspect}"
       end
       return true
     end # otherwise return nil (as "Not Applicable")
    end

    def [](object)
      if open?
        MethodProxy.new object, @proxy
      else
        raise WrapperClosed, "Wrapper closed"
      end
    end
    
    def close
      if @sudo_pid and Process.exists? @sudo_pid
        system "sudo kill     #{@sudo_pid}"         or
        system "sudo kill -9  #{@sudo_pid}"         and
        @sudo_pid = nil
      end
      if @socket and File.exists? @socket
        system "sudo rm -f #{@socket}"                and
        @socket = nil
      end
      @proxy = nil
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

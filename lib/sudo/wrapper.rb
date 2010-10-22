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
  class Wrapper

    class RuntimeError              < RuntimeError;       end
    class NotRunning                < RuntimeError;       end
    class SudoFailed                < RuntimeError;       end
    class SocketStillExists         < RuntimeError;       end
    class SudoProcessExists         < RuntimeError;       end
    class SudoProcessAlreadyExists  < SudoProcessExists;  end
    class SudoProcessStillExists    < RuntimeError;       end
    class NoValidSocket             < RuntimeError;       end
    class SocketNotFound            < NoValidSocket;      end
    class NoValidSudoPid            < RuntimeError;       end
    class SudoProcessNotFound       < NoValidSudoPid;     end

    class << self

      # with blocks
      def run(*args)
        sudo = new(*args)
        yield sudo.start!
        sudo.stop!
      end 

      # Not an instance method, so it may act as a finalizer
      # (as in ObjectSpace.define_finalizer)
      def cleanup!(h)
        if h[:pid] and Process.exists? h[:pid]
          system "sudo kill     #{h[:pid]}"               or
          system "sudo kill -9  #{h[:pid]}"               or
          raise SudoProcessStillExists, 
            "Couldn't kill sudo process (PID=#{h[:pid]})" 
        end
        if h[:socket] and File.exists? h[:socket]
          system "sudo rm -f #{h[:socket]}"               or
          raise SocketStillExists,
              "Couldn't delete socket #{h[:socket]}"
        end
      end

    end

    def initialize(ruby_opts='') 
      @proxy      = nil
      @socket     = "/tmp/rubysu-#{Process.pid}-#{object_id}" 
      @sudo_pid   = nil
      @ruby_opts  = ruby_opts
    end

    def server_uri; "drbunix:#{@socket}"; end
    
    def start! 
      # just to check if we can sudo; and we'll receive a sudo token
      raise SudoFailed unless system "sudo ruby -e ''"

      raise SudoProcessAlreadyExists if @sudo_pid and Process.exists? @sudo_pid
      
      @sudo_pid = spawn( 
"sudo ruby -I#{LIBDIR} #{@ruby_opts} #{SERVER_SCRIPT} #{@socket} #{Process.uid}"
      ) 
      Process.detach(@sudo_pid) if @sudo_pid # avoid zombies
      ObjectSpace.define_finalizer self, Finalizer.new(
          :pid => @sudo_pid, :socket => @socket
      )

      if wait_for(:timeout => 1){File.exists? @socket}
        @proxy = DRbObject.new_with_uri(server_uri)
      else
        raise RuntimeError, "Couldn't create DRb socket #{@socket}"  
      end
      self
    end

    def running?
      true if (
        @sudo_pid and Process.exists? @sudo_pid and
        @socket   and File.exists?    @socket   and
        @proxy
      )
    end

    def stop!
      self.class.cleanup!(:pid => @sudo_pid, :socket => @socket)
      @proxy = nil

    end

    def [](object)
      if running?
        MethodProxy.new object, @proxy
      else
        raise NotRunning
      end
    end

    # Inspired by Remover class in tmpfile.rb (Ruby std library)
    class Finalizer
      def initialize(h)
        @data = h
      end

      # mimic proc-like behavior (walk like a duck)
      def call(*args)
        Sudo::Wrapper.cleanup! @data
      end
    end

  end
end

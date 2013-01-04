require 'drb/drb'
require 'drb/acl'
require 'sudo/support/kernel'
require 'sudo/support/process'
require 'sudo/constants'
require 'sudo/system'
require 'sudo/proxy'

begin
  DRb.current_server
rescue DRb::DRbServerNotFound
  DRb.start_service nil, nil,
    ACL.new(%w{ deny all allow 127.0.0.1 }, ACL::DENY_ALLOW)
end

module Sudo
  class Wrapper

    class RuntimeError              < RuntimeError;       end
    class NotRunning                < RuntimeError;       end
    class SudoFailed                < RuntimeError;       end
    class SudoProcessExists         < RuntimeError;       end
    class SudoProcessAlreadyExists  < SudoProcessExists;  end
    class NoValidSocket             < RuntimeError;       end
    class SocketNotFound            < NoValidSocket;      end
    class NoValidSudoPid            < RuntimeError;       end
    class SudoProcessNotFound       < NoValidSudoPid;     end

    class << self

      # Yields a new running Sudo::Wrapper, and do all the necessary
      # cleanup when the block exits.
      #
      # ruby_opts:: is passed to Sudo::Wrapper::new .
      def run(ruby_opts = '') # :yields: sudo
        sudo = new(ruby_opts).start!
        yield sudo
        sudo.stop!
      end

      # currently unused
      #def load_features
      #  ObjectSpace.each_object(self).each{|x| x.load_features}
      #end

      # Do the actual resources clean-up.
      #
      # Not an instance method, so it may act as a Finalizer
      # (as in ::ObjectSpace::define_finalizer)
      def cleanup!(h)
        Sudo::System.kill   h[:pid]
        Sudo::System.unlink h[:socket]
      end

    end

    # +ruby_opts+ are the command line options to the sudo ruby interpreter;
    # usually you don't need to specify stuff like "-rmygem/mylib", libraries
    # will be sorta "inherited".
    def initialize(ruby_opts='')
      @proxy            = nil
      @socket           = "/tmp/rubysu-#{Process.pid}-#{object_id}"
      @sudo_pid         = nil
      @ruby_opts        = ruby_opts
      @loaded_features  = []
      # @load_path        = [] # currentl unused
    end

    def server_uri; "drbunix:#{@socket}"; end

    # Start the sudo-ed Ruby process.
    def start!
      Sudo::System.check

      @sudo_pid = spawn(
"#{SUDO_CMD} ruby -I#{LIBDIR} #{@ruby_opts} #{SERVER_SCRIPT} #{@socket} #{Process.uid}"
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

      #set_load_path # apparently, we don't need this

      load_features

      self
    end

    # apparently, we don't need this
    #def set_load_path
    #  ($LOAD_PATH - @load_path).reverse.each do |dir|
    #    @proxy.proxy Kernel, :eval, "$LOAD_PATH.unshift #{dir}"
    #  end
    #end

    # Load needed libraries in the DRb server. Usually you don't need
    # to call this directly.
    def load_features
      unless $LOADED_FEATURES == @loaded_features
        new_features = $LOADED_FEATURES - @loaded_features
        new_features.each do |feature|
          @proxy.proxy Kernel, :require, feature
          @loaded_features << feature
        end
        #@loaded_features += new_features
      end
    end

    def running?
      true if (
        @sudo_pid and Process.exists? @sudo_pid and
        @socket   and File.exists?    @socket   and
        @proxy
      )
    end

    # Free the resources opened by this Wrapper: e.g. the sudo-ed
    # ruby process and the Unix-domain socket used to communicate
    # to it via ::DRb.
    def stop!
      self.class.cleanup!(:pid => @sudo_pid, :socket => @socket)
      @proxy = nil
    end

    # Gives a copy of +object+ with root privileges.
    def [](object)
      if running?
        load_features
        MethodProxy.new object, @proxy
      else
        raise NotRunning
      end
    end

    # Inspired by Remover class in tmpfile.rb (Ruby std library).
    # You don't want to use this class directly.
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

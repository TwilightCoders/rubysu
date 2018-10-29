require 'drb/drb'
require 'sudo/support/kernel'
require 'sudo/support/process'
require 'sudo/constants'
require 'sudo/system'
require 'sudo/proxy'

module Sudo

  class Wrapper

    RuntimeError             = Class.new(RuntimeError)
    NotRunning               = Class.new(RuntimeError)
    SudoFailed               = Class.new(RuntimeError)
    SudoProcessExists        = Class.new(RuntimeError)
    SudoProcessAlreadyExists = Class.new(SudoProcessExists)
    NoValidSocket            = Class.new(RuntimeError)
    SocketNotFound           = Class.new(NoValidSocket)
    NoValidSudoPid           = Class.new(RuntimeError)
    SudoProcessNotFound      = Class.new(NoValidSudoPid)

    class << self

      # Yields a new running Sudo::Wrapper, and do all the necessary
      # cleanup when the block exits.
      #
      # ruby_opts:: is passed to Sudo::Wrapper::new .
      def run(ruby_opts: '', load_gems: true, password: nil) # :yields: sudo
        sudo = new(ruby_opts: ruby_opts, load_gems: load_gems, password: password).start!
        retval = yield sudo
        sudo.stop!
        retval
      end

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
    def initialize(ruby_opts: '', load_gems: true, password: nil)
      @proxy            = nil
      @socket           = "/tmp/rubysu-#{Process.pid}-#{object_id}"
      @sudo_pid         = nil
      @ruby_opts        = ruby_opts
      @load_gems        = load_gems == true
    end

    def server_uri; "drbunix:#{@socket}"; end

    # Start the sudo-ed Ruby process.
    def start!
      Sudo::System.check

      @sudo_pid = spawn(
"#{SUDO_CMD} -E ruby -I#{LIBDIR} #{@ruby_opts} #{SERVER_SCRIPT} #{@socket} #{Process.uid}"
      )
      Process.detach(@sudo_pid) if @sudo_pid # avoid zombies
      finalizer = Finalizer.new(pid: @sudo_pid, socket: @socket)
      ObjectSpace.define_finalizer(self, finalizer)

      if wait_for(timeout: 1){File.exists? @socket}
        @proxy = DRbObject.new_with_uri(server_uri)
      else
        raise RuntimeError, "Couldn't create DRb socket #{@socket}"
      end

      loadit!

      self
    end

    def loadit!
      load_gems if load_gems?
    end

    def load_gems?
      @load_gems == true
    end

    # Load needed libraries in the DRb server. Usually you don't need
    def load_gems
      load_paths
      prospective_gems = (Gem.loaded_specs.keys - @proxy.loaded_specs.keys)
      prospective_gems.each do |prospective_gem|
        gem_name = prospective_gem.dup
        begin
          loaded = @proxy.proxy(Kernel, :require, gem_name)
          # puts "Loading Gem: #{gem_name} => #{loaded}"
        rescue LoadError, NameError => e
          old_gem_name = gem_name.dup
          gem_name.gsub!('-', '/')
          if old_gem_name == gem_name
            # puts "Skipping #{gem_name}"
            next
          else
            # puts "Retrying #{old_gem_name} as #{gem_name}"
            retry
          end
        end
      end
    end

    def load_paths
      host_paths = $LOAD_PATH
      proxy_paths = @proxy.load_path
      diff_paths = host_paths - proxy_paths
      diff_paths.each do |path|
        @proxy.add_load_path(path)
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
      self.class.cleanup!(pid: @sudo_pid, socket: @socket)
      @proxy = nil
    end

    # Gives a copy of +object+ with root privileges.
    def [](object)
      if running?
        loadit!
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

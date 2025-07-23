require 'drb/drb'
require 'sudo/support/kernel'
require 'sudo/support/process'
require 'sudo/constants'
require 'sudo/configuration'
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
      def run(ruby_opts: '', **config) # :yields: sudo
        sudo = new(ruby_opts: ruby_opts, config: Configuration.new(config)).start!
        yield sudo
      rescue Exception => e # Bubble all exceptions...
        raise e
      ensure # and ensure sudo stops
        sudo.stop! if sudo
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
    def initialize(ruby_opts: '', config: nil)
      @config           = config || Sudo.configuration
      @proxy            = nil
      @socket           = @config.socket_path(Process.pid, SecureRandom.hex(8))
      @sudo_pid         = nil
      @ruby_opts        = ruby_opts
      @load_gems        = @config.load_gems
      @timeout          = @config.timeout
      @retries          = @config.retries
    end

    def server_uri; "drbunix:#{@socket}"; end

    # Start the sudo-ed Ruby process.
    def start!
      Sudo::System.check

      cmd_args, env = Sudo::System.command(@ruby_opts, @socket)
      
      @sudo_pid = spawn(env, *cmd_args)
      Process.detach(@sudo_pid) if @sudo_pid # avoid zombies
      finalizer = Finalizer.new(pid: @sudo_pid, socket: @socket)
      ObjectSpace.define_finalizer(self, finalizer)

      if wait_for(timeout: @timeout) { socket? }
        @proxy = DRbObject.new_with_uri(server_uri)
      else
        raise RuntimeError, "Couldn't create DRb socket #{@socket} within #{@timeout} seconds"
      end

      load!

      self
    end

    def socket?
      File.exist?(@socket)
    end

    def running?
      Process.exists?(@sudo_pid) && socket? && @proxy
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
        load!
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

    protected

    def load!
      load_gems if load_gems?
    end

    def load_gems?
      @load_gems == true
    end

    def prospective_gems
      proxy_loaded_specs = @proxy.loaded_specs
      local_loaded_specs = Gem.loaded_specs.keys
      (local_loaded_specs - proxy_loaded_specs)
    rescue => e
      # Fallback if DRb marshaling fails with newer Bundler versions
      warn "Warning: Could not compare loaded gems (#{e.class}: #{e.message}). Skipping gem loading."
      []
    end

    # Load needed libraries in the DRb server. Usually you don't need
    def load_gems
      load_paths
      prospective_gems.each do |prospect|
        try_gem_variants(prospect)
      end
    end

    private

    def try_gem_variants(gem_name)
      [gem_name, gem_name.gsub('-', '/')].uniq.each do |variant|
        @proxy.proxy(Kernel, :require, variant)
        return # Success, stop trying variants
      rescue LoadError, NameError
        # Try next variant
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
  end
end

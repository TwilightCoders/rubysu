require 'sudo/support/process'
require 'sudo/constants'

module Sudo
  module System
    ProcessStillExists  = Class.new(RuntimeError)
    FileStillExists     = Class.new(RuntimeError)

    class << self
      def kill(pid)
        if pid and Process.exists? pid
          system("sudo", "kill", pid.to_s) or
            system("sudo", "kill", "-9", pid.to_s) or
            raise ProcessStillExists, "Couldn't kill sudo process (PID=#{pid})"
        end
      end

      def command(ruby_opts, socket, env = {})
        cmd_args, env = command_base(env)
        cmd_args << "-I#{LIBDIR}"
        cmd_args.concat(ruby_opts.split) unless ruby_opts.empty?
        cmd_args.concat([SERVER_SCRIPT.to_s, socket, Process.uid.to_s])
        [cmd_args, env]
      end

      def unlink(file)
        if file and File.exist? file
          system("sudo", "rm", "-f", file) or
            raise(FileStillExists, "Couldn't delete #{file}")
        end
      end

      # just to check if we can sudo; and we'll receive a sudo token
      def check
        cmd_args, env = command_base
        cmd_args.concat(["-e", ""])
        raise Sudo::Wrapper::SudoFailed unless system(env, *cmd_args)
      end

      private

      def command_base(env = {})
        cmd_args = [SUDO_CMD]

        if defined?(Sudo.configuration) && Sudo.configuration.sudo_askpass
          env["SUDO_ASKPASS"] = Sudo.configuration.sudo_askpass
          cmd_args << "-A"
        end

        cmd_args.concat(["-E", RUBY_CMD])
        [cmd_args, env]
      end
    end
  end
end

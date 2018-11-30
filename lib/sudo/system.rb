require 'sudo/support/process'
require 'sudo/constants'

module Sudo
  module System

    ProcessStillExists  = Class.new(RuntimeError)
    FileStillExists     = Class.new(RuntimeError)

    class << self

      def kill(pid)
        if pid and Process.exists? pid
          system "sudo kill     #{pid}" or
          system "sudo kill -9  #{pid}" or
          raise ProcessStillExists, "Couldn't kill sudo process (PID=#{pid})"
        end
      end

      def command(ruby_opts, socket)
        [
          SUDO_CMD,
          '-E',
          RUBY_CMD,
          "-I#{LIBDIR}",
          ruby_opts,
          SERVER_SCRIPT,
          socket,
          Process.uid
        ].join(' ')
      end

      def unlink(file)
        if file and File.exists? file
          system("sudo rm -f #{file}") or
          raise(FileStillExists, "Couldn't delete #{file}")
        end
      end

      # just to check if we can sudo; and we'll receive a sudo token
      def check
        raise SudoFailed unless system "#{SUDO_CMD} -E #{RUBY_CMD} -e ''"
      end

    end
  end
end

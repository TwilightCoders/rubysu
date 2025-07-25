require 'pathname'

module Sudo
  VERSION = '0.4.0'

  def self.root
    @root ||= Pathname.new(File.expand_path('../../', __dir__))
  end

  LIBDIR        = root.join('lib')
  SERVER_SCRIPT = root.join('libexec/server.rb')
  SUDO_CMD      = `which sudo`.chomp
  RUBY_CMD      = `which ruby`.chomp
  ASK_PATH_CMD  = `which ssh-askpass`.chomp

  RuntimeError = Class.new(RuntimeError)
end

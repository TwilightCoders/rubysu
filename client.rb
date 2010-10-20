require 'drb/drb'
require 'fileutils'
require 'sudo/support/object'
require 'sudo/examples/abc'
require 'sudo'


  su = Sudo::Wrapper.open 

  su[File].open '/TEST', 'w' do |f|
    f.puts "Hello from UID=#{su[Process].uid}!"
  end

  ab = A::B.new

  puts su[ab].c

  su[FileUtils].cp '/etc/shadow', '/etc/shadow2'

  su.close

  su.close







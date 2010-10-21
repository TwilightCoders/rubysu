require 'fileutils'
require 'sudo'

su = Sudo::Wrapper.new('-rfileutils')

su.start!

su[File].open '/TEST', 'w' do |f|
  f.puts "Hello from UID=#{su[Process].uid}!"
end

su[FileUtils].cp '/etc/shadow', '/etc/shadow2'

su.stop!







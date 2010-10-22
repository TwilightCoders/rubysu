require 'fileutils'
require 'sudo'

su = Sudo::Wrapper.new('-rfileutils')

su.start!

su[File].open '/TEST', 'w' do |f|
  f.puts "Hello from UID=#{su[Process].uid}!"
end

su[FileUtils].cp '/etc/shadow', '/etc/shadow2'

# i you don't call stop! explicitly, the corresponding process and file
# cleanup will be done automatically, when the object gets out of scope
#
# su.stop!








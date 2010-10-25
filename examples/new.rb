require 'fileutils'
autoload :IPAddr, 'ipaddr'
require 'sudo'

# Requires and autoloads are inherited by the sudo process.

su = Sudo::Wrapper.new

su.start!

su[File].open '/TEST', 'w' do |f|
  f.puts "Hello from UID=#{su[Process].uid}!"
  f.puts "#{su[IPAddr].new}"
end

su[FileUtils].cp '/etc/shadow', '/etc/shadow2'

# If you don't call stop! explicitly, the corresponding process and file
# cleanup will be done when su gets garbage-collected.
#
su.stop!








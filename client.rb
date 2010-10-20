require 'drb/drb'
require 'fileutils'
require 'sudo/support/object'
require 'sudo/examples/abc'
require 'sudo'


SERVER_URI="druby://localhost:8787"

DRb.start_service

@sudo_proxy = DRbObject.new_with_uri(SERVER_URI)

include Sudo::Su


 
su(File).open '/TEST', 'w' do |f|
  f.puts "Hello from UID=#{su(Process).uid}!"
end

ab = A::B.new

puts su(ab).c

su(FileUtils).cp '/etc/shadow', '/etc/shadow2'









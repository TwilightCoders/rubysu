require 'fileutils'
require 'sudo'

Sudo::Wrapper.run('-rfileutils') do |su|

  su[File].open '/TEST', 'w' do |f|
    f.puts "Hello from UID=#{su[Process].uid}!"
  end

  su[FileUtils].cp '/etc/shadow', '/etc/shadow2'

end







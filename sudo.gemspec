# -*- encoding: utf-8 -*-

$LOAD_PATH.unshift( File.dirname(__FILE__) + '/lib' )

require 'sudo'

Gem::Specification.new do |s|
  s.name = %q{sudo}
  s.version = Sudo::VERSION
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Guido De Rosa"]
  s.date = Time.now.to_date.to_s
  s.description = <<END
Give Ruby objects superuser privileges.

Based on dRuby and sudo (the Unix program).
END
  s.email = %q{guido.derosa@vemarsas.it}
  s.files = [
    "lib/sudo/support/object.rb", 
    "lib/sudo/support/kernel.rb", 
    "lib/sudo/support/process.rb", 
    "lib/sudo/wrapper.rb", 
    "lib/sudo.rb", 
    "libexec/server.rb", 
    "examples/block.rb", 
    "examples/dsl.rb", 
    "examples/new.rb", 
    "README.rdoc"
  ]
  s.homepage = %q{http://github.com/gderosa/rubysu}
  #s.post_install_message = %q{}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = `gem -v`.strip
  s.summary = %q{Give Ruby objects superuser privileges}
end

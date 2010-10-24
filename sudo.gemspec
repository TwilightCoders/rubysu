# -*- encoding: utf-8 -*-

ROOTDIR = File.dirname(__FILE__)
$LOAD_PATH.unshift( ROOTDIR + '/lib' )

require 'date'
require 'sudo/constants'

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
  s.files = File.readlines("#{ROOTDIR}/MANIFEST").map{|s| s.chomp}  
  s.homepage = %q{http://github.com/gderosa/rubysu}
  #s.post_install_message = %q{}
  s.rdoc_options = ["--charset=UTF-8", "--main", "README.rdoc"]
  s.extra_rdoc_files = ["README.rdoc"]
  s.require_paths = ["lib"]
  s.rubygems_version = `gem -v`.strip
  s.summary = %q{Give Ruby objects superuser privileges}
end

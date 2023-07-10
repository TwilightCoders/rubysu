# coding: utf-8
require_relative 'lib/sudo/constants'

Gem::Specification.new do |spec|
  spec.name         = "sudo"
  spec.version      = Sudo::VERSION
  spec.authors      = ["Guido De Rosa"]
  spec.email        = ["guidoderosa@gmail.com"]

  spec.summary      = %q{Give Ruby objects superuser privileges}
  spec.description  = <<~DESC
                        Give Ruby objects superuser privileges.
                        Based on dRuby and sudo (the Unix program).
                      DESC
  spec.homepage     = "https://github.com/TwilightCoders/rubysu"
  spec.license      = "MIT"

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.files         = Dir['CHANGELOG.md', 'README.md', 'LICENSE', 'lib/**/*', 'libexec/**/*']
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.3'

  spec.add_development_dependency 'pry-byebug', '~> 3'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec'

end


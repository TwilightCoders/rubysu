[![Gem Version](https://badge.fury.io/rb/sudo.svg)](https://badge.fury.io/rb/sudo)[![Build Status](https://travis-ci.com/gderosa/rubysu.svg?branch=master)](https://travis-ci.com/gderosa/rubysu)
[![Maintainability](https://api.codeclimate.com/v1/badges/3fdebfb836bebb531fb3/maintainability)](https://codeclimate.com/github/gderosa/rubysu/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/3fdebfb836bebb531fb3/test_coverage)](https://codeclimate.com/github/gderosa/rubysu/test_coverage)

# Ruby Sudo

Give Ruby objects superuser privileges.

Based on [dRuby](http://ruby-doc.org/stdlib-2.5.3/libdoc/drb/rdoc/DRb.html) and [sudo](http://www.sudo.ws/).

Tested with [MRI](http://en.wikipedia.org/wiki/Ruby_MRI) Ruby 2.7, 3.0, 3.1, 3.2, and 3.3.

## Usage

Your user must be allowed, in `/etc/sudoers`, to run `ruby` and `kill`
commands as root.

A password may be required from the console, depending on the
`NOPASSWD` options in `/etc/sudoers`.

Spawns a sudo-ed Ruby process running a
[DRb](http://ruby-doc.org/stdlib-2.5.3/libdoc/drb/rdoc/DRb.html) server. Communication is
done via a Unix socket (and, of course, permissions are set to `0600`).

No long-running daemons involved, everything is created on demand.

Access control is entirely delegated to `sudo`.

### Application Code

Let's start with a trivial example:

```ruby
require 'my_gem/my_class'
require 'sudo'

obj   = MyGem::MyClass.new

# Now, create a Sudo::Wrapper object:
sudo  = Sudo::Wrapper.new

# 'mygem/myclass' will be automatically required in the
# sudo DRb server

# Start the sudo-ed Ruby process:
sudo.start!
sudo[obj].my_instance_method
sudo[MyClass].my_class_method

# Call stop! when finished, otherwise, that will be done
# when the `sudo` object gets garbage-collected.
sudo.stop!
```

A convienient utility for working with sudo is to use the `run` method and pass it a block.
Run will automatically start and stop the ruby sudo process around the block.

```ruby
require 'fileutils'
require 'sudo'

Sudo::Wrapper.run do |sudo|
  sudo[FileUtils].mkdir_p '/ONLY/ROOT/CAN/DO/THAT'
end
# Sockets and processes are closed automatically when the block exits
```

Both `Sudo::Wrapper.run` and `Sudo::Wrapper.new` take the same named arguments: `ruby_opts` (default: `''` ) and `load_gems` (default: `true`).

If you'd like to pass options to the sudo-spawned ruby process, pass them as a string to `ruby_opts`.

If you'd like to prevent the loading of `gems` currently loaded from the calling program, pass `false` to `load_gems`. This will give your sudo process a unmodifed environment. The only things required via the sudo process are `'drb/drb'`, `'fileutils'`, and of course `'sudo'`.

## Todo

`sudo` has a `-A` option to accept password via an external program (maybe
graphical): support this feature.

## Credits

### Author and Copyright

Guido De Rosa ([@gderosa](http://github.com/gderosa/)).

See LICENSE.

### Contributors

Dale Stevens ([@voltechs](https://github.com/voltechs))

Robert M. Koch ([@threadmetal](https://github.com/threadmetal))

Wolfgang Teuber ([@wteuber](https://github.com/wteuber))

### Other aknowledgements


Thanks to Tony Arcieri and Brian Candler for suggestions on
[ruby-talk](http://www.ruby-forum.com/topic/262655).

Initially developed by G. D. while working at [@vemarsas](https://github.com/vemarsas).

## Contributing

1. Fork it ( https://github.com/TwilightCoders/rubysu/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

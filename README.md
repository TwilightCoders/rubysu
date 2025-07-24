[![Gem Version](https://badge.fury.io/rb/sudo.svg)](https://badge.fury.io/rb/sudo)
[![CI](https://github.com/TwilightCoders/rubysu/actions/workflows/ci.yml/badge.svg)](https://github.com/TwilightCoders/rubysu/actions/workflows/ci.yml)
[![Maintainability](https://qlty.sh/badges/e63e40be-4d72-4519-ad77-d4f94803a7b9/maintainability.svg)](https://qlty.sh/TwilightCoders/rubysu)
[![Test Coverage](https://qlty.sh/badges/e63e40be-4d72-4519-ad77-d4f94803a7b9/test_coverage.svg)](https://qlty.sh/gh/TwilightCoders/projects/rubysu/metrics/code?sort=coverageRating)
![GitHub License](https://img.shields.io/github/license/twilightcoders/rubysu)

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

A convenient utility for working with sudo is to use the `run` method and pass it a block.
Run will automatically start and stop the ruby sudo process around the block.

```ruby
require 'fileutils'
require 'sudo'

Sudo::Wrapper.run do |sudo|
  sudo[FileUtils].mkdir_p '/ONLY/ROOT/CAN/DO/THAT'
end
# Sockets and processes are closed automatically when the block exits
```

Both `Sudo::Wrapper.run` and `Sudo::Wrapper.new` accept configuration options:

- `ruby_opts` (default: `''`) - Options to pass to the sudo-spawned ruby process
- Any configuration option can be passed to override global settings (e.g., `timeout`, `load_gems`, `socket_dir`, etc.)

If you'd like to prevent the loading of `gems` currently loaded from the calling program, pass `load_gems: false`. This will give your sudo process an unmodified environment. The only things required via the sudo process are `'drb/drb'`, `'fileutils'`, and of course `'sudo'`.

### New DSL (v0.4.0+)

For simple operations, you can use the convenience method:

```ruby
require 'sudo'

# Accepts the same options as Wrapper.run:
Sudo.as_root(load_gems: false) do |sudo|
  sudo[FileUtils].mkdir_p '/root/only/path'
  sudo[File].write '/etc/config', content
end
```

### Configuration (v0.4.0+)

Configure global defaults:

```ruby
Sudo.configure do |config|
  config.timeout = 30           # Default: 10 seconds
  config.socket_dir = '/var/run' # Default: '/tmp'
  config.sudo_askpass = '/usr/bin/ssh-askpass'  # For graphical password prompts
  config.load_gems = false      # Default: true - whether to load current gems in sudo process
end
```

### Graphical Password Prompts (v0.4.0+)

Set `sudo_askpass` to use graphical password prompts via `sudo -A`:

```ruby
Sudo.configure do |config|
  config.sudo_askpass = '/usr/bin/ssh-askpass'
  # Or use the auto-detected constant for convenience:
  # config.sudo_askpass = Sudo::ASK_PATH_CMD
end

# Or per-wrapper:
Sudo::Wrapper.run(sudo_askpass: '/usr/bin/ssh-askpass') do |sudo|
  sudo[FileUtils].mkdir_p '/secure/path'
end
```

### Timeouts (v0.4.0+)

Configure connection timeouts:

```ruby
# Global configuration
Sudo.configure do |config|
  config.timeout = 15  # Wait up to 15 seconds for sudo process to start
end

# Or per-wrapper
Sudo::Wrapper.run(timeout: 5) do |sudo|
  sudo[SomeClass].time_sensitive_operation
end
```

## Credits

### Author and Copyright

Guido De Rosa ([@gderosa](http://github.com/gderosa/)).

See ([LICENSE](https://github.com/TwilightCoders/rubysu/blob/main/LICENSE)).

### Contributors

- Dale Stevens ([@voltechs](https://github.com/voltechs))
- Robert M. Koch ([@threadmetal](https://github.com/threadmetal))
- Wolfgang Teuber ([@wteuber](https://github.com/wteuber))

### Acknowledgements

- Thanks to Tony Arcieri and Brian Candler for suggestions on [ruby-talk](http://www.ruby-forum.com/topic/262655).
- Initially developed by Guido De Rosa while working at [@vemarsas](https://github.com/vemarsas).

## Contributing

1. Fork it ( <https://github.com/TwilightCoders/rubysu/fork> )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

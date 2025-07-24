# Sudo

<!--
Emoji Legend:
🎉 Initial Release   ✨ Feature         🐛 Bug Fix        🔒 Security
🚀 Compatibility    💥 Breaking        🔧 Internal       ✅ Testing
📚 Documentation    📄 License         🗑️ Removed
-->

## `v0.4.0-rc1` _(July 23, 2025)_

- 🔒 **Security**: Fix command injection vulnerabilities in system calls
- 🔒 **Security**: Use SecureRandom for socket paths instead of predictable object_id
- ✨ **Feature**: Add configuration system with global defaults
- ✨ **Feature**: Implement sudo -A flag support for graphical password prompts
- ✨ **Feature**: Add Sudo.as_root convenience method for better DSL
- ✨ **Feature**: Add configurable timeouts
- ✨ **Feature**: Add respond_to_missing? for proper method reflection
- 💥 **Breaking**: Minimum Ruby version bumped to 2.7+ (EOL compliance)
- 🔧 **Internal**: Modernize Ruby code with keyword arguments and array-form system calls
- 🔧 **Internal**: Improve test coverage and add configuration tests

<details>
<summary>📜 Historical Releases</summary>

## `v0.3.0` _(July 04, 2023)_

- 🚀 **Compatibility**: Add Ruby 3.2 support
- 🐛 **Fix**: Resolve Bundler::StubSpecification marshaling issues

## `v0.2.0` _(November 05, 2018)_

- 🔧 **Internal**: Complete code modernization and cleanup
- ✅ **Testing**: Add comprehensive RSpec test suite (98%+ coverage)
- 🚀 **Compatibility**: Support Ruby 2.3, 2.4, and 2.5
- 🐛 **Fix**: Improve gem and dependency loading robustness
- 🐛 **Fix**: Ensure sudo process properly stops when run block ends
- 🐛 **Fix**: Fix Wrapper.run to properly return values
- 🐛 **Fix**: Resolve infinite recursion under Bundler
- 🔒 **Security**: Restrict DRb access to localhost only
- 📚 **Documentation**: Extensive README and code documentation improvements

## `v0.1.0` _(October 25, 2010)_

- 📄 **License**: Switch to MIT license
- ✨ **Feature**: Add auto-require and autoload support
- 🔧 **Internal**: Modularize codebase architecture
- 📚 **Documentation**: Extensive documentation improvements
- 🗑️ **Removed**: Remove confusing DSL features (temporarily)

## `v0.0.2` _(October 22, 2010)_

- 📚 **Documentation**: Correct RDoc options in gemspec
- 🔧 **Internal**: Minor packaging improvements

## `v0.0.1` _(October 22, 2010)_

- 🎉 **Initial**: First public release
- ✨ **Feature**: Core sudo wrapper functionality with DRb
- ✨ **Feature**: Unix domain socket communication
- ✨ **Feature**: Process spawning and management
- ✨ **Feature**: Basic object proxying through sudo

</details>

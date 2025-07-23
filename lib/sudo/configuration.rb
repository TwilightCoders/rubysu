# frozen_string_literal: true

require 'securerandom'

# Sudo module provides superuser privileges to Ruby objects
module Sudo
  # Configuration class for managing global sudo settings
  class Configuration < Hash
    private :[], :[]=

    DEFAULTS = {
      timeout: 10,
      retries: 3,
      socket_dir: '/tmp',
      sudo_askpass: nil,
      load_gems: true
    }.freeze

    def initialize(config = {}, **kwargs)
      super()
      merge!(@configuration || DEFAULTS)
      merge!(config.merge(kwargs).slice(*DEFAULTS.keys))
    end

    def socket_path(pid, random_id)
      File.join(self[:socket_dir], "rubysu-#{pid}-#{random_id}")
    end

    def method_missing(method, *args, &block)
      method_name = method.to_s

      if method_name.end_with?('=')
        key = method_name.chomp('=').to_sym
        if DEFAULTS.key?(key)
          self[key] = args.first
        else
          super
        end
      elsif DEFAULTS.key?(method)
        self[method]
      else
        super
      end
    end

    def respond_to_missing?(method, include_private = false)
      method_name = method.to_s
      key = method_name.end_with?('=') ? method_name.chomp('=').to_sym : method
      DEFAULTS.key?(key) || super
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end

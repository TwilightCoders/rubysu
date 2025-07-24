module Sudo
  class MethodProxy
    def initialize(object, proxy)
      @object = object
      @proxy = proxy
    end

    def method_missing(method = :itself, *args, &blk)
      @proxy.proxy @object, method, *args, &blk
    end

    def respond_to_missing?(method, include_private = false)
      @object.respond_to?(method, include_private) || super
    end
  end

  class Proxy
    def proxy(object, method = :itself, *args, &blk)
      object.send method, *args, &blk
    end

    def loaded_specs
      # Return only the keys (gem names) to avoid marshaling StubSpecification objects
      # which can fail in newer Bundler versions
      Gem.loaded_specs.keys
    rescue => e
      warn "Warning: Could not get loaded gem specs (#{e.class}: #{e.message}). Returning empty list."
      []
    end

    def load_path
      $LOAD_PATH
    end

    def add_load_path(path)
      $LOAD_PATH << path
    end
  end
end

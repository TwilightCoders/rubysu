require 'pry'

module Sudo

  class MethodProxy
    def initialize(object, proxy)
      @object = object
      @proxy = proxy
    end
    def method_missing(method=:itself, *args, &blk)
      @proxy.proxy @object, method, *args, &blk
    end
  end

  class Proxy
    def proxy(object, method=:itself, *args, &blk)
      object.send method, *args, &blk
    end

    def call(object, method=:itself, &blk)
      object.send method, &blk
    end

    # def loaded_features
    #   $LOADED_FEATURES
    # end

    # def features
    #   # loaded_features.map { |feature| File.dirname(feature) }.
    #   loaded_features.
    #     select { |feature| feature.include?('gems') && feature =~ /.rb$/}.
    #     uniq.sort
    # end

    def loaded_specs
      # Something's weird with this method when called outside
      Gem.loaded_specs.to_a.to_h
    end

    def load_path
      $LOAD_PATH
    end

    def add_load_path(path)
      $LOAD_PATH << path
    end
  end

end

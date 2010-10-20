require 'drb/drb'
require 'sudo/support/object'

begin
  DRb.current_server
rescue DRb::DRbServerNotFound
  DRb.start_service
end

module Sudo

  # def self.open; Wrapper.open; end

  class Wrapper

    class << self

      def open
        server_uri = "druby://localhost:8787"
        sudo_proxy = DRbObject.new_with_uri(server_uri)
        wrapper = Sudo::Wrapper.new sudo_proxy
        if block_given?
          yield wrapper
          wrapper.close
        else
          wrapper
        end
      end

    end

    def initialize(proxy)
      @proxy = proxy
    end
    def [](object)
      MethodProxy.new object, @proxy
    end
    def close
      @proxy = nil
    end
  end

  class MethodProxy
    def initialize(object, proxy)
      @object = object
      @proxy = proxy
    end
    def method_missing(method=:self, *args, &blk)
      @proxy.proxy @object, method, *args, &blk
    end
  end

  class Proxy
    def proxy(object, method=:self, *args, &blk) 
      object.send method, *args, &blk
    end
  end

end

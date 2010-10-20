require 'drb/drb'
require 'sudo/support/object'

begin
  DRb.current_server
rescue DRb::DRbServerNotFound
  DRb.start_service
end

module Sudo

  class Wrapper

    class WrapperClosed < RuntimeError; end

    class << self
      alias open new
    end

    def initialize
      @open = true
      server_uri = "druby://localhost:8787"
      @proxy = DRbObject.new_with_uri(server_uri)
      if block_given?
        yield self
        close
      end
    end

    def open?; @open; end

    def closed?; !@open; end

    def [](object)
      if @open
        MethodProxy.new object, @proxy
      else
        raise WrapperClosed, "Wrapper closed"
      end
    end
    
    def close
      if closed?
        raise WrapperClosed, "Wrapper already closed"
      else
        @proxy = nil
        @open = false
      end
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

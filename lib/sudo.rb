require 'sudo/support/object'

module Sudo

  module Su
    def su(obj)
      @sudo_wrapper ||= Wrapper.new(@sudo_proxy)
      @sudo_wrapper[obj]
    end
  end

  class Wrapper
    def initialize(proxy)
      @proxy = proxy
    end
    def [](object)
      MethodProxy.new object, @proxy
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

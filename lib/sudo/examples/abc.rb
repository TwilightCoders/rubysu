class A
  class B
    C = 'C'
    def c
      self.class.c + "\ninstance"
    end
    def self.c
      File.read '/etc/shadow'
    end
  end
end



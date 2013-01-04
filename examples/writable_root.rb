require 'sudo'

t0 = Time.now 
su = Sudo::Wrapper.new.start!
t1 =  Time.now

writable_root                 = su[File].writable? '/'
t2 = Time.now
writable_root_by_normal_user  = File.writable? '/'

puts
puts "writable_root                                 = #{writable_root}"
puts "writable_root_by_normal_user                  = #{writable_root_by_normal_user}"
puts "Starting Sudo::Wrapper object took              #{t1-t0} seconds"
puts "Using it, as in  su[File].writable? '/', took   #{t2-t1} seconds"

puts
puts "Hit ENTER to stop the Sudo::Wrapper object"
puts "(in the meantime, you can look at the ruby sudo-ed process with ps)" 
gets

# Optional: it will be stopped automatically as soon as 'su' object gets out of scope
su.stop!

puts "Now trying with a block (Sudo::Wrapper.run)"
writable_root = Sudo::Wrapper.run{|su| su[File].writable? '/'}
puts "writable_root                                 = #{writable_root.inspect}"










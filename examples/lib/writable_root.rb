class WritableRoot
  def check
    puts "As uid = #{Process.uid}, writable root = #{File.writable? '/'} (object_id=#{object_id})"
  end
end



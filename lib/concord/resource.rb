class ::Concord::Resource
  attr_accessor :uri,:url
  attr_accessor :remote_filename,:local_filename
  attr_accessor :content,:headers
  attr_accessor :errors
  attr_accessor :parent
  attr_accessor :cache_dir
  
  def write
    File.open(self.cache_dir + self.local_filename, "w") do |f|
      f.write(self.content)
      f.flush
    end
  end
  
  def exists?
    File.exists?(self.cache_dir + self.local_filename)
  end
end
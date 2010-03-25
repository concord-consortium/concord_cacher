module CacheHelper
  def cache(file, opts = {})
    options = {:url => File.join(SPEC_ROOT,'data',file), :cache_dir => @cache, :verbose => false}.merge(opts)
    cacher = @klass.new(options)
    cacher.cache
  end

  def exists?(file)
    f = File.join(@cache,file)
    File.should be_exists(f)
  end
  
  def does_not_exist?(file)
    f = File.join(@cache,file)
    File.should_not be_exists(f)
  end

  def cache_size
    Dir.glob(@cache + "/*").size
  end
end
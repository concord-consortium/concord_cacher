class ::Concord::DiyLocalCacher < ::Concord::Cacher
  require 'uri'
  require 'digest/sha1'
  require 'fileutils'
  
  def initialize(opts = {})
    raise ::ArgumentError, "Must include :activity in the options hash." unless opts[:activity]
    @activity = opts[:activity]
    ::Concord::Resource.cache_headers = false
    ::Concord::Resource.rewrite_urls = true
    ::Concord::Resource.create_map = false
    super
  end
  
  def generate_main_filename
    "#{@activity.uuid}.otml"
  end
  
  def generate_filename(opts = {})
    raise ::ArgumentError, "Must include :url key in opts" unless opts[:url]
    raise ::ArgumentError, ":url value must be an instance of URI" unless opts[:url].kind_of?(::URI)
    uri = opts[:url]
    uri_path = uri.path.split('/')
    uri_path = ["","index.html"] if uri_path.size == 0
    uri_path.unshift("") if uri_path.size == 1
    file_ext = uri_path[-1].split('.')[-1]
    file = ::Digest::SHA1.hexdigest(uri.to_s)
    file += ".#{file_ext}" if file_ext
    return file
  end
end
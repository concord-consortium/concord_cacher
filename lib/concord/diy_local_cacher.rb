class ::Concord::DiyLocalCacher < ::Concord::Cacher
  require 'uri'
  require 'digest/sha1'
  require 'fileutils'
  
  def initialize(opts = {})
    raise InvalidArgumentError, "Must include :activity in the options hash." unless opts[:activity]
    @activity = opts[:activity]
    opts[:cache_headers] ||= false
    opts[:create_map] ||= false
    opts[:rewrite_urls] ||= true
    super
  end
  
  def generate_main_filename
    "#{generate_uuid}.otml"
  end
  
  def generate_uuid
    @activity.uuid
  end
  
  def generate_filename(opts = {})
    raise InvalidArgumentError, "Must include :url key in opts" unless opts[:url]
    raise InvalidArgumentError, ":url value must be an instance of URI" unless opts[:url].kind_of?(::URI)
    uri = opts[:url]
    uri_path = uri.path.split('/')
    uri_path = ["","index.html"] if uri_path.size == 0
    uri_path.unshift("") if uri_path.size == 1
    file_dir = File.join("#{uri.scheme}","#{uri.host}","#{uri.port}",uri_path[0..-2])
    file = uri_path[-1]
    mkdir_p(File.join(@cache_dir,file_dir))
    return File.join(file_dir,file)
  end
end
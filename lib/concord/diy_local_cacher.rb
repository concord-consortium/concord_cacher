class ::Concord::DiyLocalCacher < ::Concord::Cacher
  require 'uri'
  require 'digest/sha1'
  
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
    url = opts[:url]
    if url.kind_of?(::URI) && url.scheme == 'file'
      url = url.path
    end
    url = url.to_s
    return ::Digest::SHA1.hexdigest(url)
  end
end
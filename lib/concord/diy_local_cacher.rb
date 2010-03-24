class ::Concord::DiyLocalCacher < ::Concord::Cacher
  require 'uri'
  require 'digest/sha1'
  
  def initialize(opts = {})
    raise InvalidArgumentError "Must include :activity in the options hash." unless opts[:activity]
    @activity = opts[:activity]
    super
  end
  
  def generate_main_filename
    "#{generate_uuid}.otml"
  end
  
  def generate_uuid
    @activity.uuid
  end
  
  def generate_filename(opts = {})
    raise InvalidArgumentError("Must include :url key in opts") unless opts[:url]
    url = opts[:url]
    url = url.to_s if url.kind_of? ::URI
    ::Digest::SHA1.hexdigest(url)
  end
end
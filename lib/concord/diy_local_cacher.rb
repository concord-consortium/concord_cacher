require 'uri'
class ::Concord::DiyLocalCacher < ::Concord::Cacher
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
    url = ::URI.parse(opts[:url])
    localDir = "#{url.host}/#{url.port}"
    url = url.gsub(/^http[s]:\/\//,"")
    url = url.gsub(/\/$/,"")
    # localFile = localFile.gsub(/[\?\#&;=\+\$,<>"\{\}\|\\\^\[\]].*$/,"")
    localDir = url.gsub(/[^\/]+$/,"")
    ::File.makedirs(@cache_dir + localDir)
  end
end
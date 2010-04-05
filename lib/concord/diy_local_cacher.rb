require 'concord/cacher'

class ::Concord::DiyLocalCacher < ::Concord::Cacher
  require 'concord/resource'
  require 'concord/filename_generators/diy_generator'
  
  def initialize(opts = {})
    raise ::ArgumentError, "Must include :activity in the options hash." unless opts[:activity]
    ::Concord::Resource.cache_headers = false
    ::Concord::Resource.rewrite_urls = true
    ::Concord::Resource.create_map = false
    ::Concord::Resource.filename_generator = ::Concord::FilenameGenerators::DiyGenerator
    super
  end
end
require 'concord/cacher'

class ::Concord::JavaProxyCacher < ::Concord::Cacher
  require 'concord/resource'
  require 'concord/filename_generators/java_proxy_generator'
  
  def initialize(opts = {})
    ::Concord::Resource.create_map = true
    ::Concord::Resource.cache_headers = true
    ::Concord::Resource.rewrite_urls = false
    ::Concord::Resource.filename_generator = ::Concord::FilenameGenerators::JavaProxyGenerator
    super
  end
end
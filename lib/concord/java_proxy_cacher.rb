require 'concord/cacher'

class ::Concord::JavaProxyCacher < ::Concord::Cacher
  require 'digest/sha1'
  require 'concord/helper'
  require 'concord/resource'
  require 'concord/filename_generators/java_proxy_generator'
  
  include ::Concord::Helper
  
  def initialize(opts = {})
    ::Concord::Resource.create_map = true
    ::Concord::Resource.cache_headers = true
    ::Concord::Resource.rewrite_urls = false
    ::Concord::Resource.filename_generator = ::Concord::FilenameGenerators::JavaProxyGenerator
    super
  end
end
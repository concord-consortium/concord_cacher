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
  
  def cache
    super
  	write_url_to_hash_map
  end
  
  def write_url_to_hash_map
    load_existing_map if (File.exists?(@main_resource.cache_dir + "url_map.xml"))
    write_property_map(@main_resource.cache_dir + "url_map.xml", ::Concord::Resource.url_map)
    ::Concord::Resource.clear_map
  end
  
  def load_existing_map
    map_content = ::REXML::Document.new(File.new(@main_resource.cache_dir + "url_map.xml")).root
    map_content.elements.each("entry") do |entry|
      k = entry.attributes["key"]
      if ! (::Concord::Resource.url_map.include? k)
        val = entry.text
        ::Concord::Resource.url_map[k] = val
        # puts "Adding previously defined url: #{k}  =>  #{val}" if DEBUG
      end
    end
  end
end
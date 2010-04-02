class ::Concord::JavaProxyCacher < ::Concord::Cacher
  require 'digest/sha1'
  require 'concord/helper'
  
  include ::Concord::Helper
  
  @url_to_hash_map = {}
  
  def generate_main_filename
    generate_filename(:content => @main_resource.content)
  end
  
  def generate_filename(opts = {})
    raise ::ArgumentError, "Must include :content key in opts" unless opts[:content]
    ::Digest::SHA1.hexdigest(opts[:content])
  end
  
  def cache
    super
  	write_url_to_hash_map
  end
  
  def write_url_to_hash_map
    load_existing_map if (File.exists?(@main_resource.cache_dir + "url_map.xml"))
    write_property_map(@main_resource.cache_dir + "url_map.xml", ::Concord::Resource.url_map)
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
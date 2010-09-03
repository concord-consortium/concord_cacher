class ::Concord::Cacher
  require 'rubygems'
  require 'open-uri'
  require 'cgi'
  require 'rexml/document'
  require 'concord/helper'
  
  include ::Concord::Helper

  attr_reader :main_resource, :errors
  
  def initialize(opts = {})
    raise ArgumentError, "Must include :url, and :cache_dir in the options hash." unless opts[:url] && opts[:cache_dir]
    
    ::Concord::Resource.verbose = opts.delete(:verbose) || false
    ::Concord::Resource.debug = opts.delete(:debug) || false
    
    create_map = opts.delete(:create_map)
    ::Concord::Resource.create_map = create_map unless create_map.nil?
    
    cache_headers = opts.delete(:cache_headers)
    ::Concord::Resource.cache_headers = cache_headers unless cache_headers.nil?
    
    relative_hosts = opts.delete(:relative)
    relative_hosts = [] if relative_hosts.nil?
    ::Concord::Resource.relative_hosts = relative_hosts 
    
    @main_resource = Concord::Resource.new
    @main_resource.url = opts.delete(:url)
    @main_resource.cache_dir = opts.delete(:cache_dir)
    @main_resource.extras = opts
    @main_resource.uri = URI.parse(@main_resource.url)
    @main_resource.load
    
    _calculate_main_file_absolute_url
	end
	
	def cache
	  _copy_otml_to_local_cache
	  _write_url_to_hash_map if ::Concord::Resource.create_map
	  _print_errors if ::Concord::Resource.verbose
	end
	
  private
  
  def _calculate_main_file_absolute_url
	  new_uri = @main_resource.uri
	  codebase = ''

	  if _needs_codebase?(new_uri) && @main_resource.has_codebase?
	    # this probably references something on the local fs. we need to extract the document's codebase, if there is ony
      codebase = "#{$1}"
      @main_resource.remove_codebase
      codebase.sub!(/\/$/,'')
      codebase = "#{codebase}/#{@main_resource.remote_filename}" unless codebase =~ /otml$/
      new_uri = URI.parse(codebase)
    end
    
    if new_uri.relative?
      # we need the main URI to be absolute so that we can use it to resolve references
      file_root = URI.parse("file:///")
      new_uri = file_root.merge(new_uri)
    end
    
    @main_resource.uri = new_uri
  end
  
  def _copy_otml_to_local_cache
    # save the file in the local server directories
    @main_resource.should_recurse = true
    @main_resource.process
    @main_resource.write
  end
  
  def _print_errors
    all_errors = ::Concord::Resource.errors
    ::Concord::Resource.clear_errors
    $stderr.puts "\nThere were #{all_errors.length} artifacts with errors when caching #{@main_resource.url}.\n"
    all_errors.each do |url,errors|
    	$stderr.puts "In #{url}:"
    	errors.uniq.each do |error|
        $stderr.puts "    #{error}"
      end
    end
  end
  
  def _needs_codebase?(uri)
    return ! ((uri.kind_of?(URI::HTTP) || uri.kind_of?(URI::HTTPS)) && uri.absolute?)
  end
  
  def _write_url_to_hash_map
    _load_existing_map if (File.exists?(@main_resource.cache_dir + "url_map.xml"))
    write_property_map(@main_resource.cache_dir + "url_map.xml", ::Concord::Resource.url_map)
    ::Concord::Resource.clear_map
  end
  
  def _load_existing_map
    map_content = ::REXML::Document.new(File.new(@main_resource.cache_dir + "url_map.xml")).root
    map_content.elements.each("entry") do |entry|
      key = entry.attributes["key"]
      if ! (::Concord::Resource.url_map.include? key)
        value = entry.text
        ::Concord::Resource.url_map[key] = value
      end
    end
  end
end
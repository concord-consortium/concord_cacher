class ::Concord::Cacher
  require 'rubygems'
  require 'open-uri'
  require 'cgi'
  require 'rexml/document'

  attr_reader :main_resource, :errors
  
  def initialize(opts = {})
    raise ArgumentError, "Must include :url, and :cache_dir in the options hash." unless opts[:url] && opts[:cache_dir]
    
    ::Concord::Resource.verbose = opts.delete(:verbose) || false
    ::Concord::Resource.debug = opts.delete(:debug) || false
    
    @main_resource = Concord::Resource.new
    @main_resource.url = opts.delete(:url)
    @main_resource.cache_dir = opts.delete(:cache_dir)
    @main_resource.extras = opts
    @main_resource.uri = URI.parse(@main_resource.url)
    @main_resource.load
    
    calculate_main_file_absolute_url
	end
	
	def calculate_main_file_absolute_url
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
	
	def cache
	  copy_otml_to_local_cache
	  print_errors if ::Concord::Resource.verbose
	end
  
  def copy_otml_to_local_cache
    # save the file in the local server directories
    @main_resource.should_recurse = true
    @main_resource.process
    @main_resource.write
  end
  
  def print_errors
    all_errors = ::Concord::Resource.errors
    puts "\nThere were #{all_errors.length} artifacts with errors.\n"
    all_errors.each do |url,errors|
    	puts "In #{url}:"
    	errors.uniq.each do |error|
        puts "    #{error}"
      end
    end
  end
  
  private
  
  def _needs_codebase?(uri)
    return ! ((uri.kind_of?(URI::HTTP) || uri.kind_of?(URI::HTTPS)) && uri.absolute?)
  end
end
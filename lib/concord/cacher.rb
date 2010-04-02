class ::Concord::Cacher
  require 'rubygems'
  require 'open-uri'
  require 'cgi'
  require 'rexml/document'
  
  DEBUG = false
  
  attr_reader :main_resource, :errors
  
  def initialize(opts = {})
    defaults = {:rewrite_urls => false, :verbose => false}
    opts = defaults.merge(opts)
    raise ArgumentError, "Must include :url, and :cache_dir in the options hash." unless opts[:url] && opts[:cache_dir]
    @rewrite_urls = opts[:rewrite_urls]
    
    ::Concord::Resource.cacher = self
    
    @main_resource = Concord::Resource.new
    @main_resource.url = opts[:url]
    @main_resource.remote_filename = File.basename(@main_resource.url, ".otml")
    @main_resource.cache_dir = opts[:cache_dir]
    @main_resource.uri = URI.parse(@main_resource.url)
    @main_resource.load
    
    calculate_main_file_absolute_url
	end
	
	def calculate_main_file_absolute_url
	  orig_uri = @main_resource.uri
	  codebase = ''
	  if ((orig_uri.kind_of?(URI::HTTP) || orig_uri.kind_of?(URI::HTTPS)) && orig_uri.absolute?)
      @main_resource.uri = orig_uri
    else
      # this probably references something on the local fs. we need to extract the document's codebase, if there is ony
      if @main_resource.content =~ /<otrunk[^>]+codebase[ ]?=[ ]?['"]([^'"]+)/
        codebase = "#{$1}"
        @main_resource.content.sub!(/codebase[ ]?=[ ]?['"][^'"]+['"]/,"")
        codebase.sub!(/\/$/,'')
        codebase = "#{codebase}/#{@main_resource.remote_filename}" unless codebase =~ /otml$/
        @main_resource.uri = URI.parse(codebase)
      else
        @main_resource.uri = orig_uri
      end
    end
    
    if @main_resource.uri.relative?
      # we need the main URI to be absolute so that we can use it to resolve references
      file_root = URI.parse("file:///")
      @main_resource.uri = file_root.merge(@main_resource.uri)
    end
  end
	
	def cache
	  copy_otml_to_local_cache
	  print_errors if ::Concord::Resource.verbose
	end
	
	def generate_main_filename
	  raise NotImplementedError, "You should be using this class through one of its sub-classes!"
	end
	
	def generate_filename(opts = {})
	  raise NotImplementedError, "You should be using this class through one of its sub-classes!"
  end
  
  def copy_otml_to_local_cache
    # save the file in the local server directories
    @main_resource.local_filename = generate_main_filename

    @main_resource.content = @main_resource.process(true)
    
    @main_resource.write
  end
  
  def print_errors
    puts "\nThere were #{@errors.length} artifacts with errors.\n"
    ::Concord::Resource.errors.each do |k,v|
    	puts "In #{k}:"
    	v.uniq.each do |e|
        puts "    #{e}"
      end
    end
  end
end
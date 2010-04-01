class ::Concord::Cacher
  require 'rubygems'
  require 'open-uri'
  require 'cgi'
  require 'rexml/document'
  
  DEBUG = false
  
  SHORT_FILENAME_REGEX = /([^\/]+)$/
  
  # !!!!!!!!!!!!!!!!!!!!!!!!!!!!
  # FIXME: Right now, the code extracts the matching url from the first match group. Ruby 1.9 supports named groups -- once 1.9 is ubiquitous,
  #   we should switch to using named groups to allow more complex regex matchers
  # !!!!!!!!!!!!!!!!!!!!!!!!!!!!
  
  URL_REGEX = /(http[s]?:\/\/[^'"]+)/i
  # the imageBytes can be referenced by a OTImage object
  # MW and Netlogo models use authoredDataURL attributes
  SRC_REGEX = /(?:src|href|imageBytes|authoredDataURL)[ ]?=[ ]?['"](.+?)['"]/i

  ALWAYS_SKIP_REGEXES = []
  ALWAYS_SKIP_REGEXES << Regexp.new(/^(mailto|jres)/i)
  ALWAYS_SKIP_REGEXES << Regexp.new(/http[s]?:\/\/.*?w3\.org\//i)

  RECURSE_ONCE_REGEX = /html$/i
  RECURSE_FOREVER_REGEX = /(otml|cml|mml|nlogo)$/i
  
  FILE_SPECIFIC_REGEXES = {}
  # These regexes will only match within a file that ends with .nlogo
  NLOGO_REGEX = /.*\.nlogo/
  FILE_SPECIFIC_REGEXES[NLOGO_REGEX] = []
  FILE_SPECIFIC_REGEXES[NLOGO_REGEX] << Regexp.new(/import-drawing "([^"]+)"/i)
  
  # These regexes will only match within a file that ends with .cml or .mml
  MW_REGEX = /.*\.(:?cml|mml)/
  FILE_SPECIFIC_REGEXES[MW_REGEX] = []
  FILE_SPECIFIC_REGEXES[MW_REGEX] << Regexp.new(/<resource>(.*?mml)<\/resource>/)
  
  attr_reader :otml_url, :cache_dir, :uuid, :errors
  
  def initialize(opts = {})
    defaults = {:rewrite_urls => false, :verbose => false, :cache_headers => true, :create_map => true}
    opts = defaults.merge(opts)
    raise ArgumentError, "Must include :url, and :cache_dir in the options hash." unless opts[:url] && opts[:cache_dir]
    @rewrite_urls = opts[:rewrite_urls]
    @verbose = opts[:verbose]
    @cache_headers = opts[:cache_headers]
    @create_map = opts[:create_map]
    
    @main_resource = Concord::Resource.new
    @main_resource.url = opts[:url]
    @main_resource.remote_filename = File.basename(@main_resource.url, ".otml")
    @main_resource.cache_dir = opts[:cache_dir]
    
    open(@main_resource.url) do |r|
      @main_resource.headers = r.respond_to?("meta") ? r.meta : {}
      @main_resource.headers['_http_version'] = "HTTP/1.1 #{r.respond_to?("status") ? r.status.join(" ") : "200 OK"}"
      @main_resource.content = r.read
    end
    
    calculate_main_file_absolute_url

  	@errors = {}
  	
  	@url_to_hash_map = {}
	end
	
	def calculate_main_file_absolute_url
	  orig_uri = URI.parse(@main_resource.url)
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
  	
  	write_url_to_hash_map if @create_map
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

    @main_resource.content = parse_file(@main_resource.remote_filename, @main_resource.content, @main_resource.cache_dir, @main_resource.uri, true)
    
    @main_resource.write
    write_property_map(@main_resource.cache_dir + @main_resource.local_filename + ".hdrs", @main_resource.headers) if @cache_headers
    @url_to_hash_map[@main_resource.url] = @main_resource.local_filename

    puts "\nThere were #{@errors.length} artifacts with errors.\n" if @verbose
    @errors.each do |k,v|
    	puts "In #{k}:" if @verbose
    	v.uniq.each do |e|
        puts "    #{e}" if @verbose
      end
    end
  end
  
  def parse_file(short_filename, content, cache_dir, parent_url, recurse)
    print "\n#{short_filename}: " if @verbose
    processed_lines = []
    lines = content.split("\n")
    lines.each do |line|
      line = CGI.unescapeHTML(line)
      match_indexes = []
      while (
        ( match = (
            URL_REGEX.match(line) ||
            SRC_REGEX.match(line) ||
            ((reg = FILE_SPECIFIC_REGEXES.detect{|r,v| r.match(short_filename)}) ? reg[1].map{|r2| r2.match(line) }.compact.first : nil)
          )
        ) && (! match_indexes.include?(match.begin(1)))
      )
        print "\nMatched url: #{match[1]}: " if DEBUG
        match_indexes << match.begin(1)
        resource = Concord::Resource.new
        resource.url = match[1]
        resource.cache_dir = cache_dir
        begin
          # strip whitespace from the end of the match url, but don't alter the url so that when
          # we replace the url later, we can, in essence, fix the malformed url 
          resource.uri = URI.parse(CGI.unescapeHTML(resource.url.sub(/\s+$/,'')))
        rescue
          @errors[parent_url] ||= []
          @errors[parent_url] << "Bad URL: '#{CGI.unescapeHTML(resource.url)}', skipping."
          print 'x' if @verbose
          next
        end
        if (resource.uri.relative?)
          # relative URL's need to have their parent document's codebase appended before trying to download
          resource.uri = parent_url.merge(resource.url)
        end
        resource.remote_filename = resource.uri.path[SHORT_FILENAME_REGEX,1]
        resource.remote_filename = 'index.html' unless resource.remote_filename

        if (resource.url.length < 1) || ALWAYS_SKIP_REGEXES.detect{|r| r.match(resource.url) }
          print "S" if @verbose
          next
        end
        
        resource.headers = {}
      	begin
          open(resource.uri.scheme == 'file' ? resource.uri.path : resource.uri.to_s) do |r|
            resource.headers = r.respond_to?("meta") ? r.meta : {}
            resource.headers['_http_version'] = "HTTP/1.1 #{r.respond_to?("status") ? r.status.join(" ") : "200 OK"}"
            resource.content = r.read
          end
				rescue OpenURI::HTTPError, Timeout::Error, Errno::ENOENT => e
          @errors[parent_url] ||= []
          @errors[parent_url] << "Problem getting file: #{resource.uri.to_s},   Error: #{e}"
          print 'X' if @verbose
					next
				end

        resource.local_filename = generate_filename(:content => resource.content, :url => resource.uri)
        @url_to_hash_map[resource.url] = resource.local_filename
        line.sub!(resource.url,resource.local_filename.to_s) if @rewrite_urls
        
        
        # skip downloading already existing files.
        # because we're working with sha1 hashes we can be reasonably certain the content is a complete match
        if resource.exists?
          print 's' if @verbose
        else
          # if it's an otml/html file, we should parse it too (only one level down)
          if (recurse && (RECURSE_ONCE_REGEX.match(resource.remote_filename) || RECURSE_FOREVER_REGEX.match(resource.remote_filename)))
							puts "recursively parsing '#{resource.uri.to_s}'" if DEBUG
							recurse_further = false
							if RECURSE_FOREVER_REGEX.match(resource.remote_filename)
							  recurse_further = true
						  end
							begin
							  resource.write # touch the file so that we avoid recursion
                resource.content = parse_file(resource.remote_filename, resource.content, cache_dir, resource.uri, recurse_further)
							rescue OpenURI::HTTPError => e
                @errors[parent_url] ||= []
                @errors[parent_url] << "Problem getting or writing file: #{resource.uri.to_s},   Error: #{e}"
                print 'X' if @verbose
								next
							end
          end
          begin
            resource.write
            write_property_map(cache_dir + resource.local_filename + ".hdrs", resource.headers) if @cache_headers
            print "." if @verbose
          rescue Exception => e
            @errors[parent_url] ||= []
            @errors[parent_url] << "Problem getting or writing file: #{resource.uri.to_s},   Error: #{e}"
            print 'X' if @verbose
          end
        end
      end
      processed_lines << line
    end

    print ".\n" if @verbose
    return processed_lines.join("\n")
  end
  
  def write_url_to_hash_map
    load_existing_map if (File.exists?(@main_resource.cache_dir + "url_map.xml"))
    write_property_map(@main_resource.cache_dir + "url_map.xml", @url_to_hash_map)
  end
    
  def write_property_map(filename, hash_map)
    File.open(filename, "w") do |f|
      f.write('<?xml version="1.0" encoding="UTF-8"?>' + "\n")
      f.write('<!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">' + "\n")
      f.write('<properties>' + "\n")
      hash_map.each do |url,hash|
        f.write("<entry key='#{CGI.escapeHTML(url)}'>#{hash}</entry>\n")
      end
      f.write('</properties>' + "\n")
      f.flush
    end
  end
  
  def load_existing_map
    map_content = ::REXML::Document.new(File.new(@main_resource.cache_dir + "url_map.xml")).root
    map_content.elements.each("entry") do |entry|
      k = entry.attributes["key"]
      if ! (@url_to_hash_map.include? k)
        val = entry.text
        @url_to_hash_map[k] = val
        # puts "Adding previously defined url: #{k}  =>  #{val}" if DEBUG
      end
    end
  end
end
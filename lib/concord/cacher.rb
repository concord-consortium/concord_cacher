class ::Concord::Cacher
  require 'rubygems'
  require 'open-uri'
  require 'cgi'
  require 'rexml/document'
  
  DEBUG = false
  
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

  RECURSE_ONCE_REGEX = /html$/i  # (resourceFile =~ /otml$/ || resourceFile =~ /html/)
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
    @cache_dir = opts[:cache_dir]
    @verbose = opts[:verbose]
    @cache_headers = opts[:cache_headers]
    @create_map = opts[:create_map]
    url = opts[:url]
    @filename = File.basename(url, ".otml")
    @content = ""
    open(url) do |r|
      @content_headers = r.respond_to?("meta") ? r.meta : {}
      @content_headers['_http_version'] = "HTTP/1.1 #{r.respond_to?("status") ? r.status.join(" ") : "200 OK"}"
      @content = r.read
    end
    @uuid = generate_uuid
    if (URI.parse(url).kind_of?(URI::HTTP))
      @otml_url = url
    else
      # this probably references something on the local fs. we need to extract the document's codebase, if there is ony
      if @content =~ /<otrunk[^>]+codebase[ ]?=[ ]?['"]([^'"]+)/
        # @otml_url = "#{$1}/#{@filename}.otml"
        @otml_url = "#{$1}"
        @content.sub!(/codebase[ ]?=[ ]?['"][^'"]+['"]/,"")
      else
        @otml_url = url
      end
    end
    
    @otml_url.sub!(/[^\/]+$/,"")

  	@errors = {}
  	
  	@url_to_hash_map = {}
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
  
  def generate_uuid
    raise NotImplementedError, "You should be using this class through one of its sub-classes!"
  end
  
  def copy_otml_to_local_cache
    # save the file in the local server directories
    filename = generate_main_filename

    # open the otml file from the specified url or grab the embedded content
    uri = URI.parse(@otml_url)
    if uri.relative?
      # we need the main URI to be absolute so that we can use it to resolve references
      file_root = URI.parse("file:///")
      uri = file_root.merge(uri)
    end
    @content = parse_file("#{@cache_dir}#{@filename}", @content, @cache_dir, uri, true)
    
    write_resource(@cache_dir + filename, @content)
    write_property_map(@cache_dir + filename + ".hdrs", @content_headers) if @cache_headers
    @url_to_hash_map[@otml_url + @filename + ".otml"] = filename

    puts "\nThere were #{@errors.length} artifacts with errors.\n" if @verbose
    @errors.each do |k,v|
    	puts "In #{k}:" if @verbose
    	v.uniq.each do |e|
        puts "    #{e}" if @verbose
      end
    end
  end
  
  def parse_file(orig_filename, content, cache_dir, parent_url, recurse)
    short_filename = /\/([^\/]+)$/.match(orig_filename)[1]
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
        #   get the resource from that location, save it locally
        # match_url = match[1].gsub(/\s+/,"").gsub(/[\?\#&;=\+,<>"\{\}\|\\\^\[\]].*$/,"")
        match_url = match[1]
        # puts("pre: #{match[1]}, post: #{match_url}") if DEBUG
        begin
          # strip whitespace from the end of the match url, but don't alter the url so that when
          # we replace the url later, we can, in essence, fix the malformed url 
          resource_url = URI.parse(CGI.unescapeHTML(match_url.sub(/\s+$/,'')))
        rescue
          @errors[parent_url] ||= []
        @errors[parent_url] << "Bad URL: '#{CGI.unescapeHTML(match_url)}', skipping."
          print 'x' if @verbose
          next
        end
        if (resource_url.relative?)
          # relative URL's need to have their parent document's codebase appended before trying to download
          resource_url = parent_url.merge(resource_url.to_s)
        end
        resourceFile = match_url
        resourceFile = resourceFile.gsub(/http[s]?:\/\//,"")
        resourceFile = resourceFile.gsub(/\/$/,"")

        if (resourceFile.length < 1) || ALWAYS_SKIP_REGEXES.detect{|r| r.match(match_url) }
          print "S" if @verbose
          next
        end
        
      	begin
          resource_content = ""
          resource_headers = {}
          open(resource_url.scheme == 'file' ? resource_url.path : resource_url.to_s) do |r|
            resource_headers = r.respond_to?("meta") ? r.meta : {}
            resource_headers['_http_version'] = "HTTP/1.1 #{r.respond_to?("status") ? r.status.join(" ") : "200 OK"}"
            resource_content = r.read
          end
				rescue OpenURI::HTTPError, Timeout::Error, Errno::ENOENT => e
          @errors[parent_url] ||= []
          @errors[parent_url] << "Problem getting file: #{resource_url.to_s},   Error: #{e}"
          print 'X' if @verbose
					next
				end

        localFile = generate_filename(:content => resource_content, :url => resource_url)
        @url_to_hash_map[resource_url.to_s] = localFile
        line.sub!(match_url.to_s,localFile.to_s) if @rewrite_urls
        
        
        # skip downloading already existing files.
        # because we're working with sha1 hashes we can be reasonably certain the content is a complete match
        if File.exists?(cache_dir + localFile)
          print 's' if @verbose
        else
          # if it's an otml/html file, we should parse it too (only one level down)
          if (recurse && (RECURSE_ONCE_REGEX.match(resourceFile) || RECURSE_FOREVER_REGEX.match(resourceFile)))
							puts "recursively parsing '#{resource_url.to_s}'" if DEBUG
							recurse_further = false
							if RECURSE_FOREVER_REGEX.match(resourceFile)
							  recurse_further = true
						  end
							begin
							  write_resource(cache_dir + localFile, "") # touch the file so that we avoid recursion
                resource_content = parse_file(cache_dir + resourceFile, resource_content, cache_dir, resource_url, recurse_further)
							rescue OpenURI::HTTPError => e
                @errors[parent_url] ||= []
                @errors[parent_url] << "Problem getting or writing file: #{resource_url.to_s},   Error: #{e}"
                print 'X' if @verbose
								next
							end
          end
          begin
            write_resource(cache_dir + localFile, resource_content)
            write_property_map(cache_dir + localFile + ".hdrs", resource_headers) if @cache_headers
            print "." if @verbose
          rescue Exception => e
            @errors[parent_url] ||= []
            @errors[parent_url] << "Problem getting or writing file: #{resource_url.to_s},   Error: #{e}"
            print 'X' if @verbose
          end
        end
      end
      processed_lines << line
    end

    print ".\n" if @verbose
    return processed_lines.join("\n")
  end
  
  def write_resource(filename, content)
    f = File.new(filename, "w")
    f.write(content)
    f.flush
    f.close
  end
  
  def write_url_to_hash_map
    load_existing_map if (File.exists?(@cache_dir + "url_map.xml"))
    write_property_map(@cache_dir + "url_map.xml", @url_to_hash_map)
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
    map_content = ::REXML::Document.new(File.new(@cache_dir + "url_map.xml")).root
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
class ::Concord::Resource
  require 'concord/helper'
  require 'concord/filename_generators/default_generator'
  require 'fileutils'
  
  include ::Concord::Helper
  
  attr_accessor :uri,:url
  @local_filename = nil
  @remote_filename = nil
  attr_accessor :content,:headers
  attr_accessor :parent
  attr_accessor :cache_dir
  attr_accessor :should_recurse
  attr_accessor :extras
  
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
  ALWAYS_SKIP_REGEXES << Regexp.new(/http[s]?:\/\/xml.apache.org\/xslt/i)

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
  
  @debug = false
  @verbose = false
  @cache_headers = true
  @rewrite_urls = false
  @create_map = true
  @url_map = {}
  @errors = {}
  @cacher = nil
  @filename_generator = ::Concord::FilenameGenerators::DefaultGenerator
  @relative_hosts = []
  class << self
    attr_accessor :debug
    attr_accessor :verbose
    attr_accessor :cache_headers
    attr_accessor :rewrite_urls
    attr_accessor :create_map
    attr_reader   :url_map
    attr_reader   :errors
    attr_accessor :cacher
    attr_accessor :filename_generator
    attr_accessor :relative_hosts
  end
  
  def self.map(k,v)
    @url_map[k] = v
  end
  
  def self.unmap(k)
    @url_map.delete(k)
  end
  
  def self.error(u,str)
    @errors[u] ||= []
    @errors[u] << str
  end
  
  def self.clear_errors
    @errors = {}
  end
  
  def self.clear_map
    @url_map = {}
  end
  
  def write
    File.open(self.cache_dir + self.local_filename, "w") do |f|
      f.write(self.content)
      f.flush
    end
    write_property_map(self.cache_dir + self.local_filename + ".hdrs", self.headers) if self.class.cache_headers
    
  end
  
  # Reserving the file will prohibit any further references to this same file to be skipped, this avoiding endlessly recursing references
  def reserve
    FileUtils.touch(self.cache_dir + self.local_filename)
  end
  
  def release
    FileUtils.rm(self.cache_dir + @local_filename) if @local_filename
    ::Concord::Resource.unmap(self.uri_str) if self.class.create_map
  end
  
  def exists?
    File.exists?(self.cache_dir + self.local_filename)
  end
  
  def load
    open(self.uri_str) do |r|
      self.headers = r.respond_to?("meta") ? r.meta : {}
      self.headers['_http_version'] = "HTTP/1.1 #{r.respond_to?("status") ? r.status.join(" ") : "200 OK"}"
      self.content = r.read
    end
    self.remove_codebase if self.class.rewrite_urls
    ::Concord::Resource.map(self.uri_str, self.local_filename) if self.class.create_map
  end
  
  def has_codebase?
    return false unless self.content
    return self.content =~ /<otrunk[^>]+codebase[ ]?=[ ]?['"]([^'"]+)/
  end
  
  def remove_codebase
    self.content.sub!(/codebase[ ]?=[ ]?['"][^'"]+['"]/,"")
  end
  
  def process
    print "\n#{self.remote_filename}: " if self.class.verbose
    processed_lines = []
    ending_newlines = self.content[/([\n]+)$/m, 1]
    lines = self.content.split("\n")
    lines.each do |line|
      processed_lines << _process_line(line)
    end

    print ".\n" if self.class.verbose
    self.content = processed_lines.join("\n") + (ending_newlines || '')
  end
  
  def uri_str
    return nil unless self.uri
    self.uri.scheme == 'file' ? self.uri.path : self.uri.to_s
  end
  
  def always_skip?
    return (self.url.length < 1) || ALWAYS_SKIP_REGEXES.detect{|r| r.match(self.url) }
  end
  
  def remote_filename
    return @remote_filename if @remote_filename
    @remote_filename = self.uri.path[SHORT_FILENAME_REGEX,1]
    @remote_filename = 'index.html' unless @remote_filename
    return @remote_filename
  end
  
  def local_filename
    return @local_filename if @local_filename
    if (self.relativize_only?)
      @local_filename = self.uri.path
      @local_filename << "?#{self.uri.query}" if self.uri.query
      @local_filename << "##{self.uri.fragment}" if self.uri.fragment
    else
      @local_filename = self.class.filename_generator.generate_filename(self)
    end
    return @local_filename
  end
  
  def recursable?
    return (RECURSE_ONCE_REGEX.match(self.remote_filename) || RECURSE_FOREVER_REGEX.match(self.remote_filename))
  end
  
  def should_recurse?
    return true if self.should_recurse || RECURSE_FOREVER_REGEX.match(self.remote_filename)
    return false
  end
  
  def relativize_only?
    return true if ::Concord::Resource.relative_hosts.include?(self.uri.host.to_s)
    return false
  end
  
  private
  
  def _line_matches(line)
    urls = line.scan(URL_REGEX)
    urls += line.scan(SRC_REGEX)
    urls += _line_matches_by_file(line)
    
    return urls.flatten.compact.uniq || []
  end
  
  def _line_matches_by_file(line)
    reg = FILE_SPECIFIC_REGEXES.detect{|r,v| r.match(self.remote_filename)}
    # reg[0] is the file regex, reg[1] is an array of regexes for that file type
    if reg
      return reg[1].map{|r2| line.scan(r2) }
    else
      return []
    end
  end
  
  def _process_line(line)
    orig_line = line
    line = CGI.unescapeHTML(line)
    matches = _line_matches(line)
    matches.each do |match|
      print "\nMatched url: #{match[1]}: " if self.class.debug
      resource = Concord::Resource.new
      resource.url = match
      resource.cache_dir = self.cache_dir
      catch :nextResource do
        _handle_resource(resource)
        orig_line.sub!(resource.url,resource.local_filename.to_s) if self.class.rewrite_urls
      end
    end
    return orig_line
  end
  
  def _handle_resource(resource)
    resource.headers = {}
    _cleanup_uri(resource)

    if resource.always_skip?
      print "S" if self.class.verbose
      throw :nextResource
    end
    
  	_try(resource, lambda {
      resource.load
    })
    
    if resource.relativize_only?
      print 'r' if self.class.verbose
      return
    end

    # skip downloading already existing files.
    # because we're working with sha1 hashes we can be reasonably certain the content is a complete match
    if resource.exists?
      print 's' if self.class.verbose
    else
      # if it's an otml/html file, we should parse it too (only one level down)
      if (self.should_recurse? && resource.recursable?)
        _recurse(resource)
      end
      _write(resource)
    end
  end
  
  def _cleanup_uri(resource)
    _try(resource, lambda {
      # strip whitespace from the end of the match url, but don't alter the url so that when
      # we replace the url later, we can, in essence, fix the malformed url 
      resource.uri = URI.parse(CGI.unescapeHTML(resource.url.sub(/\s+$/,'')))
    })
    if (resource.uri.relative?)
      # relative URL's need to have their parent document's codebase appended before trying to download
      resource.uri = self.uri.merge(resource.url.sub(/\s+$/,''))
    end
  end
  
  def _recurse(resource)
    puts "recursively parsing '#{resource.uri_str}'" if self.class.debug
		_try(resource, lambda {
		  resource.reserve # touch the file so that we know not to try to re-process the file we're currently processing
      resource.process
    })
	end
	
	def _write(resource)
	  _try(resource, lambda {
      resource.write
      print "." if self.class.verbose
    })
  end
  
  def _try(resource, lam)
    begin
      lam.call
    rescue => e
      self.class.error(self.url,"Problem getting or writing file: #{resource.uri_str},   Error: #{e}")
      print 'X' if self.class.verbose
      resource.release
      throw :nextResource
    rescue Timeout::Error
      retry
    end
  end
end
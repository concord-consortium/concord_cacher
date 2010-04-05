class ::Concord::FilenameGenerators::DiyGenerator < ::Concord::FilenameGenerators::DefaultGenerator
  require 'fileutils'
  require 'uri'
  require 'digest/sha1'
  
  def self.generate_filename(resource)
    return "#{resource.extras[:activity].uuid}.otml" if resource.extras && resource.extras[:activity]
    raise ::ArgumentError, "Resource must have a valid URI" unless resource.uri && resource.uri.kind_of?(::URI)
    uri = resource.uri
    uri_path = uri.path.split('/')
    uri_path = ["","index.html"] if uri_path.size == 0
    uri_path.unshift("") if uri_path.size == 1
    file_ext = uri_path[-1].split('.')[-1]
    file = ::Digest::SHA1.hexdigest(uri.to_s)
    file += ".#{file_ext}" if file_ext
    return file
  end
end
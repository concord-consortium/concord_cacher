class ::Concord::FilenameGenerators::JavaProxyGenerator < ::Concord::FilenameGenerators::DefaultGenerator
  require 'digest/sha1'
  
  def self.generate_filename(resource)
    raise ::ArgumentError, "Resource must have valid content!" unless resource.content
    ::Digest::SHA1.hexdigest(resource.content)
  end
end
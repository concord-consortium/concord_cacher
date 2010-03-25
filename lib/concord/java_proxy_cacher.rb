class ::Concord::JavaProxyCacher < ::Concord::Cacher
  require 'digest/sha1'
  
  def generate_main_filename
    generate_filename(:content => @content)
  end
  
  def generate_uuid
    generate_filename(:content => @content)
  end
  
  def generate_filename(opts = {})
    raise InvalidArgumentError, "Must include :content key in opts" unless opts[:content]
    ::Digest::SHA1.hexdigest(opts[:content])
  end
end
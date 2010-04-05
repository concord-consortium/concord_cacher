class ::Concord::FilenameGenerators::DefaultGenerator
  require 'digest/sha1'
  
  @count = 0
  class << self
    attr_reader :count
  end
  
  def self.next_sequence
    @count += 1
    return @count
  end
  
  def self.generate_filename(resource)
    ::Digest::SHA1.hexdigest(next_sequence.to_s)
  end
end
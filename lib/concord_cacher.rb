$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module Concord
  require 'concord/cacher'
  require 'concord/diy_local_cacher'
  require 'concord/java_proxy_cacher'
end
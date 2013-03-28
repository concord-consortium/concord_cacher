$:.unshift(File.expand_path(File.dirname(__FILE__))) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))


raise "concord_cacher is incompatible with your version of ruby (#{RUBY_VERSION})" unless RUBY_VERSION =~ /^1\.8\.[67]/

module Concord
  require 'concord/filename_generators'
  require 'concord/diy_local_cacher'
  require 'concord/java_proxy_cacher'
end
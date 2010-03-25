begin
  require 'concord_cacher'
rescue LoadError
  require File.join(File.dirname(__FILE__), '..','lib','concord.rb')
end

require File.join(File.dirname(__FILE__),'helpers','cache_helper.rb')

require 'fileutils'

include FileUtils

require 'openssl'
module OpenSSL
  module SSL
	  remove_const :VERIFY_PEER
	end
end
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

SPEC_ROOT = File.expand_path(File.dirname(__FILE__))


describe 'Java Proxy Cacher' do
  include CacheHelper
  
  before(:each) do
    @klass = Concord::JavaProxyCacher
    @cache = File.join(SPEC_ROOT, "..", 'tmp','java_proxy')
    mkdir_p(@cache)
    @cache += '/'
  end
  
  after(:each) do
    rm_rf(@cache)
  end
  
  describe 'empty otml' do
    it 'should create a url map xml file' do
      cache('empty.otml')
      exists?('url_map.xml')
    end
  
    it 'should create a cached file of the original url' do
      url = File.join(SPEC_ROOT,'data','empty.otml')
      expected_filename = ::Digest::SHA1.hexdigest(File.read(url))
      cache('empty.otml')
      exists?(expected_filename)
    end
  
    it 'should create a cached header of the original url' do
      url = File.join(SPEC_ROOT,'data','empty.otml')
      expected_filename = ::Digest::SHA1.hexdigest(File.read(url))
      cache('empty.otml')
      exists?("#{expected_filename}.hdrs")
    end
  end
  
  describe 'standard uri syntax' do
    it 'should cache 2 referenced files' do
      expected_files = []
      expected_files << 'e954312036485d3ca1894265922d9bd9491bf59e' # standard_uri.otml
      expected_files << '8f0ebcb45d7ba71a541d4781329f4a6900c7ee65' # http://portal.concord.org/images/icons/delete.png
      expected_files << '21b8b442e4449f642fcbd6796f4f0f937ec6c70d' # https://mail.google.com/mail/images/2/5/mountains/base/gmail_solid_white.png
      expected_files << expected_files.collect{|f| f+".hdrs" } # headers for each file
      expected_files.flatten!
      expected_files << 'url_map.xml'

      cache('standard_uri.otml')
      
      cache_size.should == 7
      expected_files.each do |f|
        exists?(f)
      end
    end
  end
  
  describe 'element references syntax' do
    it 'should cache 6 referenced files' do
      expected_files = []
      expected_files << '9f945e576290efa874842b4ee07ab437d9d94a67' # element_reference.otml
      expected_files << 'd9a2565586307e2924c953dfe788154749e93799' # http://loops.diy.concord.org/
      expected_files << '4e9576a56db3d142113b8905d7aa93e31c9f441b' # http://portal.concord.org/images/icons/chart_bar.png
      expected_files << '41f082b7e69a399679a47acfdcd7e7a204e49745' # http://portal.concord.org/images/icons/chart_pie.png
      expected_files << 'cbe7ac86926fd3b8aa8659842a1d8c299d8966a7' # resources/text.txt
      expected_files << '8f0ebcb45d7ba71a541d4781329f4a6900c7ee65' # resources/delete.png
      expected_files << 'd1cea238486aeeba9215d56bf71efc243754fe48' # resources/chart_line.png
      expected_files << expected_files.collect{|f| f+".hdrs" } # headers for each file
      expected_files.flatten!
      expected_files << 'url_map.xml'
      
      cache('element_reference.otml')
      
      cache_size.should == 15
      expected_files.each do |f|
        exists?(f)
      end
    end
  end
  
  describe 'recursive references' do
    it 'should cache 4 referenced files in otml files' do
      expected_files = []
      expected_files << 'dbbd46b446a205047cfbf32e7af350a73c38848d' # recursion.otml
      expected_files << 'cdc3d425b0ac9c3e89e1b79e0ad8a07c09bcedbd' # resources/recurse1.otml
      expected_files << '8f0ebcb45d7ba71a541d4781329f4a6900c7ee65' # resources/delete.png
      expected_files << '10f39c75f40386e8fbbb9320b6e77f3bd12b0f1d' # resources/recurse2.otml
      expected_files << 'd1cea238486aeeba9215d56bf71efc243754fe48' # resources/chart_line.png
      expected_files << expected_files.collect{|f| f+".hdrs" } # headers for each file
      expected_files.flatten!
      expected_files << 'url_map.xml'
      
      cache('recursion.otml')
      
      cache_size.should == 11
      expected_files.each do |f|
        exists?(f)
      end
    end
  end
  
  describe 'embedded nlogo files' do
    it 'should correctly download resources referenced from within netlogo model files'
  end
  
  describe 'embedded mw files' do
    it 'should correctly download resources referenced from within mw model files'
  end
  
  describe 'never cache' do
    it 'should always skip mailto and jres references'
  end
  
  describe 'recursion limits' do
    it 'should only recurse html files once'
    it 'should recurse otml,cml,mml and nlogo files forever'
  end
end
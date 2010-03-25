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

describe 'DIY Local Cacher' do
  include CacheHelper
  
  before(:each) do
    @klass = Concord::DiyLocalCacher
    @cache = File.join(SPEC_ROOT, '..', 'tmp','diy_local')
    mkdir_p(@cache)
    @cache += '/'
  end
  
  def mockup(file)
    return mock('activity',{:uuid => 'hash', :url => file})
  end
  
  after(:each) do
    rm_rf(@cache)
  end
  
  describe 'empty otml' do
    it 'should not create a url map xml file' do
      cache('empty.otml', :activity => mockup('empty.otml'))
      does_not_exist?('url_map.xml')
    end
  
    it 'should create a cached file of the original url' do
      url = File.join(SPEC_ROOT,'data','empty.otml')
      cache('empty.otml', :activity => mockup('empty.otml'))
      exists?('hash.otml')
    end
  
    it 'should not create a cached header of the original url' do
      url = File.join(SPEC_ROOT,'data','empty.otml')
      expected_filename = 'hash.otml'
      cache('empty.otml', :activity => mockup('empty.otml'))
      does_not_exist?("#{expected_filename}.hdrs")
    end
  end
  
  describe 'standard uri syntax' do
    it 'should cache 2 referenced files' do
      expected_files = []
      expected_files << 'hash.otml' # standard_uri.otml
      expected_files << ::Digest::SHA1.hexdigest('http://portal.concord.org/images/icons/delete.png')
      expected_files << ::Digest::SHA1.hexdigest('https://mail.google.com/mail/images/2/5/mountains/base/gmail_solid_white.png')

      cache('standard_uri.otml', :activity => mockup('standard_uri.otml'))
      
      cache_size.should == 3
      expected_files.each do |f|
        exists?(f)
      end
      
      
    end
    
    it 'should rewrite the urls in the main otml file' do
      cache('standard_uri.otml', :activity => mockup('standard_uri.otml'))
      
      file_content = File.read(File.join(@cache,'hash.otml'))
      
      file_content.should_not match(/http:/)
      file_content.should match(::Digest::SHA1.hexdigest('http://portal.concord.org/images/icons/delete.png'))
      file_content.should match(::Digest::SHA1.hexdigest('https://mail.google.com/mail/images/2/5/mountains/base/gmail_solid_white.png'))
    end
  end
  
  describe 'element references syntax' do
    it 'should cache 6 referenced files' do
      expected_files = []
      expected_files << 'hash.otml' # element_reference.otml
      expected_files << ::Digest::SHA1.hexdigest('http://loops.diy.concord.org/')
      expected_files << ::Digest::SHA1.hexdigest('http://portal.concord.org/images/icons/chart_bar.png')
      expected_files << ::Digest::SHA1.hexdigest('http://portal.concord.org/images/icons/chart_pie.png')
      expected_files << ::Digest::SHA1.hexdigest(File.join(SPEC_ROOT,'data','resources','text.txt'))
      expected_files << ::Digest::SHA1.hexdigest(File.join(SPEC_ROOT,'data','resources','delete.png'))
      expected_files << ::Digest::SHA1.hexdigest(File.join(SPEC_ROOT,'data','resources','chart_line.png'))
      
      cache('element_reference.otml', :activity => mockup('element_reference.otml'))
      
      cache_size.should == 7
      expected_files.each do |f|
        exists?(f)
      end
    end
    
    it 'should rewrite the urls in the main otml file' do
      expected_urls = []
      unexpected_urls = []
      unexpected_urls << 'http://loops.diy.concord.org/'
      unexpected_urls << 'http://portal.concord.org/images/icons/chart_bar.png'
      unexpected_urls << 'http://portal.concord.org/images/icons/chart_pie.png'
      unexpected_urls << File.join('resources','text.txt')
      unexpected_urls << File.join('resources','delete.png')
      unexpected_urls << File.join('resources','chart_line.png')
      
      unexpected_urls.each do |url|
        if url =~ /^http/
          expected_urls << ::Digest::SHA1.hexdigest(url)
        else
          expected_urls << ::Digest::SHA1.hexdigest(File.join(SPEC_ROOT,'data',url))
        end
      end
      
      cache('element_reference.otml', :activity => mockup('element_reference.otml'))
      
      file_content = File.read(File.join(@cache,'hash.otml'))
      
      unexpected_urls.each do |url|
        file_content.should_not match(Regexp.new(url))
      end
      
      expected_urls.each do |url|
        file_content.should match(Regexp.new(url))
      end
    end
  end
  
  describe 'recursive references' do
    it 'should cache 4 referenced files in otml files' do
      expected_files = []
      expected_files << 'hash.otml' # recursion.otml
      expected_files << ::Digest::SHA1.hexdigest(File.join(SPEC_ROOT,'data','resources','recurse1.otml'))
      expected_files << ::Digest::SHA1.hexdigest(File.join(SPEC_ROOT,'data','resources','delete.png'))
      expected_files << ::Digest::SHA1.hexdigest(File.join(SPEC_ROOT,'data','resources','recurse2.otml'))
      expected_files << ::Digest::SHA1.hexdigest(File.join(SPEC_ROOT,'data','resources','chart_line.png'))
      
      cache('recursion.otml', :activity => mockup('recursion.otml'))
      
      cache_size.should == 5
      expected_files.each do |f|
        exists?(f)
      end
    end
    
    it 'should rewrite urls in first level recursion otml' do
      recurse_otml = ::Digest::SHA1.hexdigest(File.join(SPEC_ROOT,'data','resources','recurse1.otml'))
      
      expected_urls = []
      unexpected_urls = []
      
      unexpected_urls << File.join('resources','recurse2.otml')
      unexpected_urls << File.join('resources','delete.png')
      
      unexpected_urls.each do |url|
        expected_urls << ::Digest::SHA1.hexdigest(File.join(SPEC_ROOT,'data',url))
      end
      
      cache('recursion.otml', :activity => mockup('recursion.otml'))
      
      file_content = File.read(File.join(@cache,recurse_otml))
      
      unexpected_urls.each do |url|
        file_content.should_not match(Regexp.new(url))
      end
      
      expected_urls.each do |url|
        file_content.should match(Regexp.new(url))
      end
    end
    
    it 'should rewrite urls in second level recursion otml' do
      recurse_otml = ::Digest::SHA1.hexdigest(File.join(SPEC_ROOT,'data','resources','recurse2.otml'))
      
      expected_urls = []
      unexpected_urls = []

      unexpected_urls << File.join('resources','chart_line.png')
      
      unexpected_urls.each do |url|
        expected_urls << ::Digest::SHA1.hexdigest(File.join(SPEC_ROOT,'data',url))
      end
      
      cache('recursion.otml', :activity => mockup('recursion.otml'))
      
      file_content = File.read(File.join(@cache,recurse_otml))
      
      unexpected_urls.each do |url|
        file_content.should_not match(Regexp.new(url))
      end
      
      expected_urls.each do |url|
        file_content.should match(Regexp.new(url))
      end
    end
    
    it 'should not get stuck when handling circular loops' do
      expected_files = []
      expected_files << 'hash.otml' # recursion.otml
      expected_files << ::Digest::SHA1.hexdigest(File.join(SPEC_ROOT,'data','resources','loop1.otml'))
      expected_files << ::Digest::SHA1.hexdigest(File.join(SPEC_ROOT,'data','resources','delete.png'))
      expected_files << ::Digest::SHA1.hexdigest(File.join(SPEC_ROOT,'data','resources','loop2.otml'))
      expected_files << ::Digest::SHA1.hexdigest(File.join(SPEC_ROOT,'data','resources','chart_line.png'))
      
      lambda {
        cache('recursive_loop.otml', :activity => mockup('recursive_loop.otml'))
      }.should_not raise_error(SystemStackError)
      
      cache_size.should == 5
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
require 'concord'
require 'fileutils'

include FileUtils

describe 'Java Proxy Cacher' do
  before(:each) do
    @cache = File.join(File.dirname(__FILE__), "..", 'tmp','java_proxy')
    rm_rf(@cache)
    mkdir_p(@cache)
    @cache += '/'
  end
  # Dir.glob(@cache + "/*").size.should == 3
  
  it 'should create a url map xml file' do
    cacher = Concord::JavaProxyCacher.new(:url => File.join(File.dirname(__FILE__),'data','empty.otml'), :cache_dir => @cache)
    cacher.cache
    File.exists?(File.join(@cache,'url_map.xml')).should be_true
  end
  
  it 'should create a cached file of the original url' do
    cacher = Concord::JavaProxyCacher.new(:url => File.join(File.dirname(__FILE__),'data','empty.otml'), :cache_dir => @cache)
    cacher.cache
    File.exists?(File.join(@cache,'334ba4891d03b6e0fada493661534eedd57e1493')).should be_true
  end
  
  it 'should create a cached header of the original url' do
    cacher = Concord::JavaProxyCacher.new(:url => File.join(File.dirname(__FILE__),'data','empty.otml'), :cache_dir => @cache)
    cacher.cache
    File.exists?(File.join(@cache,'334ba4891d03b6e0fada493661534eedd57e1493.hdrs')).should be_true
  end
end
begin
  require 'concord_cacher'
rescue LoadError
  require File.expand_path(File.join(File.dirname(__FILE__), '..','lib','concord.rb'))
end

require File.expand_path(File.join(File.dirname(__FILE__),'helpers','cache_helper.rb'))

require 'fileutils'

include FileUtils

describe 'Java Proxy Cacher' do
  include CacheHelper
  
  before(:each) do
    @klass = Concord::JavaProxyCacher
    @spec_root = File.expand_path(File.dirname(__FILE__))
    @cache = File.join(@spec_root, "..", 'tmp','java_proxy')
    mkdir_p(@cache)
    @cache += '/'
  end
  
  after(:each) do
    rm_rf(@cache)
  end
  
  describe 'empty otml' do
    it 'should create a url map xml file' do
      cache('empty.otml')
      cache_size.should == 3
      exists?('url_map.xml')
    end
  
    it 'should create a cached file of the original url' do
      url = File.join(@spec_root,'data','empty.otml')
      expected_filename = ::Digest::SHA1.hexdigest(File.read(url))
      cache('empty.otml')
      cache_size.should == 3
      exists?(expected_filename)
    end
  
    it 'should create a cached header of the original url' do
      url = File.join(@spec_root,'data','empty.otml')
      expected_filename = ::Digest::SHA1.hexdigest(File.read(url))
      cache('empty.otml')
      cache_size.should == 3
      exists?("#{expected_filename}.hdrs")
    end
  end
  
  describe 'error handling' do
    it 'should handle a bad url gracefully' do
      url = File.join(@spec_root,'data','bad_url.otml')
      expected_filename = ::Digest::SHA1.hexdigest(File.read(url))
      
      lambda {
        cache('bad_url.otml')
      }.should_not raise_error
      
      cache_size.should == 3
      
      exists?(expected_filename)
      does_not_exist?('8f0ebcb45d7ba71a541d4781329f4a6900c7ee65') # http://portal.concord.org/images/icons/delete.png
    end
    
    it 'should handle a url with trailing spaces gracefully' do
      url = File.join(@spec_root,'data','url_with_space.otml')
      expected_filename = ::Digest::SHA1.hexdigest(File.read(url))
      
      lambda {
        cache('url_with_space.otml')
      }.should_not raise_error
      
      cache_size.should == 5
      
      exists?(expected_filename)
      exists?('d1cea238486aeeba9215d56bf71efc243754fe48') # http://portal.concord.org/images/icons/chart_line.png
    end
    
    it 'should handle an empty url gracefully' do
      url = File.join(@spec_root,'data','empty_url.otml')
      expected_filename = ::Digest::SHA1.hexdigest(File.read(url))
      
      lambda {
        cache('empty_url.otml')
      }.should_not raise_error
      
      cache_size.should == 3
      
      exists?(expected_filename)
    end
    
    it 'should handle an empty root url gracefully' do
      pending do
      lambda {
        cache('')
      }.should_not raise_error
      
      cache_size.should == 1
    end
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
      expected_files << '836ba09d9d7288cf735f555e7a9b9b314ad2f6ef' # element_reference.otml
      expected_files << '20e89b62dda582d80e1832050f4998d64c801c03' # http://www.concord.org/~aunger/
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
    
    it 'should not get stuck when handling circular loops' do
      expected_files = []
      expected_files << '14a11cc1ba19ce76d651c93f8294009e3e46f0db' # recursive_loop.otml
      expected_files << '2a564e6997c4a43bdfa3b0314e5bed7f9a5673ec' # resources/loop1.otml
      expected_files << '8f0ebcb45d7ba71a541d4781329f4a6900c7ee65' # resources/delete.png
      expected_files << '156b6f0a8885251ea5853cbebd1e9da5fedc00e0' # resources/loop2.otml
      expected_files << 'd1cea238486aeeba9215d56bf71efc243754fe48' # resources/chart_line.png
      expected_files << expected_files.collect{|f| f+".hdrs" } # headers for each file
      expected_files.flatten!
      expected_files << 'url_map.xml'
      
      lambda {
        cache('recursive_loop.otml')
      }.should_not raise_error(SystemStackError)
      
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
    it 'should always skip some references' do
      url = File.join(@spec_root,'data','always_skip.otml')
      expected_filename = ::Digest::SHA1.hexdigest(File.read(url))
      cache('always_skip.otml')
      cache_size.should == 3
    end
  end
  
  describe 'recursion limits' do
    it 'should only recurse html files once'
    it 'should recurse otml,cml,mml and nlogo files forever'
  end
  
  describe 'special cases' do
    it 'should not unencode xml entities that are not part of a url' do
      expected_files = []
      expected_files << "40f8f0e37503367ea32732b9a357722b6a750d0e" # xml_entities.otml
      expected_files << 'd1cea238486aeeba9215d56bf71efc243754fe48' # resources/chart_line.png
      expected_files << expected_files.collect{|f| f+".hdrs" } # headers for each file
      expected_files.flatten!
      expected_files << 'url_map.xml'
      
      cache('xml_entities.otml')

      cache_size.should == 5
      expected_files.each do |f|
        exists?(f)
      end
      
      file_content = File.read(File.join(@cache,'40f8f0e37503367ea32732b9a357722b6a750d0e'))

      file_content.should match(Regexp.new('<OTText text="&lt;img src=&quot;http://portal.concord.org/images/icons/chart_line.png&quot; /&gt;" />'))      
    end
    
    it 'should maintain newlines occurring at the end of the file' do
      cache('xml_entities.otml')
      
      file_content = File.read(File.join(@cache,'40f8f0e37503367ea32732b9a357722b6a750d0e'))
      
      file_content.should match(/\n\n$/m)
    end
    
    it 'should find a src= reference when there is an absolute url on the same line' do
      cache('flash_file.otml')
      
      cache_size.should == 13
      
      exists?('2e867d0a681370b8debb0a7981915c0f8f6de33b') # radishes.html
      exists?('e04e4e2fdfb39c5b8776fa365bd9ac4fdb3851d5') # radishes.swf
    end
  end
  
  describe 'url map' do
    it 'should always use absolute urls as keys' do
      data_dir = File.join(@spec_root, 'data')
      expected_entries = []
      expected_entries << {:val => '836ba09d9d7288cf735f555e7a9b9b314ad2f6ef', :key => File.expand_path('element_reference.otml',data_dir)}
      expected_entries << {:val => '20e89b62dda582d80e1832050f4998d64c801c03', :key => 'http://www.concord.org/~aunger/'}
      expected_entries << {:val => '4e9576a56db3d142113b8905d7aa93e31c9f441b', :key => 'http://portal.concord.org/images/icons/chart_bar.png'}
      expected_entries << {:val => '41f082b7e69a399679a47acfdcd7e7a204e49745', :key => 'http://portal.concord.org/images/icons/chart_pie.png'}
      expected_entries << {:val => 'cbe7ac86926fd3b8aa8659842a1d8c299d8966a7', :key => File.expand_path('resources/text.txt',data_dir)}
      expected_entries << {:val => '8f0ebcb45d7ba71a541d4781329f4a6900c7ee65', :key => File.expand_path('resources/delete.png',data_dir)}
      expected_entries << {:val => 'd1cea238486aeeba9215d56bf71efc243754fe48', :key => File.expand_path('resources/chart_line.png',data_dir)}
      
      cache('element_reference.otml')
      
      url_map_content = File.read(File.expand_path('url_map.xml', @cache))
      
      expected_entries.each do |e|
        url_map_content.should match(Regexp.new("<entry key='#{e[:key]}'>#{e[:val]}</entry>"))
      end
    end
    
    it 'should list both urls when the content is the same' do
      expected_entries = []
      expected_entries << {:key => 'http://udl.concord.org/artwork/elect_34/red_positive_charge/el_34_red_positive_charge.png', :val => '0cb63d1b4b57af2b8fa671854caa707da5390a80'}
      expected_entries << {:key => 'http://udl.concord.org/artwork/elect_34/red_postive_charge/el_34_red_positive_charge.png', :val => '0cb63d1b4b57af2b8fa671854caa707da5390a80'}
      
      cache('same_content.otml')
      
      url_map_content = File.read(File.expand_path('url_map.xml', @cache))
      
      expected_entries.each do |e|
        url_map_content.should match(Regexp.new("<entry key='#{e[:key]}'>#{e[:val]}</entry>"))
      end
    end
  end
end
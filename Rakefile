require 'rubygems'

require 'rake'
require 'spec/rake/spectask'

require './lib/concord_cacher.rb'

require 'echoe'
Echoe.new('concord_cacher', '0.1.9') do |p|
  p.description    = "concord_cacher provides support for locally caching a resource and all referenced resources in multiple different ways. It is intended for using with other Concord Consortium projects and not necessarily for outside projects."
  p.summary        = "Support for locally caching a resource and all referenced resources in multiple different ways"
  p.url            = "http://github.com/psndcsrv/concord_cacher"
  p.author         = "Aaron Unger"
  p.email          = "aunger @nospam@ concord.org"
  p.ignore_pattern = ["tmp/*","pkg/*","hudson/*"]
  p.development_dependencies = []
  p.runtime_dependencies = []
  p.clean_pattern = ["hudson/*", "tmp/*"]
end

task :default => :spec
Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList["spec/**/*_spec.rb"]
end

namespace :hudson do
  task :spec => ["hudson:setup:rspec", 'rake:spec']

  namespace :setup do
    task :pre_ci do
      ENV["CI_REPORTS"] = 'hudson/reports/'
      gem 'ci_reporter'
      require 'ci/reporter/rake/rspec'
    end
    task :rspec => [:pre_ci, "ci:setup:rspec"]
  end
end

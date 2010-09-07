require "rubygems"
require "bundler"
Bundler.setup(:test, :ci)

require 'rake'
require 'spec/rake/spectask'
require './lib/concord_cacher.rb'

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

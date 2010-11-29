require 'bundler'
Bundler.setup

require 'rake'
require 'rake/rdoctask'
require 'rspec'
require 'rspec/core/rake_task'

task :gem => :build
task :build do
  system "gem build mongoid_taggable.gemspec"
end

task :install => :build do
  system "gem install mongoid_taggable-#{Mongoid::Taggable::VERSION}.gem"
end

desc 'Default: run unit tests.'
task :default => :spec

Rspec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = "spec/**/*_spec.rb"
end

desc 'Generate documentation for the mongoid_taggable plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'MongoidTaggable'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc 'Default: run unit tests.'
task :default => :spec

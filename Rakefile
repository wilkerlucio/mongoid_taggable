require 'rake'
require 'rake/rdoctask'
require 'rspec'
require 'rspec/core/rake_task'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "mongoid_taggable"
    gemspec.version = "0.1.7"
    gemspec.summary = "Mongoid taggable behaviour"
    gemspec.description = "Mongoid Taggable provides some helpers to create taggable documents."
    gemspec.email = "wilkerlucio@gmail.com"
    gemspec.homepage = "http://github.com/wilkerlucio/mongoid_taggable"
    gemspec.authors = ["Wilker Lucio", "Kris Kowalik"]
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
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

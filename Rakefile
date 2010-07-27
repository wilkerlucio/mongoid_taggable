require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "mongoid_taggable"
    gemspec.version = "0.1.1"
    gemspec.summary = "Mongoid taggable behaviour"
    gemspec.description = "Mongoid Taggable provides some helpers to create taggable documents."
    gemspec.email = "wilkerlucio@gmail.com"
    gemspec.homepage = "http://github.com/kriss/mongo_taggable"
    gemspec.authors = ["Wilker Lúcio", "Kris Kowalik"]
  end
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end


desc 'Default: run unit tests.'
task :default => :test

desc 'Test the mongoid_taggable plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the mongoid_taggable plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'MongoidTaggable'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

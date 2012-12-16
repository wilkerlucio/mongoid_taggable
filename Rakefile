require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'
require 'rdoc/task'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "mongoid_taggable"
    gemspec.version = "0.1.7"
    gemspec.summary = "Mongoid taggable behaviour"
    gemspec.description = "Mongoid Taggable provides some helpers to create taggable documents."
    gemspec.email = "wilkerlucio@gmail.com"
    gemspec.homepage = "http://github.com/wilkerlucio/mongoid_taggable"
    gemspec.authors = ["Wilker Lucio", "Kris Kowalik", 'Vladimir Krylov']
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end


require 'rspec'
require 'rspec/core/rake_task'
desc "Run specs"
RSpec::Core::RakeTask.new :spec

task :default => :spec

desc 'Generate documentation for the mongoid_taggable plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'MongoidTaggable'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

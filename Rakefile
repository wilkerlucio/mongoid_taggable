require 'bundler'
require 'bundler/gem_tasks'
begin
  Bundler.setup(:default, :test)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rake'
require 'rdoc/task'
require 'rspec'
require 'rspec/core/rake_task'

desc 'Run specs'
task :default => :spec

RSpec::Core::RakeTask.new :spec

desc 'Generate documentation for the mongoid_taggable plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'MongoidTaggable'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

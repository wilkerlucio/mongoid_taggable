# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |g|
  g.name        = 'mongoid_taggable'
  g.version     = '1.1.1'
  g.date        = '2013-03-22'
  g.description = %q{Mongoid Taggable provides some helpers to create taggable documents.}
  g.summary     = %q{Mongoid taggable behaviour}
  g.authors     = ['Wilker Lucio', 'Kris Kowalik', 'Adam St. John', 'Caleb Clark']
  g.email       = ['cclark@mobilizationlabs.com']
  g.homepage    = 'http://github.com/wilkerlucio/mongoid_taggable'

  g.extra_rdoc_files = %w(LICENSE README.textile)

  g.files         = `git ls-files`.split($/)
  g.test_files    = g.files.grep(%r{^(test|spec|features)/})
  g.require_paths = ['lib']

  g.add_runtime_dependency 'rake', '>= 0'
  g.add_runtime_dependency 'mongoid', '>= 3'
end

$: << File.expand_path("../../lib", __FILE__)

require 'database_cleaner'

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end

require 'mongoid'
require 'mongoid_taggable'

if Mongoid::Taggable.mongoid3? || Mongoid::Taggable.mongoid4?
  Mongoid.load!("spec/mongoid3+4.yml", :test)
else
  Mongoid.load!("spec/mongoid5.yml", :test)
end


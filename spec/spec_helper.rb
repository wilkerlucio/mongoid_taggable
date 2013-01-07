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

def database_id
    ENV['CI'] ? "mongoid_taggable_#{Process.pid}" : 'mongoid_taggable_test'
end

Mongoid.configure do |config|
  config.connect_to database_id
end

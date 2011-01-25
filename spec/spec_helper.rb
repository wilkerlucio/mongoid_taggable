$: << File.expand_path("../../lib", __FILE__)

require 'mongoid'
require 'mongoid_taggable'

Mongoid.configure do |config|
  config.master = Mongo::Connection.new.db("mongoid_taggable_test")
end

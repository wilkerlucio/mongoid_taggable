begin
  require File.join(File.dirname(__FILE__), %w[.. .. .. .. spec spec_helper])
rescue LoadError
  puts "You need to install rspec in your base app"
  exit
end

plugin_spec_dir = File.dirname(__FILE__)

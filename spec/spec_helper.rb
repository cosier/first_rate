$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "rspec"
require "factory_girl"
require "first_rate"

# Set the database that the spec suite connects to.
Mongoid.configure do |config|
  config.connect_to("firstrate_test", consistency: :strong)
end

FactoryGirl.definition_file_paths << File.expand_path("../factories", __FILE__)
FactoryGirl.find_definitions

RSpec.configure do |config|
  config.order = "random"
  
  # Drop all collections and clear the identity map before each spec.
  config.before(:each) do
    Mongoid.purge!
    Mongoid::IdentityMap.clear
  end
end



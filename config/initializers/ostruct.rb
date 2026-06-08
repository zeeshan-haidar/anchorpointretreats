# config/initializers/ostruct.rb
# Ruby 3.3+ deprecates ostruct from default gems, but we use it extensively
# in service objects for the OpenStruct pattern.
require "ostruct"

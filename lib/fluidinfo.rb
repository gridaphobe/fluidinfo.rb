require File.join(File.dirname(__FILE__), "/fluidinfo/client")
require File.join(File.dirname(__FILE__), "/fluidinfo/response")

##
# +fludiinfo.rb+ is a library for interacting with
# {http://www.fluidinfo.com Fluidinfo}. Take a look at
# {Fluidinfo::Client} to get started.
module Fluidinfo
  ITERABLE_TYPES      = [Array]
  SERIALIZEABLE_TYPES = [NilClass, String, Fixnum, Float, Symbol, TrueClass, FalseClass, Array]
  JSON_TYPES          = ["application/json", "application/vnd.fluiddb.value+json"]
  # The main instance of Fluidinfo.
  MAIN = 'https://fluiddb.fluidinfo.com'
end

require "yajl"

module Fluidinfo

  ##
  # An instance of {Fluidinfo::Response} is returned by all of the
  # {Fluidinfo::Client} calls. There's no reason to instantiate one
  # yourself.
  class Response
    # [Integer] The return code of the API call.
    attr_reader :status
    # [Hash] The returned headers.
    attr_reader :headers
    # [String, nil] The raw response
    attr_reader :content
    # [Hash, String] The parsed response if the +Content-Type+ was one of {Fluidinfo::JSON_TYPES}, otherwise equivalent to {#content}.
    attr_reader :value
    # [String] The error, if any, returned by Fluidinfo
    attr_reader :error

    def initialize(response)
      @status   = response.code
      @headers  = response.headers
      @error    = @headers[:x_fluiddb_error_class]
      @content  = response.body
      @value    = if JSON_TYPES.include? @headers[:content_type]
                    Yajl.load @content
                  else
                    @content
                  end
    end

    ##
    # A shortcut for +Response.value#[]+.
    def [](key)
      @value[key]
    end

  end
end

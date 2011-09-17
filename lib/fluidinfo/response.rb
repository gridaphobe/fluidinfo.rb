require "yajl"

module Fluidinfo
  class Response
    attr_reader :status, :headers, :content, :value

    def initialize(response)
      @status   = response.code
      @headers  = response.headers
      @content  = response.body
      @value    = if JSON_TYPES.include? @headers[:content_type]
                    Yajl.load @content
                  else
                    @content
                  end
    end

    def [](key)
      @value[key]
    end
    
  end
end

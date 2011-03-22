require "rest-client"
require "uri"
require "json"

module Fluidinfo
  class Client
    # The main fluidinfo instance.
    @@MAIN    = 'https://fluiddb.fluidinfo.com'
    # The sandbox instance, test your code here.
    @@SANDBOX = 'https://sandbox.fluidinfo.com'
    
    def initialize(sandbox=false)
      if sandbox
        @instance = @@SANDBOX
      else
        @instance = @@MAIN
      end
      @fluid = RestClient::Resource.new @instance
    end

    def login(user, pass)
      @fluid = RestClient::Resource.new @instance, :user => user, :password => pass
    end

    def logout
      @fluid = RestClient::Resource.new @instance
    end

    # Call GET
    def get(path, options={})
      args = ''
      options.each do |key, val|
        if key == :tags
          val.each do |tag|
            args += "&tag=#{URI.escape tag.to_s}"
          end
        else
          args += "&#{URI.escape key.to_s}=#{URI.escape val.to_s}"
        end
        args[0] = '?'
      end
      path += args
      response = @fluid[path].get
      begin
        JSON.load response.to_str
      rescue
        eval response.to_str
      end
    end
    
    def post(path, body=nil, mime=nil)
      unless mime
        mime = :json
        body = JSON.dump body
      end
      JSON.parse(@fluid[path].post body, :content_type => mime)
    end
    
    def put(path, body=nil, mime=nil, query=nil)
      if query
        query = URI.escape query
        path += "?query=#{query}"
      end
      unless mime
        mime = :json
        body = JSON.dump body
      end
      JSON.parse(@fluid[path].put body, :content_type => mime)
    end
    
    def delete(path, query=nil, tags=nil)
      if query
        query = URI.escape query
        path += "?query=#{query}"
      end
      if tags
        tags.each do |tag|
          tag = URI.escape tag
          path += "&tag=#{tag}"
        end
      end
      JSON.parse(@fluid[path].delete)
    end
  end
end

require "rest-client"
require "uri"
require "json"
require "base64"
require "crack/json"

module Fluidinfo
  class Client
    # The main fluidinfo instance.
    @@MAIN    = 'https://fluiddb.fluidinfo.com'
    # The sandbox instance, test your code here.
    @@SANDBOX = 'https://sandbox.fluidinfo.com'
    
    def initialize(instance=:main)
      if instance == :sandbox
        @instance = @@SANDBOX
      else
        @instance = @@MAIN
      end
      @headers = {
        :accept => "*/*"
      }
    end

    def login(user, pass)
      auth = "Basic " + (Base64.encode64 "#{user}:#{pass}").strip
      @headers[:authorization] = auth
    end

    def logout
      @headers.delete :authorization
    end

    ##
    # Call GET on one of the APIs
    #
    # +options+ contains URI arguments that will be appended to +path+
    # consult the {Fluidinfo API documentation}[api.fluidinfo.com] for a list of
    # appropriate options
    def get(path, options={})
      path = @instance + path
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
      response = RestClient.get path, @headers
      begin
        JSON.load response.to_str
      rescue JSON::ParserError
        # this should mean that fluidinfo returned a non-hash/array primitive
        Crack::JSON.parse response.to_str
      end
    end

    ##
    # Call HEAD on the /about or /object API to test for the existence
    # of a tag
    def head(path)
      path = @instance + path
      RestClient.head path
    end

    ##
    # Call POST on one of the APIs
    #
    # +options[:body]+ contains the request payload. For some API
    # calls this may be empty.
    def post(path, options={})
      path = @instance + path
      if options[:body]
        body = options[:body]
        mime = "application/json"
        body = JSON.dump options[:body]
        headers = @headers.merge :content_type => mime
        JSON.parse(RestClient.post path, body, headers)
      else
        JSON.parse(RestClient.post path, nil)
      end
    end

    ##
    # Call PUT on one of the APIs
    #
    # +options[:body]+ contains the request payload.
    #
    # +options[:mime]+ contains the MIME-type unless the payload is JSON-encodable
    def put(path, options={})
      path = @instance + path
      if options[:query]
        query = URI.escape options[:query]
        path += "?query=#{query}"
      end
      body = options[:body]
      if options[:mime]
        mime = options[:mime]
      else
        mime = "application/json"
        begin
          body = JSON.dump options[:body]
        rescue JSON::GeneratorError
          if options[:body] == nil
            body = "null"
          else
            body = options[:body].to_s
          end
        end
      end
      # nothing returned in response body for PUT
      headers = @headers.merge :content_type => mime
      RestClient.put path, body, headers
    end

    ##
    # Call DELETE on one of the APIs
    #
    # +options+ contains URI arguments that will be appended to +path+
    # consult the {Fluidinfo API documentation}[api.fluidinfo.com] for a list of
    # appropriate options
    def delete(path, options={})
      path = @instance + path
      if options[:query]
        query = URI.escape options[:query]
        path += "?query=#{query}"
      end
      if options[:tags]
        options[:tags].each do |tag|
          tag = URI.escape tag
          path += "&tag=#{tag}"
        end
      end
      # nothing returned in response body for DELETE
      RestClient.delete path, @headers
    end
  end
  
  def self.version
    # This was borrowed from the rest-client gem :)
    version_path = File.dirname(__FILE__) + "/../VERSION"
    return File.read(version_path).chomp if File.file?(version_path)
    "0.0.0"
  end

end

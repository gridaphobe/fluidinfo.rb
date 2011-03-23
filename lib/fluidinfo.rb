require "rest-client"
require "uri"
require "json"
require "base64"

module Fluidinfo
  class Client
    # The main fluidinfo instance.
    @@MAIN    = 'https://fluiddb.fluidinfo.com'
    # The sandbox instance, test your code here.
    @@SANDBOX = 'https://sandbox.fluidinfo.com'
    
    def initialize(options={})
      if options[:sandbox]
        @instance = @@SANDBOX
      else
        @instance = @@MAIN
      end
      @headers = {
        "Accept" => "*/*"
      }
    end

    def login(user, pass)
      auth = "Basic " + (Base64.encode64 "#{user}:#{pass}").strip
      @headers["Authorization"] = auth
    end

    def logout
      @headers.delete "Authorization"
    end

    # Call GET
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
        eval response.to_str
      end
    end

    def head(path)
      path = @instance + path
      RestClient.head path
    end
    
    def post(path, options={})
      path = @instance + path
      if options[:body]
        if options[:mime]
          mime = options[:mime]
          body = options[:body]
        else
          mime = "application/json"
          begin
            body = JSON.dump options[:body]
          rescue JSON::GeneratorError
            body = options[:body]
          end
        end
        headers = @headers.merge :content_type => mime
        JSON.parse(RestClient.post path, body, headers)
      else
        JSON.parse(RestClient.post path, nil)
      end
    end
    
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
          body = options[:body]
        end
      end
      # nothing returned in response body for PUT
      headers = @headers.merge :content_type => mime
      RestClient.put path, body, headers
    end
    
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
      RestClient.delete path
    end
  end
end

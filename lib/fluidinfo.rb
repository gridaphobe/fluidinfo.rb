require "rest-client"
require "uri"
require "yajl/json_gem"
require "base64"
require "set"

module Fluidinfo
  ITERABLE_TYPES = Set.new [Array, Hash]
  SERIALIZABLE_TYPES = Set.new [NilClass, String, Fixnum, Float, Symbol,
    TrueClass, FalseClass]
  
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
      url = build_url path, options
      response = RestClient.get url, @headers
      JSON.parse response
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
        payload = build_payload options
        headers = @headers.merge :content_type => payload[:mime]
        JSON.parse(RestClient.post path, payload[:body], headers)
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
      url = build_url path, options
      payload = build_payload options
      headers = @headers.merge :content_type => payload[:mime]
      RestClient.put url, payload[:body], headers
    end

    ##
    # Call DELETE on one of the APIs
    #
    # +options+ contains URI arguments that will be appended to +path+
    # consult the {Fluidinfo API documentation}[api.fluidinfo.com] for a list of
    # appropriate options
    def delete(path, options={})
      url = build_url path, options
      # nothing returned in response body for DELETE
      RestClient.delete url, @headers
    end
    
    private
      ##
      # Build a url from the given path and url args
      def build_url(path, options={})
        opts = options.reject do |key, val|
          [:body, :mime].include? key
        end
        args = opts.inject([]) do |arr, (key, val)|
          if key == :tags
            # dealing with tag list
            val.each do |tag|
              arr << "tag=#{tag}"
            end
          else
            arr << "#{key}=#{val}"
          end
          arr
        end.join('&')
        if args != ''
          URI.escape "#{@instance}#{path}?#{args}"
        else
          "#{@instance}#{path}"
        end
      end
      
      ##
      # Build the payload from the options hash
      def build_payload(options)
        payload = options.select {|k,v| [:body, :mime].include? k}
        if payload[:mime]
          # user set mime-type, let them deal with it :)
          payload
        elsif ITERABLE_TYPES.include? payload[:body].class
          payload[:body] = JSON.dump payload[:body]
          payload[:mime] = "application/json"
          payload
        elsif SERIALIZABLE_TYPES.include? payload[:body].class
          payload[:body] = JSON.dump payload[:body]
          payload[:mime] = "application/vnd.fluiddb.value+json"
          payload
        else
          raise TypeError, "You must supply the mime-type"
        end
      end
  end
  
  def self.version
    # This was borrowed from the rest-client gem :)
    version_path = File.dirname(__FILE__) + "/../VERSION"
    return File.read(version_path).chomp if File.file?(version_path)
    "0.0.0"
  end

end

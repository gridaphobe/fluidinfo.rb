require "rest-client"
require "cgi"
require "yajl"
require "base64"
require "set"

module Fluidinfo
  ITERABLE_TYPES      = Set.new [Array]
  SERIALIZEABLE_TYPES = Set.new [NilClass, String, Fixnum, Float, Symbol,
                                 TrueClass, FalseClass, Array]
  JSON_TYPES          = Set.new ["application/json",
                                 "application/vnd.fluiddb.value+json"]

  class Client
    # The main fluidinfo instance.
    MAIN    = 'https://fluiddb.fluidinfo.com'
    # The sandbox instance, test your code here.
    SANDBOX = 'https://sandbox.fluidinfo.com'

    def initialize(instance=:main)
      if instance == :sandbox
        @instance = SANDBOX
      else
        @instance = MAIN
      end
      @headers = {
        :accept => "*/*",
        :user_agent => "fluidinfo.rb/#{Fluidinfo.version}"
      }
    end

    def login(user, pass)
      @headers[:authorization] = "Basic " + 
        (Base64.encode64 "#{user}:#{pass}").strip
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
      Response.new(RestClient.get url, @headers)
    end

    ##
    # Call HEAD on the /about or /object API to test for the existence
    # of a tag
    def head(path)
      path = @instance + path
      Response.new(RestClient.head path, @headers)
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
        Response.new(RestClient.post path, payload[:body], headers)
      else
        Response.new(RestClient.post path, nil, @headers)
      end
    end

    ##
    # Call PUT on one of the APIs
    #
    # +options[:body]+ contains the request payload.
    #
    # +options[:mime]+ contains the MIME-type unless the payload is 
    # JSON-encodable
    def put(path, options={})
      url = build_url path, options
      payload = build_payload options
      headers = @headers.merge(:content_type   => payload[:mime],
                               :content_length => payload[:size])
      Response.new(RestClient.put url, payload[:body], headers)
    end

    ##
    # Call DELETE on one of the APIs
    #
    # +options+ contains URI arguments that will be appended to +path+
    # consult the {Fluidinfo API documentation}[api.fluidinfo.com] for a list 
    # of appropriate options
    def delete(path, options={})
      url = build_url path, options
      # nothing returned in response body for DELETE
      Response.new(RestClient.delete url, @headers)
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
          arr << "#{key}=#{CGI.escape val.to_s}"
        end
        arr
      end.join('&')
      # fix for /about API
      if path.start_with? '/about/'
        path = path.split("/").map{|x| CGI.escape x}.join("/")
      end
      if args != ''
        "#{@instance}#{path}?#{args}"
      else
        "#{@instance}#{path}"
      end
    end

    ##
    # Build the payload from the options hash
    def build_payload(options)
      payload = options.reject {|k,v| !([:body, :mime].include? k)}
      if payload[:mime]
        # user set mime-type, let them deal with it :)
        # fix for ruby 1.8
        if payload[:body].is_a? File
          payload[:size] = payload[:body].path.size
        else
          payload[:size] = payload[:body].size
        end
      elsif payload[:body].is_a? Hash
        payload[:body] = Yajl.dump payload[:body]
        payload[:mime] = "application/json"
      elsif SERIALIZEABLE_TYPES.include? payload[:body].class
        if ITERABLE_TYPES.include? payload[:body].class
          if is_set_of_strings? payload[:body]
            # set of strings is primitive
            payload[:mime] = "application/vnd.fluiddb.value+json"
          else
            # we have an Array with some non-String items
            payload[:mime] = "application/json"
          end
        else
          # primitive type
          payload[:mime] = "application/vnd.fluiddb.value+json"
        end
        payload[:body] = Yajl.dump payload[:body]
      else
        raise TypeError, "You must supply the mime-type"
      end
      payload
    end
    
    ##
    # Check if payload is a "set of strings"
    def is_set_of_strings?(list)
      # are all elements unique strings?
      list.all? { |x| x.is_a? String } && list == list.uniq
    end
  end

  def self.version
    # This was borrowed from the rest-client gem :)
    version_path = File.dirname(__FILE__) + "/../../VERSION"
    return File.read(version_path).chomp if File.file?(version_path)
    "0.0.0"
  end

end

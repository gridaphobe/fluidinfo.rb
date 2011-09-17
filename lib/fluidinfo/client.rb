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
  # The main fluidinfo instance.
  MAIN = 'https://fluiddb.fluidinfo.com'

  class Client
    def initialize(options={})
      base_url = options[:instance] || Fluidinfo::MAIN
      headers = {
        :accept => "*/*",
        :user_agent => "fluidinfo.rb/#{Fluidinfo.version}"
      }
      @client = RestClient::Resource.new base_url, :user => options[:user],
                                                   :password => options[:password],
                                                   :headers => headers
    end

    ##
    # Call GET on one of the APIs
    #
    # +options+ contains URI arguments that will be appended to +path+
    # consult the {Fluidinfo API documentation}[api.fluidinfo.com] for a list of
    # appropriate options
    def get(path, options={})
      url = build_url path, options
      headers = options[:headers] || {}
      Response.new(@client[url].get headers)
    end

    ##
    # Call HEAD on the /about or /object API to test for the existence
    # of a tag
    def head(path, options={})
      url = build_url path, options
      headers = options[:headers] || {}
      Response.new(@client[url].head headers)
    end

    ##
    # Call POST on one of the APIs
    #
    # +options[:body]+ contains the request payload. For some API
    # calls this may be empty.
    def post(path, options={})
      url = build_url path, options
      body = options[:body]
      headers = options[:headers] || {}
      if body
        # the body for a POST will always be app/json, so no need
        # to waste cycles in build_payload
        body = Yajl.dump body
        headers.merge! :content_type => "application/json"
      end
      Response.new(@client[url].post body, headers)
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
      body, mime = build_payload options
      headers = (options[:headers] || {}).merge :content_type => mime
                                               # :content_length => size
      Response.new(@client[url].put body, headers)
    end

    ##
    # Call DELETE on one of the APIs
    #
    # +options+ contains URI arguments that will be appended to +path+
    # consult the {Fluidinfo API documentation}[api.fluidinfo.com] for a list 
    # of appropriate options
    def delete(path, options={})
      url = build_url path, options
      headers = options[:headers] || {}
      # nothing returned in response body for DELETE
      Response.new(@client[url].delete headers)
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
        "#{path}?#{args}"
      else
        "#{path}"
      end
    end

    ##
    # Build the payload from the options hash
    def build_payload(options)
      body = options[:body]
      mime = options[:mime]
      if mime
        # user set mime-type, let them deal with it :)
        # fix for ruby 1.8
        if body.is_a? File
          size = body.path.size
        else
          size = body.size
        end
      elsif body.is_a? Hash
        body = Yajl.dump body
        mime = "application/json"
      elsif SERIALIZEABLE_TYPES.include? body.class
        if ITERABLE_TYPES.include? body.class
          if is_set_of_strings? body
            # set of strings is primitive
            mime = "application/vnd.fluiddb.value+json"
          else
            # we have an Array with some non-String items
            mime = "application/json"
          end
        else
          # primitive type
          mime = "application/vnd.fluiddb.value+json"
        end
        body = Yajl.dump body
      else
        raise TypeError, "You must supply the mime-type"
      end
      [body, mime]
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

require "rest-client"
require "cgi"
require "uri"
require "yajl"
require "base64"

module Fluidinfo

  ##
  # {Fluidinfo::Client} handles all of the communication between your
  # application and Fluidinfo. You should create a new
  # {Fluidinfo::Client} anytime you want to begin making calls as a
  # different user. All {Fluidinfo::Client} methods return an instance
  # of {Fluidinfo::Response}.
  #
  # Example Usage:
  #     # start with anonymous calls
  #     fi = Fluidinfo::Client.new
  #     fi.get "/values", :query => "has terry/rating > 4 and eric/seen",
  #                       :tags  => ["imdb.com/title", "amazon.com/price"]
  #     # now log in
  #     fi = Fluidinfo::Client.new :user => "user", :password => "password"
  #     fi.put "/about/Inception/user/comment", :body => "Awesome!"
  class Client

    ##
    # Create a new instance of {Fluidinfo::Client}.
    #
    # @param [Hash] options Initialization options.
    #
    # @option options [String] :user The username to use for
    #   authentication.
    # @option options [String] :password The password to use for
    #   authentication.
    # @option options [Hash] :headers Additional headers to send with
    #   every API call made via this client.
    def initialize(options={})
      base_url = options[:instance] || Fluidinfo::MAIN
      headers = {
        :accept => "*/*",
        :user_agent => "fluidinfo.rb/#{Fluidinfo.version}"
      }.merge(options[:headers] || {})
      @client = RestClient::Resource.new base_url, :user => options[:user],
                                                   :password => options[:password],
                                                   :headers => headers
    end

    ##
    # Call GET on one of the APIs.
    #
    # @param [String] path The path segment of the API call.
    # @param [Hash] options Additional arguments for the GET call.
    #
    # @option options [Hash] :headers Additional headers to send.
    # @option options [String] :query A Fluidinfo query for objects, only used in
    #   +/objects+ and +/values+.
    # @option options [Array] :tags Tags to be deleted, only used in +/values+.
    def get(path, options={})
      url = build_url path, options
      headers = options[:headers] || {}
      Response.new(@client[url].get headers)
    end

    ##
    # Call HEAD on one of the APIs. Only used to check for the
    # existence of a tag using +/about+ or +/objects+.
    #
    # @param [String] path The path segment of the API call.
    # @param [Hash] options Additional arguments for the GET call.
    #
    # @option options [Hash] :headers Additional headers to send.
    def head(path, options={})
      url = build_url path, options
      headers = options[:headers] || {}
      Response.new(@client[url].head headers)
    end

    ##
    # Call POST on one of the APIs.
    #
    # @param [String] path The path segment of the API call.
    # @param [Hash] options Additional arguments for the POST call.
    #
    # @option options [Hash] :headers Additional headers to send.
    # @option options [Hash] :body The payload to send.
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
    # Call PUT on one of the APIs.
    #
    # @param [String] path The path segment of the API call.
    # @param [Hash] options Additional arguments for the PUT call.
    #
    # @option options [Hash] :headers Additional headers to send.
    # @option options [Hash, other] :body The payload to send. Type
    #   should be +Hash+ unless sending a tag-value.
    # @option options [String] :mime The mime-type of an opaque tag-value.
    def put(path, options={})
      url = build_url path, options
      body, mime = build_payload options
      headers = (options[:headers] || {}).merge :content_type => mime
      Response.new(@client[url].put body, headers)
    end

    ##
    # Call DELETE on one of the APIs.
    #
    # @param [String] path The path segment of the API call.
    # @param [Hash] options Additional arguments for the DELETE call.
    #
    # @option options [Hash] :headers Additional headers to send.
    # @option options [String] :query A Fluidinfo query for objects, only used in
    #   +/values+.
    # @option options [Array] :tags Tags to be deleted, only used in +/values+.
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
        # path components need to be escaped with URI.escape instead
        # of CGI.escape so " " is translated properly to "%20"
        path = path.split("/").map{|x| URI.escape x}.join("/")
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

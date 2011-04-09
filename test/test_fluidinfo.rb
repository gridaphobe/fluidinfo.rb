require 'helper'
require 'uuidtools'

class FluidinfoTest < Test::Unit::TestCase
  context "GET" do
    setup do
      @fluid = Fluidinfo::Client.new
    end

    context "/objects" do
      should "retrieve tags correctly" do
        uid = "e034d8c0-a2e4-4094-895b-3a8065f9696e"
        tag = "gridaphobe/given-name"
        assert_equal "Eric", @fluid.get("/objects/#{uid}/#{tag}")
      end

      should "process queries correctly" do
        query = 'fluiddb/users/username = "gridaphobe"'
        expected = {
          "ids" => ["e034d8c0-a2e4-4094-895b-3a8065f9696e"]
        }
        assert_equal expected, @fluid.get("/objects", :query => query)
      end

      should "retrieve objects with about tag" do
        uid = "206b5ca5-cd69-469a-9aba-44b28cfb455e"
        expected = {
          "about"=>nil,
          "tagPaths"=>["gridaphobe/test/test_tag"]
        }
        assert_equal expected, @fluid.get("/objects/#{uid}", :showAbout => true)
      end
      
      should "retrieve objects without about tag" do
        uid = "206b5ca5-cd69-469a-9aba-44b28cfb455e"
        expected = {
          "tagPaths"=>["gridaphobe/test/test_tag"]
        }
        assert_equal expected, @fluid.get("/objects/#{uid}")
      end
      
      should "raise 404 errors on bad request" do
        uid = "1"
        tag = "gridaphobe/given-name"
        assert_raise RestClient::ResourceNotFound do
          @fluid.get "/objects/#{uid}/#{tag}"
        end
      end
    end

    context "/namespaces" do
      should "show basic information about namespaces" do
        user = "gridaphobe"
        ns   = "test"
        expected = {
          "id"             =>"9c16dcbe-87fd-4fe9-ae0e-699be84f1105"
        }
        assert_equal expected, @fluid.get("/namespaces/#{user}/#{ns}")
      end

      should "show detailed information about namespaces" do
        user = "gridaphobe"
        ns   = "test"
        expected = {
          "tagNames"       => ["test_tag"],
          "namespaceNames" => ["sub_ns"],
          "id"             =>"9c16dcbe-87fd-4fe9-ae0e-699be84f1105",
          "description"    =>"test"
        }
        assert_equal expected, @fluid.get("/namespaces/#{user}/#{ns}",
                                          :returnDescription => true,
                                          :returnTags => true,
                                          :returnNamespaces => true)
      end
    end
    
    context "/values" do
      should "retrieve a set of tags" do
        expected = {
          "results" => {
            "id"      => {
              "e034d8c0-a2e4-4094-895b-3a8065f9696e" => {
                "fluiddb/users/username" => { "value" => "gridaphobe" },
                "fluiddb/about" => { "value" => "Object for the user named gridaphobe"}
              }
            }
          }
        }
        assert_equal expected, @fluid.get("/values",
                              :query => 'fluiddb/users/username="gridaphobe"',
                              :tags => ['fluiddb/users/username', 'fluiddb/about'])
      end
    end
  end

  context "POST" do
    setup do
      @fluid = Fluidinfo::Client.new :sandbox
      @fluid.login 'test', 'test'
    end

    context "/namespaces" do
      should "create new namespaces" do
        new_ns = UUIDTools::UUID.random_create
        body = {
          'description' => 'a test namespace',
          'name'        => new_ns
        }
        resp = @fluid.post "/namespaces/test", :body => body
        # assert_equal 201, resp.code
        assert_not_nil resp["id"]
        
        # now cleanup
        @fluid.delete "/namespaces/test/#{new_ns}"
      end
    end
  end

  context "PUT" do
    setup do
      @fluid = Fluidinfo::Client.new :sandbox
      @fluid.login 'test', 'test'
    end

    context "/tags" do
      should "update primitive tag values" do
        new_ns = UUIDTools::UUID.random_create
        ns_body = {
          'description' => 'a test namespace',
          'name' => new_ns
        }
        resp = @fluid.post '/namespaces/test', :body => ns_body
        assert_not_nil resp["id"]
        ns_id = resp["id"]      # for later use

        new_tag = UUIDTools::UUID.random_create
        tag_body = {
          'description' => 'a test tag',
          'name' => new_tag,
          'indexed' => false
        }
        resp = @fluid.post "/tags/test/#{new_ns}", :body => tag_body
        assert_not_nil resp["id"]
        path = "/objects/#{ns_id}/test/#{new_ns}/#{new_tag}"
        # Make sure that all primitive values are properly encoded and
        # sent to Fluidinfo
        primitives = [1, 1.1, "foo", true, nil, [1, '2', 3]]
        primitives.each do |p|
          resp = @fluid.put(path, :body => p)
          assert_equal p, @fluid.get(path)
        end

        # now cleanup
        response = @fluid.delete "/tags/test/#{new_ns}/#{new_tag}"
        assert_equal 204, response.code
      
        response = @fluid.delete "/namespaces/test/#{new_ns}"
        assert_equal 204, response.code
      end

      should "update opaque tag values" do
        new_ns = UUIDTools::UUID.random_create
        ns_body = {
          'description' => 'a test namespace',
          'name' => new_ns
        }
        resp = @fluid.post '/namespaces/test', :body => ns_body
        assert_not_nil resp["id"]
        ns_id = resp["id"]      # for later use

        new_tag = UUIDTools::UUID.random_create
        tag_body = {
          'description' => 'a test tag',
          'name' => new_tag,
          'indexed' => false
        }
        resp = @fluid.post "/tags/test/#{new_ns}", :body => tag_body
        file = File.new(__FILE__)
        path = "/objects/#{ns_id}/test/#{new_ns}/#{new_tag}"
        resp = @fluid.put path, :body => file, :mime => "text/ruby"
        assert_equal File.new(__FILE__).read, @fluid.get(path)

        # now cleanup
        @fluid.delete "/tags/test/#{new_ns}/#{new_tag}"
        @fluid.delete "/namespaces/test/#{new_ns}"
      end

      should "raise TypeError on malformed request" do
        file = File.new(__FILE__)
        assert_raise TypeError do
          @fluid.put("/objects", :body => file)
        end
      end
    end
  end
  
  context "private functions" do
    setup do
      @fluid = Fluidinfo::Client.new
      def @fluid.test_build_payload(*args)
        build_payload(*args)
      end
    end
    
    context "build_payload" do
      should "set proper mime-types" do
        primitives = [1, 1.1, true, false, nil, ["1", "2", "hi"]]
        primitives.each do |p|
          h = @fluid.test_build_payload :body => p
          assert_equal "application/vnd.fluiddb.value+json", h[:mime]
        end
        
        non_primitives = [[1, 2, 3], {"hi" => "there"}]
        non_primitives.each do |n|
          h = @fluid.test_build_payload :body => n
          assert_equal "application/json", h[:mime]
        end
      end
    end
  end
end

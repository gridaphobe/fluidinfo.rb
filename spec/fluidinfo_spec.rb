require "fluidinfo"
require "uuidtools"

describe Fluidinfo do
  describe "GET" do
    before(:each) do
      @fluid = Fluidinfo::Client.new
    end

    it "should return a Fluidinfo::Response" do
      r = @fluid.get("/about/fluidinfo")
      r.should be_a(Fluidinfo::Response)
      r.should respond_to(:status, :content, :headers, :value, :error)
    end

    describe "/objects" do
      it "should retrieve tags correctly" do
        uid = "e034d8c0-a2e4-4094-895b-3a8065f9696e"
        tag = "fluiddb/users/username"
        @fluid.get("/objects/#{uid}/#{tag}").value.should eq("gridaphobe")
      end

      it "should process queries correctly" do
        query = 'fluiddb/users/username = "gridaphobe"'
        expected = {
          "ids" => ["e034d8c0-a2e4-4094-895b-3a8065f9696e"]
        }
        @fluid.get("/objects", :query => query).value.should eq(expected)
      end

      it "should retrieve objects with about tag" do
        uid = "206b5ca5-cd69-469a-9aba-44b28cfb455e"
        expected = {
          "about"=>nil,
          "tagPaths"=>["gridaphobe/test/test_tag"]
        }
        @fluid.get("/objects/#{uid}",
                   :showAbout => true).value.should eq(expected)
      end

      it "should retrieve objects without about tag" do
        uid = "206b5ca5-cd69-469a-9aba-44b28cfb455e"
        expected = {
          "tagPaths"=>["gridaphobe/test/test_tag"]
        }
        @fluid.get("/objects/#{uid}").value.should eq(expected)
      end

      it "should contain an error message for failed requests" do
        r = @fluid.get "/about/1/gridaphobe/given-name"
        r.status.should eq(404)
        r.error.should eq("TNoInstanceOnObject")
      end
    end

    describe "/namespaces" do
      it "should show basic information about namespaces" do
        user = "gridaphobe"
        ns   = "test"
        expected = {
          "id"             =>"9c16dcbe-87fd-4fe9-ae0e-699be84f1105"
        }
        @fluid.get("/namespaces/#{user}/#{ns}").value.should eq(expected)
      end

      it "should show detailed information about namespaces" do
        user = "gridaphobe"
        ns   = "test"
        expected = {
          "tagNames"       => ["test_tag"],
          "namespaceNames" => ["sub_ns"],
          "id"             =>"9c16dcbe-87fd-4fe9-ae0e-699be84f1105",
          "description"    =>"test"
        }
        @fluid.get("/namespaces/#{user}/#{ns}",
                   :returnDescription => true,
                   :returnTags => true,
                   :returnNamespaces => true).value.should eq(expected)
      end
    end

    describe "/values" do
      it "should retrieve a set of tags" do
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
        @fluid.get("/values",
                   :query => 'fluiddb/users/username="gridaphobe"',
                   :tags => ['fluiddb/users/username',
                             'fluiddb/about']).value.should eq(expected)
      end
    end
  end

  describe "POST" do
    before(:each) do
      @fluid = Fluidinfo::Client.new :user => "test", :password => "test"
    end

    it "should return a Fluidinfo::Response" do
      r = @fluid.post("/objects")
      r.should be_a(Fluidinfo::Response)
      r.should respond_to(:status, :content, :headers, :value, :error)
    end

    describe "/namespaces" do
      it "should create new namespaces" do
        new_ns = UUIDTools::UUID.random_create
        body = {
          'description' => 'a test namespace',
          'name'        => new_ns
        }
        r = @fluid.post "/namespaces/test", :body => body
        r.status.should eq(201)
        r["id"].should_not be_nil

        # now cleanup
        @fluid.delete "/namespaces/test/#{new_ns}"
      end
    end
  end

  describe "PUT" do
    before(:each) do
      @fluid = Fluidinfo::Client.new :user => "test", :password => "test"
    end

    it "should return a Fluidinfo::Response" do
      r = @fluid.put("/about/fluidinfo/test/tag", :body => nil)
      r.should be_a(Fluidinfo::Response)
      r.should respond_to(:status, :content, :headers, :value, :error)
      @fluid.delete("/about/fluidinfo/test/tag")
    end

    describe "/tags" do
      it "should update primitive tag values" do
        new_ns = UUIDTools::UUID.random_create
        ns_body = {
          'description' => 'a test namespace',
          'name' => new_ns
        }
        r = @fluid.post '/namespaces/test', :body => ns_body
        r["id"].should_not be_nil

        ns_id = r["id"]      # for later use
        new_tag = UUIDTools::UUID.random_create
        tag_body = {
          'description' => 'a test tag',
          'name' => new_tag,
          'indexed' => false
        }
        r = @fluid.post "/tags/test/#{new_ns}", :body => tag_body
        r["id"].should_not be_nil

        path = "/objects/#{ns_id}/test/#{new_ns}/#{new_tag}"
        # Make sure that all primitive values are properly encoded and
        # sent to Fluidinfo
        primitives = [1, 1.1, "foo", true, nil, [1, '2', 3]]
        primitives.each do |p|
          @fluid.put(path, :body => p)
          @fluid.get(path).value.should eq(p)
        end

        # now cleanup
        r = @fluid.delete "/tags/test/#{new_ns}/#{new_tag}"
        r.status.should eq(204)

        r = @fluid.delete "/namespaces/test/#{new_ns}"
        r.status.should eq(204)
      end

      it "should update opaque tag values" do
        new_ns = UUIDTools::UUID.random_create
        ns_body = {
          'description' => 'a test namespace',
          'name' => new_ns
        }
        r = @fluid.post '/namespaces/test', :body => ns_body
        r["id"].should_not be_nil

        ns_id = r["id"]      # for later use
        new_tag = UUIDTools::UUID.random_create
        tag_body = {
          'description' => 'a test tag',
          'name' => new_tag,
          'indexed' => false
        }
        @fluid.post "/tags/test/#{new_ns}", :body => tag_body
        file = File.new(__FILE__).read
        path = "/objects/#{ns_id}/test/#{new_ns}/#{new_tag}"
        @fluid.put path, :body => file, :mime => "text/ruby"
        File.new(__FILE__).read.should eq(@fluid.get(path).value)

        # now cleanup
        @fluid.delete "/tags/test/#{new_ns}/#{new_tag}"
        @fluid.delete "/namespaces/test/#{new_ns}"
      end

      it "should raise TypeError on malformed request" do
        file = File.new(__FILE__)
        expect {@fluid.put "/objects", :body => file}.to raise_error(TypeError)
      end
    end
  end

  describe "private functions" do
    before(:each) do
      @fluid = Fluidinfo::Client.new
      def @fluid.test_build_payload(*args)
        build_payload(*args)
      end
      def @fluid.test_build_url(*args)
        build_url(*args)
      end
    end

    describe "build_url" do
      it "escapes &'s in query tag-values" do
        query = "test/tag=\"1&2\""
        expected = "/objects?query=test%2Ftag%3D%221%262%22"
        @fluid.test_build_url("/objects", :query => query).should eq(expected)

        query = "oreilly.com/title=\"HTML & CSS: The Good Parts\""
        tags = ["oreilly.com/isbn"]
        expected = "/values?query=oreilly.com%2Ftitle%3D%22HTML+%26+CSS%3A+The+Good+Parts%22&tag=oreilly.com/isbn"
        @fluid.test_build_url("/values",
                              :query => query,
                              :tags => tags).should eq(expected)
      end

      it "escapes &'s in about-values" do
        about = "tom & jerry"
        expected = "/about/tom%20&%20jerry"
        @fluid.test_build_url('/about/tom & jerry').should eq(expected)
      end
    end

    describe "build_payload" do
      it "sets proper mime-types" do
        primitives = [1, 1.1, true, false, nil, ["1", "2", "hi"]]
        primitives.each do |p|
          body, mime = @fluid.test_build_payload :body => p
          mime.should eq("application/vnd.fluiddb.value+json")
        end

        non_primitives = [[1, 2, 3], {"hi" => "there"}]
        non_primitives.each do |n|
          body, mime = @fluid.test_build_payload :body => n
          mime.should eq("application/json")
        end
      end
    end
  end
end

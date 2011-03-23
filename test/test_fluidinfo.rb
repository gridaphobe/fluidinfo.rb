require 'helper'

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
  end
end

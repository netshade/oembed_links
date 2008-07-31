require File.join(File.dirname(__FILE__), "spec_helper")

describe OEmbed, "registration tasks" do
  include SpecHelper
  
  before(:each) do
    OEmbed.clear_registrations
    clear_urls
  end

  it "should default to NetHTTP if no method is specified in configuration" do
    OEmbed.register()
    OEmbed.instance_variable_get("@fetch_method").should == "NetHTTP"
  end
  
  it "should throw an error if you provide provider URLs but no scheme or format information" do
    lambda { OEmbed.register({ }, { :fake => "http://fake" })}.should raise_error
  end

  it "should throw an error if you don't provide any scheme urls for registration" do
    lambda { OEmbed.register({ }, { :fake => "http://fake" }, { :fake => { :format => "json", :schemes => []}})}.should raise_error
  end

  it "should default to json format if none is specified" do
    OEmbed.register({ }, { :fake => "http://fake" }, { :fake => { :schemes => ["http://fake/*"]}})
    OEmbed.instance_variable_get("@formats")[:fake].should == "json"
  end

  it "should support loading a configuration via YAML" do
    OEmbed.register_yaml_file(File.join(File.dirname(__FILE__), "oembed_links_test.yml"))
    OEmbed.instance_variable_get("@urls").size.should == 3
  end

  it "should support ad hoc addition of providers" do
    OEmbed.register_yaml_file(File.join(File.dirname(__FILE__), "oembed_links_test.yml"))
    OEmbed.instance_variable_get("@urls").size.should == 3
    OEmbed.register_provider(:test4, "http://test4/oembed.{format}", "xml", "http://test4.*/*", "http://test4.*/foo/*")
    OEmbed.instance_variable_get("@urls").size.should == 4
  end

  it "should support adding new fetchers" do
    
    OEmbed.register_fetcher(FakeFetcher)
    OEmbed.register({ :method => "fake_fetcher"},
                    { :fake => "http://fake" },
                    { :fake => {
                        :format => "json",
                        :schemes => "http://fake/*"
                      }})
    OEmbed.transform("http://fake/bar/baz").should == "fakecontent"
  end
  
  it "should support adding new formatters" do
    OEmbed.register_formatter(FakeFormatter)
    OEmbed.register({ :method => "fake_fetcher"},
                    { :fake => "http://fake" },
                    { :fake => {
                        :format => "fake_formatter",
                        :schemes => "http://fake/*"
                      }})
    url_provides("")    
    OEmbed.transform("http://fake/bar/baz").should == "http://fakesville"
  end

end

describe OEmbed, "transforming functions" do
  include SpecHelper
  before(:each) do
    OEmbed.clear_registrations
    clear_urls
    url_provides({
     "html" => "foo",
     "type" => "video"
    }.to_json)
    OEmbed.register_yaml_file(File.join(File.dirname(__FILE__), "oembed_links_test.yml"))
  end

  it "should always give priority to provider conditional blocks" do
    OEmbed.transform("http://test1.net/foo") do |r|
      r.any? { |a| "any" }
      r.video? { |v| "video" }
      r.from?(:test1) { |t| "test1" }
      r.matches?(/./) { |m| "regex" }
    end.should == "test1"
  end

  it "should always give priority regex conditional blocks over all others except provider" do
    OEmbed.transform("http://test1.net/foo") do |r|
      r.any? { |a| "any" }
      r.video? { |v| "video" }
      r.matches?(/./) { |m| "regex" }
    end.should == "regex"
    OEmbed.transform("http://test1.net/foo") do |r|
      r.matches?(/./) { |m| "regex" }
      r.any? { |a| "any" }
      r.video? { |v| "video" }      
    end.should == "regex"
  end

  it "should recognize the type of content and handle the conditional block appropriately" do
    OEmbed.transform("http://test1.net/foo") do |r|
      r.any? { |a| "any" }
      r.video? { |v| "video" }
    end.should == "video"
    url_provides({
     "html" => "bar",
     "type" => "hedgehog"
    }.to_json)
    OEmbed.transform("http://test1.net/foo") do |r|
      r.video? { |v| "video" }
      r.hedgehog? { |v| "hedgey"}
    end.should == "hedgey"    
  end

  it "should still output the content of a url if no transforming blocks match it" do
    OEmbed.transform("http://test1.net/foo") do |r|
      r.audio? { |a| "audio" }
      r.hedgehog? { |v| "hedgey"}
      r.from?(:test2) { |t| "test2" }
      r.matches?(/baz/) { |m| "regex" }
    end.should == "foo" 
  end
  
  
end



require File.join(File.dirname(__FILE__), "spec_helper")

describe OEmbed, "registration tasks" do
  include SpecHelper
  
  before(:each) do
    OEmbed.clear_registrations
    OEmbed.load_default_libs
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

  it "should allow selective loading of formatters through the load_default_libs function" do
    OEmbed.clear_registrations
    OEmbed.load_default_libs
    OEmbed.instance_variable_get("@formatters")["xml"].class.should == OEmbed::Formatters::LibXML
    OEmbed.clear_registrations
    OEmbed.load_default_libs("libxml")
    OEmbed.instance_variable_get("@formatters")["xml"].class.should == OEmbed::Formatters::HpricotXML
    OEmbed.clear_registrations
    OEmbed.load_default_libs("libxml", "hpricot")
    OEmbed.instance_variable_get("@formatters")["xml"].class.should == OEmbed::Formatters::RubyXML    
  end

  it "should support the hpricot formatter" do
    OEmbed.clear_registrations
    OEmbed.load_default_libs("libxml")
    url_provides(<<-EOXML)
<?xml version="1.0"?>
<oembed>
  <html>bar</html>
</oembed>
    EOXML
    OEmbed.register_provider(:test, "http://test4/oembed.{format}", "xml", "http://test.*/*")
    OEmbed.transform("http://test.com/bar/baz").should == "bar"
  end

  it "should support the rexml formatter" do
    OEmbed.clear_registrations
    OEmbed.load_default_libs("libxml", "hpricot")
    url_provides(<<-EOXML)
<?xml version="1.0"?>
<oembed>
  <html>barxml</html>
</oembed>
    EOXML
    OEmbed.register_provider(:test, "http://test4/oembed.{format}", "xml", "http://test.*/*")
    OEmbed.transform("http://test.com/bar/baz").should == "barxml"
  end  

  

end

describe OEmbed, "transforming functions" do
  include SpecHelper
  before(:each) do
    OEmbed.clear_registrations
    OEmbed.load_default_libs
    clear_urls
    url_provides({
     "html" => "foo",
     "type" => "video"
    }.to_json)
    OEmbed.register_yaml_file(File.join(File.dirname(__FILE__), "oembed_links_test.yml"))
    @current_path = File.dirname(__FILE__)
    @template_path = File.join(@current_path, "templates")
  end

  it "should always give priority to provider conditional blocks" do
    OEmbed.transform("http://test1.net/foo") do |r, url|
      r.none? { "none" }
      r.any? { |a| "any" }
      r.video? { |v| "video" }
      r.from?(:test1) { |t| "test1" }
      r.matches?(/./) { |m| "regex" }
    end.should == "test1"
  end

  it "should always give priority regex conditional blocks over all others except provider" do
    OEmbed.transform("http://test1.net/foo") do |r, url|
      r.none? { "none" }      
      r.any? { |a| "any" }
      r.video? { |v| "video" }
      r.matches?(/./) { |m| "regex" }
    end.should == "regex"
    OEmbed.transform("http://test1.net/foo") do |r, url|
      r.matches?(/./) { |m| "regex" }
      r.any? { |a| "any" }
      r.video? { |v| "video" }      
    end.should == "regex"
  end

  it "should recognize the type of content and handle the conditional block appropriately" do
    OEmbed.transform("http://test1.net/foo") do |r, url|
      r.none? { "none" }      
      r.any? { |a| "any" }
      r.video? { |v| "video" }
    end.should == "video"
    url_provides({
     "html" => "bar",
     "type" => "hedgehog"
    }.to_json)
    OEmbed.transform("http://test1.net/foo") do |r, url|
      r.video? { |v| "video" }
      r.hedgehog? { |v| "hedgey"}
    end.should == "hedgey"    
  end

  it "should still output the content of a url if no transforming blocks match it" do
    OEmbed.transform("http://test1.net/foo") do |r, url|
      r.audio? { |a| "audio" }
      r.hedgehog? { |v| "hedgey"}
      r.from?(:test2) { |t| "test2" }
      r.matches?(/baz/) { |m| "regex" }
    end.should == "http://test1.net/foo" 
  end

  it "should transform only urls which have registered providers" do
    OEmbed.transform("http://test1.net/foo and http://not.a.valid.url.host/fake are urls") do |r, url|
      r.video? { |v| "video" }
    end.should == "video and http://not.a.valid.url.host/fake are urls"    
  end

  it "should pass control to the .none? block if no scheme matched" do
    OEmbed.transform("http://not.a.valid.url.host/fake") do |r, url|
      r.none? { "nomatch" }
      r.audio? { |a| "audio" }
      r.hedgehog? { |v| "hedgey"}
      r.from?(:test2) { |t| "test2" }
      r.matches?(/baz/) { |m| "regex" }
    end.should == "nomatch" 
  end

  it "should allow templates to be used to process the output" do
    url_provides({
     "url" => "template!"
                 }.to_json)
    
    OEmbed.transform("http://test1.net/foo") do |r, url|
      r.any?(:template => File.join(@template_path, "test.rhtml"))
    end.should == "template! rhtml"
  end


  it "should allow a template root to be set programmatically to process the output" do
    url_provides({
                   "url" => "template!"
                 }.to_json)
    OEmbed::TemplateResolver.template_root = @template_path
    OEmbed.transform("http://test1.net/foo") do |r, url|
      r.any?(:template => "test.html.erb")
    end.should == "template! erb"
  end

  it "should allow for selection of different template renderers" do
    url_provides({
                   "url" => "template!"
                 }.to_json)
    defined?(Erubis).should_not == true
    defined?(Haml).should_not == true
    OEmbed::TemplateResolver.template_root = @template_path    
    OEmbed::TemplateResolver.template_processor = :erubis
    OEmbed.transform("http://test1.net/foo") do |r, url|
      r.any?(:template => "test.html.erb")
    end.should == "template! erb"    
    defined?(Erubis).should == "constant"
    OEmbed::TemplateResolver.template_processor = :haml
    OEmbed.transform("http://test1.net/foo") do |r, url|
      r.any?(:template => "test.haml")
    end.should == "template! haml"
    defined?(Haml).should == "constant"
  end

  it "should throw an exception if a path to a template specified does not exist" do
    url_provides({
                   "url" => "template!"
                 }.to_json)
    lambda { OEmbed.transform("http://test1.net/foo") do |r, url|
      r.any?(:template => "does.not.exist")
      end }.should raise_error
  end
  
  
end


describe OEmbed, "Rails template resolving functions" do
  include SpecHelper
  before(:each) do
    OEmbed.clear_registrations
    OEmbed.load_default_libs    
    clear_urls
    url_provides({
     "html" => "foo",
                   "type" => "video",
                   "url" => "rails"
    }.to_json)
    OEmbed.register_yaml_file(File.join(File.dirname(__FILE__), "oembed_links_test.yml"))
    OEmbed::TemplateResolver.template_processor = nil
    @current_path = File.dirname(__FILE__)
    @template_path = File.join(@current_path, "templates")

    require 'actionpack'
    require 'action_controller'
    require 'action_controller/test_process'

    class ::ApplicationController < ActionController::Base
      
    end
    ApplicationController.view_paths += [File.dirname(__FILE__)]
    ActiveSupport::Dependencies.mark_for_unload(ApplicationController)
  end

  it "should support Rails-like template paths for template selection" do

    OEmbed.transform("http://test1.net/foo") do |r, url|
      r.any?(:template => ("templates/test"))
    end.should == "rails erb"
  end

  it "should support Rails-like template paths with extension specified" do
    OEmbed.transform("http://test1.net/foo") do |r, url|
      r.any?(:template => "templates/test.rhtml")
    end.should == "rails rhtml"
  end
  
end






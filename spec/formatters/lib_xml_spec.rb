require File.join(File.dirname(__FILE__), "../spec_helper")
require File.join(File.dirname(__FILE__), "../../lib/oembed_links/formatters/lib_xml.rb")

describe OEmbed::Formatters::LibXML do

  describe "raw xml from youtube" do
    before(:each) do
      @youtube_xml = File.open(
        File.join(File.dirname(__FILE__), "example_xml/youtube.xml"),
        "rb"
      ).read
      @result = OEmbed::Formatters::LibXML.new.format(@youtube_xml)
    end

    it "parsed raw xml should contain some html" do
      @result["html"].empty?.should_not be_true
    end
  end

  describe "raw xml from flickr" do
    before(:each) do
      @flickr_xml = File.open(
        File.join(File.dirname(__FILE__), "example_xml/flickr.xml"),
        "rb"
      ).read
      @result = OEmbed::Formatters::LibXML.new.format(@flickr_xml)
    end

    it "parsed raw xml should contain a url" do
      @result["url"].should == "http://farm4.static.flickr.com/3040/2362225867_4a87ab8baf.jpg"
    end
  end

  describe "raw xml from viddler" do
    before(:each) do
      @viddler_xml = File.open(
        File.join(File.dirname(__FILE__), "example_xml/viddler.xml"),
        "rb"
      ).read
      @result = OEmbed::Formatters::LibXML.new.format(@viddler_xml)
    end

    it "parsed raw xml should contain some html" do
      @result["html"].empty?.should_not be_true
    end
  end

  describe "raw xml from hulu" do
    before(:each) do
      @hulu_xml = File.open(
        File.join(File.dirname(__FILE__), "example_xml/hulu.xml"),
        "rb"
      ).read
      @result = OEmbed::Formatters::LibXML.new.format(@hulu_xml)
    end

    it "parsed raw xml should contain some html" do
      @result["html"].empty?.should_not be_true
    end
  end

end # Oembed

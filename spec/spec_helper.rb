$: << File.join(File.dirname(__FILE__), "..", "lib")
require 'oembed_links'

module SpecHelper
  
  def url_provides(content)
    Net::HTTP.fake_content(content)
  end

  def clear_urls
    Net::HTTP.clear_fakes
  end
  
end

require 'net/http'
module Net
  class HTTP
    
    def self.fake_content(content)
      @content = content
    end
    

    def self.clear_fakes
      @content = nil
    end
    
    def self.get(uri)
      return @content
    end
    
  end
end


require 'json'
class FakeFetcher
  def name
    "fake_fetcher"
  end

  def fetch(url)
    {
      "url" => "fakecontent"
    }.to_json
  end
end

class FakeFormatter
  def name
    "fake_formatter"
  end

  def format(txt)
    {
      "url" => "http://fakesville"
    }
  end
end



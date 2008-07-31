require 'net/http'

class OEmbed
  module Fetchers
    class NetHTTP
      
      def name
        "NetHTTP"
      end

      def fetch(url)
        Net::HTTP.get(URI.parse(url))
      end
      
    end
  end
end

OEmbed.register_fetcher(OEmbed::Fetchers::NetHTTP)

require 'curb'

class OEmbed
  module Fetchers
    class Curb

      def initialize
      end
      
      def name
        "Curb"
      end

      def fetch(url)
        Curl::Easy.perform(url).body_str
      end
      
    end
  end
end

OEmbed.register_fetcher(OEmbed::Fetchers::Curb)

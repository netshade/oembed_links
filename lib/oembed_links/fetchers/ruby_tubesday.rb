require 'ruby_tubesday'

class OEmbed
  module Fetchers
    class RubyTubesday

      def initialize
        @client = ::RubyTubesday.new(:verify_ssl => false)
      end
      
      def name
        "RubyTubesday"
      end

      def fetch(url)
        @client.get(url)
      end
      
    end
  end
end

OEmbed.register_fetcher(OEmbed::Fetchers::RubyTubesday)

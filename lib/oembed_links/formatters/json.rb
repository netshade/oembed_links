require 'json'

class OEmbed
  module Formatters
    class JSON
      
      def name
        "json"
      end

      def format(txt)
        ::JSON.parse(txt)
      end
      
    end
  end
end
OEmbed.register_formatter(OEmbed::Formatters::JSON)

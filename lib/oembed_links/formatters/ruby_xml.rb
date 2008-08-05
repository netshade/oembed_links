require 'rexml/document'


class OEmbed
  module Formatters
    class RubyXML
      
      def name
        "xml"
      end

      # This is an extremely naive XML doc to hash
      # formatter.  Cases like arrays represented in
      # XML will not work; only strings, ints and
      # floats will be converted.
      def format(txt)
        doc = ::REXML::Document.new(txt)
        h = { }
        doc.elements.each("/oembed/*") do |elem|
          c = elem.text
          if c =~ /^[0-9]+$/
            c = c.to_i
          elsif c=~ /^[0-9]+\.[0-9]+$/
            c = c.to_f
          end
          h[elem.name.strip] = c
        end
        return h
      end
      
    end
  end
end


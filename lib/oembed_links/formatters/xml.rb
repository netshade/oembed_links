require 'libxml'

class OEmbed
  module Formatters
    class LibXML
      
      def name
        "xml"
      end

      # This is an extremely naive XML doc to hash
      # formatter.  Cases like arrays represented in
      # XML will not work; only strings, ints and
      # floats will be converted.
      def format(txt)
        parser = LibXML::XML::Parser.string(txt)
        doc = parser.parse
        h = { }
        doc.root.children.each do |node|
          unless node.name.strip.empty?
            c = node.content
            if c =~ /^[0-9]+$/
              c = c.to_i
            elsif c=~ /^[0-9]+\.[0-9]+$/
              c = c.to_f
            end
            h[node.name.strip] = c
          end
        end
        return h
      end
      
    end
  end
end
OEmbed.register_formatter(OEmbed::Formatters::LibXML)

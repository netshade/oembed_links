require 'hpricot'

class OEmbed
  module Formatters
    class HpricotXML
      
      def name
        "xml"
      end



      # This is an extremely naive XML doc to hash
      # formatter.  Cases like arrays represented in
      # XML will not work; only strings, ints and
      # floats will be converted.
      def format(txt)
        doc = ::Hpricot.XML(txt)
        h = { }
        (doc/"/oembed/*").each do |elem|
          if elem.is_a? Hpricot::Elem
            c = elem.innerHTML
            if c =~ /^[0-9]+$/
              c = c.to_i
            elsif c=~ /^[0-9]+\.[0-9]+$/
              c = c.to_f
            end
            h[elem.name.strip] = c
          end
        end
        return h
      end
      
    end
  end
end


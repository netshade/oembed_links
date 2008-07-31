# The class used to represent data returned by the server.
#
class OEmbed
  class Response

    def initialize(provider, url, response_object)
      @provider = provider
      @url = url
      @response = response_object
      @rendered_via_provider = @rendered_via_regex = @rendered_via_type = false
      @rendered = nil
    end

    def to_s
      @response["html"] || @response["url"]
    end

    # If no content has been explicitly rendered for this Response,
    # the default representation of the data will be returned.
    def rendered_content
      @rendered || self.to_s
    end

    # Test if this response has been returned from
    # the given provider_name.
    def from?(provider_name, &block)
      if @provider.to_s === provider_name.to_s
        if can_render_type?(:provider)
          @rendered_via_provider = true
          return render_content(&block)
        end
      end
    end

    # Test if this response came from a URL
    # that matches the given regex.
    def matches?(regex, &block)
      if @url =~ regex
        if can_render_type?(:regex)
          @rendered_via_regex = true
          render_content(&block)
        end
      end
    end

    # Lowest priority renderer, which will execute
    # a block regardless of conditions so long as
    # no content has yet been rendered for this response.
    def any?(&block)
      if can_render_type?
        return render_content(&block)
      end      
    end

    # Provides the mechanism to allow .audio?, .video?
    # and other .type? checking methods. The value of the
    # method name will be compared against the "type" field
    # from the returned server data.
    def method_missing(msym, *args, &block)
      mname = msym.to_s
      if mname[mname.size - 1, mname.size] == "?"
        ts = mname[0..mname.size - 2]
        if @response["type"] == ts
          if can_render_type?(:type)
            @rendered_via_type = true
            return render_content(&block)
          end
        end
      else
        raise NoMethodError.new("No such method #{msym.to_s}", msym, *args)
      end
    end

    private

    # Needlessly stupid priority for rendering.
    def can_render_type?(type = nil)
      if type == :provider
        !@rendered_via_provider 
      elsif type == :regex
        !@rendered_via_provider && !@rendered_via_regex
      elsif type == :type
        !@rendered_via_provider && !@rendered_via_regex && !@rendered_via_type
      else
        !has_rendered?
      end
    end

    def has_rendered?
      !@rendered.nil?
    end
    
    def render_content(&block)
      if block_given?
        @rendered = yield(@response)
      else
        @rendered = self.to_s
      end      
    end
    
  end
end

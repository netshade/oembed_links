# The class used to represent data returned by the server.
#

class OEmbed
  class Response

    def initialize(provider, url, response_object)
      @provider = provider
      @url = url
      @response = response_object || {}
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


    # Case where url has not matched at all
    def none?(*args, &block)
      if @response.keys.empty? && !has_rendered?
        return render_content(*args, &block)
      end
    end
    
    # Test if this response has been returned from
    # the given provider_name.
    def from?(provider_name, *args, &block)
      if @provider.to_s === provider_name.to_s
        if can_render_type?(:provider)
          @rendered_via_provider = true
          return render_content(*args, &block)
        end
      end
    end

    # Test if this response came from a URL
    # that matches the given regex.
    def matches?(regex, *args, &block)
      if @url =~ regex
        if can_render_type?(:regex)
          @rendered_via_regex = true
          render_content(*args, &block)
        end
      end
    end

    # Lowest priority renderer, which will execute
    # a block regardless of conditions so long as
    # no content has yet been rendered for this response.
    def any?(*args, &block)
      if can_render_type?
        return render_content(*args, &block)
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
            return render_content(*args, &block)
          end
        end
      else
        raise NoMethodError.new("No such method #{msym.to_s}", msym, *args)
      end
    end

    def has_rendered?
      !@rendered.nil?
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

    
    def render_content(*args, &block)
      options = (args.last.is_a?(Hash)) ? args.last : { }
      if options[:template]
        @rendered = TemplateResolver.eval_template_for_path(options[:template], @url, @response, self).strip
      elsif block_given?
        @rendered = yield(@response).strip
      else
        @rendered = self.to_s.strip
      end      
    end
    
  end
end

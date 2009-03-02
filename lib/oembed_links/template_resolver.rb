class OEmbed
  # The TemplateResolver class acts as a filesystem path resolver for finding
  # templates, as well as a template renderer.  Currently support is enabled for
  # Haml, Erubis, and ERB templates;  if you wish to force a particular type of processor
  # for any of the templates used, you may set it by specifing it with template_processor=
  # method.  You can specify a base path for resolving template names with the template_root=
  # method.
  class TemplateResolver

    # Specify the base filesystem path for resolving templates.
    def self.template_root=(r)
      @template_root = r
    end

    # Get the current base filesystem path, or nil
    def self.template_root
      @template_root
    end

    # Specify the template processor to use for rendering templates;
    # this will be used regardless of file extension 
    def self.template_processor=(p)
      p = p.to_s if p.is_a? Symbol
      raise "Unsupported processor type" unless ["erb", "haml", "erubis", nil].include?(p)
      @template_processor = p
    end

    # Return the current forced template processor, or nil
    def self.template_processor
      @template_processor 
    end

    # Resolves the template path for the given (potentially relative) path
    # If the given path is found to exist immediately, whether by itself
    # or when combined with the optionally present template_root (OEmbed::TemplateResolver.template_root),
    # it is returned immediately.  
    #
    # If no path is found for the supplied template path, an exception
    # is raised.
    def self.resolve_template_path(path)
      tmp_path = (@template_root) ? File.join(@template_root, path) : path
      found_path = nil
      if File.exists?(tmp_path)
        found_path = tmp_path
      end
      unless found_path
        raise StandardError.new("File not found: #{path}")
      else
        return found_path        
      end
    end

    # Evaluate the template at the given (possibly relative) path,
    # assigning the template the local variables url, data and response.
    # If ApplicationController and ActionController have been defined, then
    # it is assumed that you are specifying a Rails template path, and an instance
    # ApplicationController will be used to render the results.  You may use
    # Rails-style helpers / models inside your template, as the ActionView rendering
    # pipeline will be used.  NOTE that to accomplish this, the Rails TestRequest
    # and TestResponse classes will be loaded and used, if they have not been loaded already. 
    #
    # If no Rails style template was found or you are not using rails, the following actions take place:
    # If you specify a template processor (via OEmbed::TemplateResolver.template_processor=)
    # then it will be used to process the template at the given path (taking any configured template_root
    # into account.  Otherwise a processor will be selected on the following criterion:
    #
    # If the file extension is haml, then the Haml library will be required and used
    # If the Erubis library has been loaded or the file extension is erubis, the Erubis library will be used
    # In all other cases, the ERB library will be used
    #

    #
    # The evaluated result of the template will be returned.
    def self.eval_template_for_path(path, url, data, response)
      rendered_response = nil
      if defined?(ApplicationController) && defined?(ActionController)
        if !defined?(ActionController::TestRequest) ||
            !defined?(ActionController::TestResponse)
          require 'action_controller/test_process'          
        end
        @app_c ||= ApplicationController.new
        rendered_response = @app_c.process(ActionController::TestRequest.new,
                                           ActionController::TestResponse.new,
                                           :render_for_file,
                                           path,
                                           200,
                                           nil,
                                           { :data => data,
                                             :url => url,
                                             :response => response }).body
      end
      if rendered_response.nil? && actual_path = resolve_template_path(path)
        contents = File.read(actual_path)
        processor = (@template_processor || File.extname(actual_path)[1..4]).to_s
        has_erubis = defined?(Erubis)
        if processor == "haml"
          require 'haml' unless defined?(Haml)
          rendered_response = Haml::Engine.new(contents).render({ }, :data => data, :url => url, :response => response)
        elsif processor == "erubis" || has_erubis
          require 'erubis' unless has_erubis
          rendered_response = Erubis::Eruby.new(contents).result(:data => data, :url => url, :response => response)
        else
          require 'erb' unless defined?(ERB)
          rendered_response = ERBTemplate.new(url, data, response).evaluate(contents)
        end        
      end
      return rendered_response.chomp
    end

    private

    class ERBTemplate
      attr_reader :url, :data, :response

      def initialize(u, d, r)
        @url = u
        @data = d
        @response = r
      end

      
      def evaluate(contents)
        ERB.new(contents).result(binding)
      end
    end
    
  end
end

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
    # it is returned immediately.  Otherwise, a check is made to see if the
    # usual Rails classes (ActionView and ApplicationController) have been defined,
    # and if so, detect the Rails template path via the .view_paths class
    # method of ApplicationController.  Furthermore, Haml support is detected
    # by presence of a Haml template handler in the ActionView::Template
    # class, and if it's found, given default precedence over the other template forms.
    #
    # If no path is found for the supplied template path, an exception
    # is raised.
    def self.resolve_template_path(path)
      tmp_path = (@template_root) ? File.join(@template_root, path) : path
      found_path = nil
      if File.exists?(tmp_path)
        found_path = tmp_path
      else
        # Rails like templates
        if defined?(ApplicationController) && defined?(ActionView)
          exts = ["html.erb", "erb", "rhtml"]
          exts = (["haml"] + exts) if ActionView::Template.class_eval("@@template_handlers").keys.include?("haml")
          unless exts.any? { |e| path =~ /\.#{e}/ }
            for ext in exts
              if found_path = resolve_path_in_view_paths("#{path}.#{ext}", ApplicationController.view_paths)
                break
              end
            end
          end
          found_path ||= resolve_path_in_view_paths(path, ApplicationController.view_paths)

        end
      end
      unless found_path
        raise StandardError.new("File not found: #{path}")
      else
        return found_path        
      end
    end

    # Evaluate the template at the given (possibly relative) path,
    # assigning the template the local variables url, data and response.
    # If you specify a template processor (via OEmbed::TemplateResolver.template_processor=)
    # then it will be used to process the template at the given path.  Otherwise
    # a processor will be selected on the following criterion:
    #
    # If the file extension is haml, then the Haml library will be required and used
    # If the Erubis library has been loaded or the file extension is erubis, the Erubis library will be used
    # In all other cases, the ERB library will be used
    #
    # The evaluated result of the template will be returned.
    def self.eval_template_for_path(path, url, data, response)
      if actual_path = resolve_template_path(path)
        contents = File.read(actual_path)
        processor = (@template_processor || File.extname(actual_path)[1..4]).to_s
        has_erubis = defined?(Erubis)
        if processor == "haml"
          require 'haml' unless defined?(Haml)
          Haml::Engine.new(contents).render({ }, :data => data, :url => url, :response => response)
        elsif processor == "erubis" || has_erubis
          require 'erubis' unless has_erubis
          Erubis::Eruby.new(contents).result(:data => data, :url => url, :response => response)
        else
          require 'erb' unless defined?(ERB)
          ERBTemplate.new(url, data, response).evaluate(contents)
        end
      end
    end

    private

    # Resolve a relative path among an array of potential base
    # paths, returning the found path if it exists or nil if
    # none were found.
    def self.resolve_path_in_view_paths(desired, view_paths)
      view_paths.each do |p|
        prop = File.join(p, desired)
        if File.exists?(prop)
          return prop
        end
      end
      return nil
    end

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

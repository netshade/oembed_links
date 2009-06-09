require 'cgi'
require 'uri'
require 'yaml'
require 'oembed_links/template_resolver'
require 'oembed_links/response'

# The OEmbed class is the interface to class registration functions
# such as register_provider, register_formatter, etc., as well as
# the seat of the main .transform() function. If you are using OEmbed
# inside a Rails application, the process of initialization will be
# handled for you by the init.rb file.  Create a file called
# oembed_links.yml inside your RAILS_ROOT/config directory, giving it
# a format like:
#
#   :config:
#     :method: "NetHTTP"
#
#   :providers:
#     :provider_1: "http://provider1.com/oembed.{format}"
#     :provider_2: "http://provider2.com/oembed.{format}"
#
#   :provider_1:
#     :format: "json"
#     :schemes:
#       - "http://provider1.com/links/*/user/*"
#       - "http://provider1.com/photos/*/user/*"
#
#   :provider_2:
#     :format: "xml"
#     :schemes:
#       - "http://provider2.com/videos/*"
#
#
# If you are not using the library in a Rails app, you can still create
# a YAML file like above and register it using OEmbed.register_yaml_file("/path/to/file.yml")
#
# You  may also programmatically register information into the app using the
# register function, which takes a hash of configuration options, a
# provider hash, and the provider scheme hash.
#
# You may also register providers ad hoc using the OEmbed.register_provider
# function.
#
# To transform text, use the OEmbed.transform function, like:
#
#  OEmbed.transform("This is my text and here's a picture http://www.flickr.com/path/to/a/photo")
#
#  OEmbed.transform("Same text http://youtube.com/videos/somevideo") do |r, url|
#    r.from?(:youtube) { |vid| vid["html"] }
#  end
#
#  OEmbed.transform("Some more text from http://en.wikipedia.com/wiki/Dinosaurs!") do |r, url|
#    r.from?(:wikipedia, :template => "links/wiki_links")
#  end 
#
#  See the OEmbed.transform function for more details.
#
#
# The OEmbed library by default uses net/http, libxml and json libraries for
# fetching network data, parsing xml and parsing json, respectively.  These
# libraries are loaded by default.
#
# If you want to write your own mechanism for fetching HTTP data, parsing XML
# data, JSON data, or some other format, see the OEmbed::Fetchers::NetHTTP and
# OEmbed::Formatters::JSON for simple examples in terms of API.  Once your new
# class mirrors these classes, you can register it with OEmbed by using
# OEmbed.register_formatter(class) or OEmbed.register_fetcher(class).
#
# NOTE that the default formatters and fetcher are EXTREMELY naive.  There is no
# attempt at error handling, connection timeouts, or the like. If you need richer
# functionality you should subclass the existing formatters / fetchers and register them.
#
class OEmbed

  # Configure OEmbed with all necessary information  - library configuration,
  # oembed provider urls, and the supported schemes and formats of said providers.
  #
  # The configuration hash should follow the form:
  # { :method => "NameOfFetcher" }
  # Note that the name of the fetcher is NOT the classname, but the arbitrarily
  # chosen name provided by that class' .name() method.  By default, it will
  # be NetHTTP.
  #
  # The provider hash will be a hash where the keys are the symbolic names of the
  # providers, eg. :vimeo, and the values are the URL strings used to query those providers.
  # You may use the substring {format} inside these URLs to indicate that the
  # given provider URL requires the format desired to be inserted at that point.
  # Whatever format you have configured that provider for in the provider_scheme_hash
  # will be inserted when they are queried.
  #
  # The provider_scheme_hash is a hash with two keys - the first key is the format
  # key, which will either be the string "json" or the string "xml".  The other
  # key will be the schemes key, which contains an array of supported URL schemes
  # by the provider.
  #
  # It is assumed that all hashes passed in use symbols for keys.  Do not use string
  # keys. This decision is totally arbitrary and without any technical merit.
  #
  # It is assumed that all provider names are symbols.  Same rules as above.
  #
  def self.register(config_hash = { }, provider_hash = { }, provider_scheme_hash = { })
    @fetch_method = (config_hash[:method] || "NetHTTP")
    @config = config_hash
    provider_hash.each do |provider, url|
      config = provider_scheme_hash[provider]
      raise "No Schemes were provided for #{provider.to_s}" if config.nil? ||
                                                               config[:schemes].nil? ||
                                                               config[:schemes].empty?
      self.register_provider(provider, url, config[:format] || "json", *config[:schemes])
    end
  end

  # The configuration hash passed into register() or parsed from the YAML file
  def self.config
    @config
  end

  # Register a provider with OEmbed.  The provider name should be a symbol,
  # like :flickr.  The URL should be a string representing the endpoint
  # for that provider, and may include the {format} substring to indicate
  # how that provider should be notified of the desired format.
  # format is either the string "json", or the string "xml".
  # The list of schemes is an array of strings representing the different
  # URL schemes supported by the provider.  These strings follow the form:
  #
  # http://*.somedomain.*/*/*
  #
  # All schemes should use * to indicate variable text matched until the
  # next non-* character or end of line.
  def self.register_provider(provider, url, format = "json", *schemes)
    @schemes ||= [ ]
    @urls ||= { }
    @formats ||= { }
    
    @formats[provider] = format
    @urls[provider] = url.gsub(/\{format\}/i, format)
    schemes.each do |scheme|
      sanitized_scheme = scheme.gsub(/([\.\?])/) { |str| "\\#{$1}" }.gsub(/\*/, '.+?')
      @schemes << [Regexp.new("^" + sanitized_scheme + "$"), provider]
    end    
  end

  # Loads the YAML file at the specified path and registers
  # its information with OEmbed.
  def self.register_yaml_file(file)
    y = YAML.load(File.read(file))
    self.register(y.delete(:config),
                  y.delete(:providers),
                  y)
  end

  # Clear all registration information; really only valuable in testing
  def self.clear_registrations()
    @schemes = []
    @urls = { }
    @formats = { }
    @formatters = { }
    @fetchers = { }
  end

  # Load the default JSON and XML formatters, autodetecting
  # formatters when possible; load the default fetcher as well
  def self.load_default_libs(*ignore_formats)
    self.autodetect_xml_formatters(*ignore_formats)
    require 'oembed_links/formatters/json'
    self.register_formatter(OEmbed::Formatters::JSON)
    require 'oembed_links/fetchers/net_http'
    self.register_fetcher(OEmbed::Fetchers::NetHTTP)        
  end

  # Register a new formatter.  klass is the class object of the desired formatter.
  # A new instance of klass will be created and stored. This instance MUST
  # respond to the methods "name" and "format".
  def self.register_formatter(klass)
    @formatters ||= { }
    inst = klass.new
    @formatters[inst.name] = inst
  end

  # Register a new fetcher. klass is the class object of the desired fetcher.
  # A new instance of klass will be created and stored.  This instance MUST
  # respond to the methods "name" and "fetch".
  def self.register_fetcher(klass)
    @fetchers ||= { }
    inst = klass.new
    @fetchers[inst.name] = inst
  end

  # Get the OEmbed::Response object for a given URL and provider. If you wish
  # to pass extra attributes to the provider, provide a hash as the last attribute
  # with keys and values representing the keys and values of the added querystring
  # parameters.
  def self.get_url_for_provider(url, provider, *attribs)
    purl = @urls[provider]
    eurl = CGI.escape(url)
    purl += (purl.index("?")) ? "&" : "?"
    purl += "url=#{eurl}"
    attrib_hash = (attribs.last.is_a?(Hash)) ? attribs.last : { }
    attrib_hash.each do |k, v|
      purl += "&#{CGI.escape(k)}=#{CGI.escape(v)}"
    end
    fetcher = @fetchers[@fetch_method] || @fetchers[@fetchers.keys.first]
    formatter = @formatters[@formats[provider]]
    response = fetcher.fetch(purl)
    formatter.format(response)
  end

  # Transform all URLs supported by configured providers by the passed-in
  # block or by outputting their "html" attributes ( or "url" attributes
  # if no "html" attribute exists ).  You may pass in a hash to specify
  # extra parameters that should be appended to the querystrings to any
  # matching providers (see OEmbed.get_url_for_provider).  If you pass a
  # block to this method, that block will be executed for each URL
  # found in txt that has a matching provider.  This block will be passed
  # the OEmbed::Response object representing the embedding information for that
  # url.
  #
  # OEmbed.transform supports two additional parameters:
  #
  #   use_strict:  Optionally use Ruby's stricter URI detection regex. While
  #                this will be technically correct regex, not all URLs
  #                use correct syntax.  If this is false, URLs will be detected
  #                by the incredibly naive approach of finding any instance of
  #                http:// or https://, and finding anything that is not whitespace
  #                after that.
  #
  #                Example:
  #                OEmbed.transform("all my urls are correctly formed", true)
  #
  #   (options hash):  This hash is used to append extra querystring parameters
  #                to the oembed provider.  For example:
  #                OEmbed.transform("blah", false, :max_width => 320, :max_height => 200)
  #
  # You may fine tune the appearance of the embedding information by using the
  # following forms:
  #
  #   OEmbed.transform(some_string) do |r, url|
  #     r.from?(:provider_name) { |content| content["html"] }
  #     r.matches?(/some_regex_against_the_url/) { |content| content["title"] }
  #     r.video?(:template => "videos/oembed_link")
  #     r.audio? { |audio| content["html"] }
  #     r.hedgehog?(:template => File.join(File.dirname(__FILE__), "templates", "hedgehogs.haml"))
  #     r.photo? { |photo| "<img src='#{photo["url"]}' title='#{photo['title']} />" }
  #     r.any? { |anythingelse| content["title"] }
  #   end
  #
  # The priority of these conditions is as follows:
  #  The first matching block for provider (.from?(:provider_name)) takes precendence OVER
  #  The first matching block for a URL regex (.matches?(/some_regex_against_the_url/)) takes precedence OVER
  #  The first matching block for a type equivalent (.video?, .audio?, .hedgehog?, .photo?) takes precendence OVER
  #  The match anything block (.any?)
  #
  #
  #
  #
  # You do not need to specify an .any? block if you do not intend to perform any special
  # transformations upon its data; the OEmbed::Response object will output either its html attribute
  # (if it exists) or its url attribute.
  #
  # The value passed to these conditional blocks is a hash representing the data returned
  # by the server.  The keys of all the attributes will be strings.
  #
  # If you specify the :template option, a template will be found for you based on your current engironment.
  # Currently there is support for Haml, Erubis and ERB templates.  Each template will have the following
  # local variables available to it:
  #
  #  url      : The URL for which OEmbed data exists
  #  data     : A hash of the actual OEmbed data for that URL
  #  response : The OEmbed::Response object for the URL
  #
  #
  # If you are using Rails, you may specify your template relative to your application's
  # view root (eg "photos/flickr_oembed"), and your template will be found based on your application settings.
  # For more options regarding template support, see the documentation for OEmbed::TemplateResolver.
  #
  # NOTE: The type equivalent blocks (.video?, .audio?, .hedgehog?, .photo?, etc.) perform
  # an equality test between the method name and the type returned by the OEmbed provider.
  # You may specify any type name you wish as the method name, and its type will be checked
  # appropriately (as shown by the obviously trivial .hedgehog? method name).
  #
  def self.transform(txt, use_strict = false, *attribs, &block)
    ret = txt.dup

    if use_strict
      URI.extract(txt, "http") do |u|
        transform_url_for_text!(u, ret, *attribs, &block)
      end
    else
      simple_extract(txt) do |u|
        transform_url_for_text!(u, ret, *attribs, &block)
      end
    end

    return ret
  end

  # Determine the XML formatter that can be loaded for
  # this system based on what libraries are present
  def self.autodetect_xml_formatters(*ignore)
    loaded_lib = false
    unless ignore.include? "libxml"
      begin
        require 'libxml'
        require 'oembed_links/formatters/lib_xml'
        self.register_formatter(OEmbed::Formatters::LibXML)
        loaded_lib = true
      rescue LoadError
        puts "Error loading LibXML XML formatter"
      end
    end
    unless loaded_lib || ignore.include?("hpricot")
      begin
        require 'hpricot'
        require 'oembed_links/formatters/hpricot_xml'
        self.register_formatter(OEmbed::Formatters::HpricotXML)        
        loaded_lib = true
      rescue LoadError
        puts "Error loading Hpricot XML formatter"
      end      
    end
    unless loaded_lib || ignore.include?("rexml")
      require 'oembed_links/formatters/ruby_xml'
      self.register_formatter(OEmbed::Formatters::RubyXML) 
      loaded_lib = true
    end
    raise StandardError.new("No XML formatter could be autodetected") unless loaded_lib
  end

  private

  # stupid simple copy of URI.extract to allow for looser URI detection
  def self.simple_extract(str, &block)
    reg = /(https?:\/\/[^\s]+)/i
    if block_given?
      str.scan(reg) { yield $& }
      nil
    else
      result = []
      str.scan(reg) { result.push $& }
      result
    end
  end

  # extraction of inner loop of .transform(), to allow for easier
  # parameterization of OEmbed
  def self.transform_url_for_text!(u, txt, *attribs, &block)
    unless (vschemes = @schemes.select { |a| u =~ a[0] }).empty?
      regex, provider = vschemes.first
      data = get_url_for_provider(u, provider, *attribs)
      response = OEmbed::Response.new(provider, u, data)
      if block.nil?
        txt.gsub!(u, response.to_s)
      else
        yield(response, u)
        (response.has_rendered?) ? txt.gsub!(u, response.rendered_content) : txt
      end
    else
      if block.nil?
        txt
      else
        response = OEmbed::Response.new("", u, {})
        yield(response, u)
        (response.has_rendered?) ? txt.gsub!(u, response.rendered_content) : txt
      end      
    end
  end
end


OEmbed.load_default_libs


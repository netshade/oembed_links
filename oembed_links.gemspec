Gem::Specification.new do |s|
    s.name       = "oembed_links"
    s.version    = "0.0.4"
    s.author     = "Indianapolis Star"
    s.email      = "bugs at indystar dot com"
    s.homepage   = "http://www.indystar.com"
    s.platform   = Gem::Platform::RUBY
    s.summary    = "a library for using the OEmbed format (http://oembed.com/) to acquire embedding information for freetext"
    s.files      = ["Rakefile", "README", "oembed_links_example.yml", "oembed_links.gemspec", "lib", "lib/oembed_links.rb", "lib/oembed_links", "lib/oembed_links/formatters", "lib/oembed_links/fetchers", "lib/oembed_links/response.rb", "lib/oembed_links/formatters/json.rb", "lib/oembed_links/formatters/xml.rb", "lib/oembed_links/fetchers/net_http.rb", "rails", "rails/init.rb", "spec", "spec/spec_helper.rb", "spec/oembed_links_spec.rb", "spec/oembed_links_test.yml" ]
    s.require_path      = "lib"
    s.has_rdoc          = true
    s.extra_rdoc_files  = ['README']
    s.add_dependency(%q<json>)
    s.add_dependency(%q<libxml-ruby>)
end

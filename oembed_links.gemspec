Gem::Specification.new do |s|
    s.name       = "oembed_links"
    s.version    = "0.0.3"
    s.author     = "Indianapolis Star"
    s.email      = "bugs at indystar dot com"
    s.homepage   = "http://www.indystar.com"
    s.platform   = Gem::Platform::RUBY
    s.summary    = "a library for using the OEmbed format (http://oembed.com/) to acquire embedding information for freetext"
    s.files      = FileList["{lib,rails,spec}/**/*", "Rakefile", "README", "oembed_links_example.yml", "oembed_links.gemspec"].to_a
    s.require_path      = "lib"
    s.has_rdoc          = true
    s.extra_rdoc_files  = ['README']
    s.add_dependency(%q<json>)
    s.add_dependency(%q<libxml-ruby>)
end

= oembed_links

* http://indystar.com/

== DESCRIPTION:

This is the oembed_links gem.  It allows you to easily parse text and
query configured providers for embedding information on the links
inside the text. A sample configuration file for configuring the
library has been included (oembed_links_example.yml), though you
may also configure the library programmatically (see rdocs).

== REQUIREMENTS:

You must have the JSON gem installed to use oembed_links.
If you have the libxml-ruby gem installed, oembed_links will use that;
it will fall back to hpricot if that is installed, and finally REXML
if you have nothing else.  

== SYNOPSIS:

To get started quickly (in irb):

require 'oembed_links'
OEmbed.register({:method => "NetHTTP"},
                {:flickr => "http://www.flickr.com/services/oembed/",
                 :vimeo => "http://www.vimeo.com/api/oembed.{format}"},
                {:flickr => { :format => "xml", :schemes => ["http://www.flickr.com/photos/*"]},
                 :vimeo => { :format => "json", :schemes => ["http://www.vimeo.com/*"]}})

# Simple transformation
OEmbed.transform("This is my flickr URL http://www.flickr.com/photos/bees/2341623661/ and all I did was show the URL straight to the picture")

# More complex transformation
OEmbed.transform("This is my flickr URL http://www.flickr.com/photos/bees/2341623661/ and this is a vimeo URL http://www.vimeo.com/757219 wow neat") do |r, url|
  r.audio? { |a| "It's unlikely flickr or vimeo will give me audio" }
  r.photo? { |p| "<img src='#{p["url"]}' alt='Sweet, a photo named #{p["title"]}' />" }
  r.from?(:vimeo) { |v| "<div class='vimeo'>#{v['html']}</div>" }
end

# Transformation to drive Amazon links to our department affiliate code and help us buy some laptops (hint)
OEmbed.register_provider(:oohembed,
                         "http://oohembed.com/oohembed/",
                         "json",
                         "http://*.amazon.(com|co.uk|de|ca|jp)/*/(gp/product|o/ASIN|obidos/ASIN|dp)/*",
                         "http://*.amazon.(com|co.uk|de|ca|jp)/(gp/product|o/ASIN|obidos/ASIN|dp)/*")
OEmbed.transform("Here is a link to amazon http://www.amazon.com/Complete-Aubrey-Maturin-Novels/dp/039306011X/ref=pd_bbs_sr_2 wow") do |res, url|
    res.matches?(/amazon/) { |d|
      unless url =~ /(&|\?)tag=[^&]+/i
        url += ((url.index("?")) ? "&" : "?")
        url += "tag=wwwindystarco-20"
      end
      <<-EOHTML
        <div style="text-align:center;">
          <a href='#{url}' target='_blank'>
            <img src='#{d['thumbnail_url']}' border='0' /><br />
            #{d['title']} #{"<br />by #{d['author']}" if d['author']}
          </a>
        </div>
      EOHTML
    }
end


To get started quickly in Rails:

Copy the included oembed_links_example.yml file to RAILS_ROOT/config/oembed_links.yml,
add a dependency to the gem in your environment.rb ( config.gem "oembed_links" )
and start your server.  That's it.  If you'd like to transform the oembedded content via
templates, you can do so using the following syntax:

OEmbed.transform(text_to_transform) do |res, url|
  res.video?(:template => "oembed/video")
  res.from?(:a_provider, :template => "a_provider/oembed")
  res.matches?(/some_regex/, :template => "shared/oembed_link")
  res.any?(:template => "shared/oembed_link")
end

This presumes you have a directory in your Rails views directory called "oembed", and a file
of the form "video.html.erb" or "video.rhtml".  If you are not using Rails, you may still use the
template functionality, but you must specify the full path to the template. When you are integrating
with Rails, you may use any template library that is installed for your Rails app; when you are using
the absolute filename method, you only have access to ERB, Erubis or HAML.

As of version 0.0.9, your Rails oembed templates have access to all the traditional Rails template helper methods
(such as Rails' link_to, image_tag, etc.); the templates are processed using the Rails template rendering
pipeline, and as such may even do evil things like access your Models.

See the RDocs for OEmbed::TemplateResolver for more information regarding templates and oembed_links.

See the rdocs for much more complete examples.  The specs directory has some examples of programmatic
use, but the test to code ratio is slim atm.

== INSTALL:

sudo gem install oembed_links
(from github)
gem sources -a http://gems.github.com
sudo gem install netshade-oembed_links

== LICENSE:

(The MIT License)

Copyright (c) 2008 Indianapolis Star

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'oembed_links'

yaml_file = File.join(RAILS_ROOT, "config", "oembed_links.yml")
if File.exists?(yaml_file)
  OEmbed::register_yaml_file(yaml_file)
end


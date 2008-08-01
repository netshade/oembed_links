require 'rubygems'
Gem::manage_gems
require 'rake/clean'
require 'rake/gempackagetask'
CLEAN.include("pkg")

spec = eval(File.read("oembed_links.gemspec")) # I'm going to hell, etc. etc. 

task :default => [:clean, :repackage]

Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_tar = true
end


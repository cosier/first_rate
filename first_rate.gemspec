# encoding: utf-8
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require "first_rate/version"

Gem::Specification.new do |s|
  s.name        = "first_rate"
  s.version     = FirstRate::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Johnny Cihocki"]
  s.email       = ["john@startupgiraffe.com"]
  s.homepage    = "http://startupgiraffe.com"
  s.summary     = "Drop in ratings and reviews for mongoid ORM schemes."
  s.description = "mongoid_ratings_reviews allows you to easily extend any document model to allow it to be rated and reviewed, using the Mongoid ODM framework for Ruby."
  s.license     = "MIT"

  s.required_ruby_version     = ">= 1.9"
  s.required_rubygems_version = ">= 1.3.6"

  s.add_dependency("mongoid", [">= 3.0.0"])

  s.files        = Dir.glob("lib/**/*") + %w(CHANGELOG.md LICENSE README.md Rakefile)
  s.require_path = 'lib'
end

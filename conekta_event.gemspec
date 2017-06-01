$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "conekta_event/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "conekta_event"
  s.version     = ConektaEvent::VERSION
  s.authors     = ["Jorge Najera"]
  s.email       = ["jorge.najera.t@gmail.com"]
  # s.homepage    = "TODO"
  s.summary     = "Conekta webhook integration for Rails applications."
  s.description = "Conekta webhook integration for Rails applications."
  s.license     = "MIT"

  s.files         = `git ls-files`.split("\n")
   s.test_files    = `git ls-files -- test/*`.split("\n")

  s.add_dependency "activesupport", ">= 4.2.5"
  s.add_dependency "conekta", ">= 2.0.0"

  s.add_development_dependency "rspec-rails", ">= 3.5"
  s.add_development_dependency "webmock"
  # s.add_development_dependency "appraisal"
end

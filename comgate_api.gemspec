# frozen_string_literal: true

require_relative "lib/comgate_api/version"

Gem::Specification.new do |spec|
  spec.name = "comgate_api"
  spec.version = ComgateApi::VERSION
  spec.authors = ["Jozef Zigmund"]
  spec.email = ["jzigmund@users.noreply.github.com"]

  spec.summary = "Ruby client for Comgate API."
  spec.description = "A Ruby wrapper for the Comgate payment gateway API."
  spec.homepage = "https://apidoc.comgate.cz/en/uvod/"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 4.0.0"

  spec.files = Dir.chdir(__dir__) do
    Dir["{bin,lib}/**/*", "LICENSE", "README.md"]
  end
  spec.bindir = "bin"
  spec.executables = []
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 2.9"
  spec.add_dependency "dry-types", "~> 1.7"
  spec.add_dependency "dry-struct", "~> 1.6"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "factory_bot", "~> 6.4"
  spec.add_development_dependency "faker", "~> 3.3"
  spec.add_development_dependency "webmock", "~> 3.23"
  spec.add_development_dependency "dotenv", "~> 2.8"
  spec.add_development_dependency "irb", "~> 1.13"
  spec.add_development_dependency "debug"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage
end

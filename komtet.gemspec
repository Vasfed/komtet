
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "komtet/version"

Gem::Specification.new do |spec|
  spec.name          = "komtet"
  spec.version       = Komtet::VERSION
  spec.authors       = ["Vasily Fedoseyev"]
  spec.email         = ["vasilyfedoseyev@gmail.com"]

  spec.summary       = %q{Ruby client for kassa.komtet.ru}
  spec.description   = %q{Ruby client for kassa.komtet.ru}
  spec.homepage      = "https://github.com/Vasfed/komtet"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", ">=0.15"
  spec.add_dependency "faraday_middleware"

  spec.add_development_dependency "bundler", ">= 1.17"
  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "simplecov"
end

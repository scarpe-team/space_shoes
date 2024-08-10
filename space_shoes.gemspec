# frozen_string_literal: true

require_relative "lib/space_shoes/version"

Gem::Specification.new do |spec|
  spec.name = "space_shoes"
  spec.version = SpaceShoes::VERSION
  spec.authors = ["Noah Gibbs"]
  spec.email = ["the.codefolio.guy@gmail.com"]

  spec.summary = "Shoes as embedded HTML, via Wasm."
  spec.description = "An implementation of the Shoes GUI library in embedded HTML, and using HTML and Wasm generally."
  spec.homepage = "https://github.com/scarpe-team/space_shoes"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  #spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/scarpe-team/space_shoes"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git npm/ appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "lacci", "~>0.4.0"
  spec.add_dependency "scarpe-components", "~>0.4.0"

  spec.add_dependency "ruby_wasm", "~> 2.5"
  spec.add_dependency "js", "~>2.6"

  # For now, require as a direct dependency - needed so that minitest can run inside the browser in wasm
  spec.add_dependency "minitest", "~>5.22"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end

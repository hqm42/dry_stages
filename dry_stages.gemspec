# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dry_stages/version'

Gem::Specification.new do |spec|
  spec.name          = 'dry_stages'
  spec.version       = DryStages::VERSION
  spec.authors       = ['Robert Steuck']
  spec.email         = ['robert.steuck@gmail.com']
  spec.summary       = 'Configurable, reusable, cached stages for optimzed code reuse and dry implementation of single-tack processing pipelines'
  spec.homepage      = 'https://github.com/hqm42/dry_stages'

  spec.license       = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(spec|examples)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end

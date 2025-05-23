# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'heytmux/version'

Gem::Specification.new do |spec|
  spec.name          = 'heytmux'
  spec.version       = Heytmux::VERSION
  spec.authors       = ['Junegunn Choi']
  spec.email         = ['junegunn.c@gmail.com']

  spec.summary       = 'Hey tmux!'
  spec.description   = 'Tmux scripting made easy'
  spec.homepage      = 'https://github.com/junegunn/heytmux'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(/^(bin|test|spec|features|plugin|examples|\.)/)
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.4'
  spec.add_development_dependency 'bundler', '>= 2.2.15'
  spec.add_development_dependency 'coveralls_reborn'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake'
end

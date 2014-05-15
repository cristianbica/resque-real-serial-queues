# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'resque/real/serial/queues/version'

Gem::Specification.new do |spec|
  spec.name          = "resque-real-serial-queues"
  spec.version       = Resque::Real::Serial::Queues::VERSION
  spec.authors       = ["Javier Evans"]
  spec.email         = ["evans.javier@gmail.com"]
  spec.summary       = %q{Resque plugin to allow queues to be processed serially without modifying the queue order}
  spec.description   = %q{The plugin is designed for sequential running of different jobs in the same queue across multiple queues.  Specifically meant for running a variety of long-running background tasks scheduled ahead of time using something like reque-scheduler.  May not be suitable for large scale operations.}
  spec.homepage      = "https://github.com/4141done/resque-real-serial-queues"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  gem.add_dependency "resque", "~> 1.25"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end

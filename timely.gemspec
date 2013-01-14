# -*- encoding: utf-8 -*-
require File.expand_path('../lib/timely/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Kenneth Keiter"]
  gem.email         = ["ken@kenkeiter.com"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "timely"
  gem.require_paths = ["lib"]
  gem.version       = Timely::VERSION

  gem.add_runtime_dependency 'redis'

  unless RUBY_PLATFORM =~ /java/i
    gem.add_runtime_dependency 'hiredis'
  end

  gem.add_development_dependency 'rspec'

end

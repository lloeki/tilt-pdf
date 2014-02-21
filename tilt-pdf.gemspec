# -*- encoding: utf-8 -*-
$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'tilt/pdf/version'

Gem::Specification.new do |s|
  s.name        = 'tilt-pdf'
  s.version     = Tilt::PDF::VERSION
  s.authors     = ['Loic Nageleisen']
  s.email       = ['loic.nageleisen@gmail.com']
  s.homepage    = 'http://github.com/lloeki/tilt-pdf'
  s.summary     = %q{PDF files via Tilt}
  s.description = %q{Integrates PDF generation into a Tilt flow}
  s.license     = 'MIT'
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n")
                                           .map { |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_dependency 'tilt', '~> 1.4.1'
  s.add_dependency 'pdfkit', '~> 0.5.4'

  s.add_development_dependency 'therubyracer'
  s.add_development_dependency 'less'
  s.add_development_dependency 'coffee-script'
  s.add_development_dependency 'slim'
  s.add_development_dependency 'rspec', '~> 2.14'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'pry'
end

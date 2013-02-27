lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rds-s3-backup/version'

Gem::Specification.new do |gem|
  gem.name          = "rds-s3-backup"
  gem.version       = Rds::S3::Backup::VERSION
  gem.authors       = ["Tamara Temple"]
  gem.email         = ["tamouse@gmail.com"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency('thor')
  gem.add_dependency('fog')
  gem.add_dependency('logger')
  gem.add_dependency('dogapi')
  gem.add_development_dependency('rspec')
  gem.add_development_dependency('aruba')
  gem.add_development_dependency('cucumber')
  gem.add_development_dependency('rake')
  gem.add_development_dependency('debugger')
  
end

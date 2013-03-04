lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rds-s3-backup/version'

Gem::Specification.new do |gem|
  gem.name          = "rds-s3-backup"
  gem.version       = Rds::S3::Backup::VERSION
  gem.authors       = ["Tamara Temple"]
  gem.email         = ["tamouse@gmail.com"]
  gem.description   = %q{"Thor script and libraries to backup an AWS RDS snapshot to AWS S3, and create an obfustacted version to backup on S3 as well"}
  gem.summary       = %q{"Backup from AWS RDS snapshot to AWS S3 as mysqldump"}
  gem.homepage      = "https://github.com/novu/rds-s3-backup-gem"

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

# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "mongo_db_logging/version"

Gem::Specification.new do |s|
  s.name        = "mongo_db_logger"
  s.version     = MongoDBLogging::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Robert Sanders"]
  s.email       = ["robert@zeevex.com"]
  s.homepage    = "https://github.com/zeevex/mongo_db_logger"
  s.summary     = %q{Our forked gemified version of the old mongo_db_logger Rails plugin}
  s.description = %q{Log Rails requests to MongoDB. This is Zeevex's forked and gemified version.}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'zeevex_delayed'
  s.add_dependency 'mongo'

  s.add_development_dependency 'rspec', '~> 2.9.0'
  s.add_development_dependency 'rake'
end

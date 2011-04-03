# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{fluidinfo}
  s.version = "0.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Eric Seidel"]
  s.date = %q{2011-04-03}
  s.description = %q{This gem provides a simple interface to fluidinfo, built on top of the rest-client gem.}
  s.email = %q{gridaphobe@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "fluidinfo.gemspec",
    "lib/fluidinfo.rb",
    "test/helper.rb",
    "test/test_fluidinfo.rb"
  ]
  s.homepage = %q{http://github.com/gridaphobe/fluidinfo.rb}
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.7.1}
  s.summary = %q{Provides a simple interface to fluidinfo}
  s.test_files = [
    "test/helper.rb",
    "test/test_fluidinfo.rb"
  ]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rest-client>, [">= 1.6.1"])
      s.add_runtime_dependency(%q<yajl-ruby>, [">= 0.8.2"])
      s.add_development_dependency(%q<shoulda>, [">= 0"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.5.2"])
      s.add_development_dependency(%q<rcov>, [">= 0"])
      s.add_development_dependency(%q<uuidtools>, [">= 2.1.2"])
    else
      s.add_dependency(%q<rest-client>, [">= 1.6.1"])
      s.add_dependency(%q<yajl-ruby>, [">= 0.8.2"])
      s.add_dependency(%q<shoulda>, [">= 0"])
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.5.2"])
      s.add_dependency(%q<rcov>, [">= 0"])
      s.add_dependency(%q<uuidtools>, [">= 2.1.2"])
    end
  else
    s.add_dependency(%q<rest-client>, [">= 1.6.1"])
    s.add_dependency(%q<yajl-ruby>, [">= 0.8.2"])
    s.add_dependency(%q<shoulda>, [">= 0"])
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.5.2"])
    s.add_dependency(%q<rcov>, [">= 0"])
    s.add_dependency(%q<uuidtools>, [">= 2.1.2"])
  end
end


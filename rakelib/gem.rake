require "hoe"

Hoe.plugin :debugging, :doofus, :git

HOE = Hoe.spec 'typhoeus' do
  developer('Paul Dix', 'paul@pauldix.net')

  self.url              = "http://github.com/pauldix/typhoeus"
  self.readme_file      = 'README.rdoc'
  self.history_file     = 'CHANGELOG.rdoc'
  self.extra_rdoc_files = FileList['*.rdoc', 'ext/**/*.c']
  self.test_globs       = "spec/*/*_spec.rb"

  self.summary          = %q{A library for interacting with web services (and building SOAs) at blinding speed.}
  self.description      = %q{Like a modern code version of the mythical beast with 100 serpent heads, Typhoeus runs HTTP requests in parallel while cleanly encapsulating handling logic.}

  spec_extras[:required_ruby_version]     = Gem::Requirement.new('>= 1.8.6')
  spec_extras[:required_rubygems_version] = '>= 1.3.5'
  spec_extras[:extensions]                = ["ext/typhoeus/extconf.rb"]

  extra_deps     << ["rack", ">= 0"]

  extra_dev_deps << ['rake-compiler', "~> 0.7.0"]
  extra_dev_deps << ["rspec", ">= 0"]
  extra_dev_deps << ["hoe-git", ">= 0"]
  extra_dev_deps << ["hoe-debug", ">= 0"]
  extra_dev_deps << ["hoe-doofus", ">= 0"]
  extra_dev_deps << ["diff-lcs", ">= 0"]
  extra_dev_deps << ["sinatra", ">= 0"]
  extra_dev_deps << ["json", ">= 0"]
end

Hoe.add_include_dirs '.'
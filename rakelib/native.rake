# use rake-compiler for building the extension
require 'rake/extensiontask'

CURL_VERSION = "7.21.0"

# C:/Ruby187/bin/ruby.exe -I. ../../../../ext/typhoeus/extconf.rb --with-curl-include=c:/Code/typhoeus/vendor/curl-7.21.0-devel-mingw32/include --with-curl-lib=c:/Code/typhoeus/vendor/curl-7.21.0-devel-mingw32/bin

Rake::ExtensionTask.new('native', Rake.application.jeweler.gemspec) do |ext|
  # reference where the vendored libCurl got extracted
  curl_lib = File.expand_path(File.join(File.dirname(__FILE__), '..', 'vendor', "curl-#{CURL_VERSION}-devel-mingw32"))

  # where native extension will be copied (matches makefile)
  ext.lib_dir = "lib/typhoeus"

  ext.ext_dir = "ext/typhoeus"

  # define target for extension (supporting fat binaries)
  if RUBY_PLATFORM =~ /mswin|mingw/ then
    ruby_ver = RUBY_VERSION.match(/(\d+\.\d+)/)[1]
    ext.lib_dir = "lib/typhoeus/#{ruby_ver}"
  end

  # automatically add build options to avoid need of manual input
  if RUBY_PLATFORM =~ /mswin|mingw/ then
    ext.config_options << "--with-curl-include=#{curl_lib}/include"
    ext.config_options << "--with-curl-lib=#{curl_lib}/bin"
  else
    ext.cross_compile = true
    ext.cross_platform = ['i386-mingw32', 'i386-mswin32-60']
    ext.cross_config_options << "--with-curl-include=#{curl_lib}/include"
    ext.cross_config_options << "--with-curl-lib=#{curl_lib}/lib"
    ext.cross_compiling do |gemspec|
      gemspec.post_install_message = <<-POST_INSTALL_MESSAGE

======================================================================================================

  You've installed the binary version of #{gemspec.name}.
  It was built using libCurl version #{CURL_VERSION}.
  It's recommended to use the exact same version to avoid potential issues.

  At the time of building this gem, the necessary DLL files where available
  in the following download:

  http://www.gknw.net/mirror/curl/win32/curl-#{CURL_VERSION}-devel-mingw32.zip

  You can put the bin\\libcurl.dll available in this package in your Ruby bin
  directory, for example C:\\Ruby\\bin

======================================================================================================

      POST_INSTALL_MESSAGE
    end
  end
end

# ensure things are compiled prior testing
task :test => [:compile]
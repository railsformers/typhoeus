# Darwin (OSX) special cases for universal binaries
# This is to avoid the lack of UB binaries for Typhoeus
ENV["RC_ARCHS"] = "" if RUBY_PLATFORM =~ /darwin/

require 'mkmf'

RbConfig::MAKEFILE_CONFIG['CC'] = ENV['CC'] if ENV['CC']

if RUBY_PLATFORM =~ /mswin/
  $CFLAGS << ' -W3'
else
  $CFLAGS << ' -O3 -Wall -Wcast-qual -Wwrite-strings -Wconversion' <<
             ' -Wmissing-noreturn -Winline'
end

def asplode missing
  if RUBY_PLATFORM =~ /mswin/
    abort "#{missing} is missing. Install libCurl from " +
          "http://curl.haxx.se/ first."
  else
    abort "#{missing} is missing."
  end
end


dir_config('curl')
libname = RUBY_PLATFORM =~ /mswin|mingw/ ? 'libcurl' : 'curl'
asplode('libcurl') unless find_library(libname, 'curl_easy_init')
asplode('curl/curl.h') unless find_header('curl/curl.h')

create_makefile("typhoeus/native")

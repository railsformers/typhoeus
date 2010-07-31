require 'rake/clean'
require 'rake/extensioncompiler'

# download curl library and headers
directory "vendor"

# http://www.gknw.net/mirror/curl/win32/curl-7.20.1-devel-mingw32.zip

file "vendor/curl-#{CURL_VERSION}-devel-mingw32.zip" => ['vendor'] do |t|
  url = "http://www.gknw.net/mirror/curl/win32/curl-#{CURL_VERSION}-devel-mingw32.zip"
  when_writing "downloading #{t.name}" do
    cd File.dirname(t.name) do
      sh "wget -c #{url} || curl -C - -O #{url}"
    end
  end
end

file "vendor/curl-#{CURL_VERSION}-devel-mingw32/include/curl/curl.h" => ["vendor/curl-#{CURL_VERSION}-devel-mingw32.zip"] do |t|
  full_file = File.expand_path(t.prerequisites.last)
  when_writing "creating #{t.name}" do
    cd "vendor" do
      sh "unzip #{full_file} curl-#{CURL_VERSION}-devel-mingw32/bin/** curl-#{CURL_VERSION}-devel-mingw32/include/** curl-#{CURL_VERSION}-devel-mingw32/lib/**"
    end
    # update file timestamp to avoid Rake perform this extraction again.
    touch t.name
  end
end

# clobber expanded packages
CLOBBER.include("vendor/curl-#{CURL_VERSION}-devel-mingw32")

# vendor:curl
task 'vendor:curl' => ["vendor/curl-#{CURL_VERSION}-devel-mingw32/include/curl/curl.h"]

# hook into cross compilation vendored curl dependency
if RUBY_PLATFORM =~ /mingw|mswin/ then
  Rake::Task['compile'].prerequisites.unshift 'vendor:curl'
else
  if Rake::Task.tasks.map {|t| t.name }.include? 'cross'
    Rake::Task['cross'].prerequisites.unshift 'vendor:curl'
  end
end
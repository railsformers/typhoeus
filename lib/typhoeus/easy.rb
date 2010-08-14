module Typhoeus
  class Easy
    alias __method__ method

    attr_reader :response_body, :response_header, :method, :headers, :url, :params
    attr_accessor :start_time

    AUTH_TYPES = {
      :CURLAUTH_BASIC         => 1,
      :CURLAUTH_DIGEST        => 2,
      :CURLAUTH_GSSNEGOTIATE  => 4,
      :CURLAUTH_NTLM          => 8,
      :CURLAUTH_DIGEST_IE     => 16,
      :CURLAUTH_AUTO          => 16 | 8 | 4 | 2 | 1
    }

    def initialize
      @method = :get
      @headers = {}

      @response_body = ""
      @response_header = ""

      @easy = Curl::Easy.new
      set_response_handlers

      # Enable encoding/compression support
      set_option(:ENCODING, '')
    end

    def set_option(option, value)
      @easy.setopt(option, value)
    end

    def set_response_handlers
      set_option(:WRITEFUNCTION, FFI::Function.new(:size_t, [:pointer, :size_t, :size_t,], &self.__method__(:write_callback)))
      set_option(:HEADERFUNCTION, FFI::Function.new(:size_t, [:pointer, :size_t, :size_t], &self.__method__(:header_callback)))
    end

    def write_callback(string_ptr, size, nmemb)
      length = size * nmemb
      @response_body << string_ptr.read_string(length)
      return length
    end

    def header_callback(string_ptr, size, nmemb)
      length = size * nmemb
      @response_header << string_ptr.read_string(length)
      return length
    end

    def headers=(hash)
      @headers = hash
    end

    def proxy=(proxy)
      set_option(:PROXY, proxy)
    end

    def auth=(authinfo)
      set_option(:USERPWD, "#{authinfo[:username]}:#{authinfo[:password]}")
      set_option(:HTTPAUTH, authinfo[:method]) if authinfo[:method]
    end

    def auth_methods
      @easy.getinfo(:HTTPAUTH_AVAIL)
    end

    def verbose=(boolean)
      set_option(:VERBOSE, boolean ? 1 : 0)
    end

    def total_time_taken
      @easy.getinfo(:TOTAL_TIME)
    end

    def effective_url
      @easy.getinfo(:EFFECTIVE_URL)
    end

    def response_code
      @easy.getinfo(:RESPONSE_CODE)
    end

    def follow_location=(boolean)
      set_option(:FOLLOWLOCATION, boolean ? 1 : 0)
    end

    def max_redirects=(redirects)
      set_option(:MAXREDIRS, redirects)
    end

    def connect_timeout=(milliseconds)
      @connect_timeout = milliseconds
      set_option(:NOSIGNAL, 1)
      set_option(:CONNECTTIMEOUT_MS, milliseconds)
    end

    def timeout=(milliseconds)
      @timeout = milliseconds
      set_option(:NOSIGNAL, 1)
      set_option(:TIMEOUT_MS, milliseconds)
    end

    def timed_out?
      @timeout && total_time_taken > @timeout && response_code == 0
    end

    def supports_zlib?
      !!(curl_version.match(/zlib/))
    end

    def read_callback(string_ptr, size, nmemb)
      @request_body_read ||= 0
      realsize = size * nmemb

      if realsize > @request_body.size - @request_body_read
        realsize = @request_body.size - @request_body_read
      end

      string_ptr.write_string(@request_body.slice(@request_body_read, realsize)) if realsize != 0
      @request_body_read += realsize

      return realsize
    end

    def request_body=(request_body)
      @request_body = request_body
      if @method == :put

        set_option(:INFILESIZE, request_body.size)
        set_option(:READFUNCTION, FFI::Function.new(:size_t, [:pointer, :size_t, :size_t], &self.__method__(:read_callback)))

        easy_set_request_body(@request_body)
        headers["Transfer-Encoding"] = ""
        headers["Expect"] = ""
      else
        self.post_data = request_body
      end
    end

    def user_agent=(user_agent)
      set_option(:USERAGENT, user_agent)
    end

    def url=(url)
      @url = url
      set_option(:URL, url)
    end

    def disable_ssl_peer_verification
      set_option(:VERIFYPEER, 0)
    end

    def method=(method)
      @method = method
      if method == :get
        set_option(:HTTPGET, 1)
      elsif method == :post
        set_option(:POST, 1)
        self.post_data = ""
      elsif method == :put
        set_option(:UPLOAD, 1)
        self.request_body = "" unless @request_body
      elsif method == :head
        set_option(:NOBODY, 1)
      else
        set_option(:CUSTOMREQUEST, method.to_s.upcase)
      end
    end

    def post_data=(data)
      @post_data_set = true
      set_option(:POSTFIELDSIZE, data.length)
      set_option(:COPYPOSTFIELDS, data)
    end

    def params=(params)
      @params = params
      params_string = params.keys.collect do |k|
        value = params[k]
        if value.is_a? Hash
          value.keys.collect {|sk| Rack::Utils.escape("#{k}[#{sk}]") + "=" + Rack::Utils.escape(value[sk].to_s)}
        elsif value.is_a? Array
          key = Rack::Utils.escape(k.to_s)
          value.collect { |v| "#{key}=#{Rack::Utils.escape(v.to_s)}" }.join('&')
        else
          "#{Rack::Utils.escape(k.to_s)}=#{Rack::Utils.escape(params[k].to_s)}"
        end
      end.flatten.join("&")

      if method == :post
        self.post_data = params_string
      else
        self.url = "#{url}?#{params_string}"
      end
    end

    # Set SSL certificate
    # " The string should be the file name of your certificate. "
    # The default format is "PEM" and can be changed with ssl_cert_type=
    def ssl_cert=(cert)
      set_option(:SSLCERT, cert)
    end

    # Set SSL certificate type
    # " The string should be the format of your certificate. Supported formats are "PEM" and "DER" "
    def ssl_cert_type=(cert_type)
      raise "Invalid ssl cert type : '#{cert_type}'..." if cert_type and !%w(PEM DER).include?(cert_type)
      set_option(:SSLCERTTYPE, cert_type)
    end

    # Set SSL Key file
    # " The string should be the file name of your private key. "
    # The default format is "PEM" and can be changed with ssl_key_type=
    #
    def ssl_key=(key)
      set_option(:SSLKEY, key)
    end

    # Set SSL Key type
    # " The string should be the format of your private key. Supported formats are "PEM", "DER" and "ENG". "
    #
    def ssl_key_type=(key_type)
      raise "Invalid ssl key type : '#{key_type}'..." if key_type and !%w(PEM DER ENG).include?(key_type)
      set_option(:SSLKEYTYPE, key_type)
    end

    def ssl_key_password=(key_password)
      set_option(:KEYPASSWD, key_password)
    end

    # Set SSL CACERT
    # " File holding one or more certificates to verify the peer with. "
    #
    def ssl_cacert=(cacert)
      set_option(:CAINFO, cacert)
    end

    # Set CAPATH
    # " directory holding multiple CA certificates to verify the peer with. The certificate directory must be prepared using the openssl c_rehash utility. "
    #
    def ssl_capath=(capath)
      set_option(:CAPATH, capath)
    end

    def perform
      set_headers
      @easy.perform
      resp_code = response_code
      if resp_code >= 200 && resp_code <= 299
        success
      else
        failure
      end
      resp_code
    end

    # @todo add_header and set_header need to be implemented
    def set_headers
#      headers.each_pair do |key, value|
#        easy_add_header("#{key}: #{value}")
#      end
#      easy_set_headers() unless headers.empty?
    end

    # gets called when finished and response code is 200-299
    def success
      @success.call(self) if @success
    end

    def on_success(&block)
      @success = block
    end

    def on_success=(block)
      @success = block
    end

    # gets called when finished and response code is 300-599
    def failure
      @failure.call(self) if @failure
    end

    def on_failure(&block)
      @failure = block
    end

    def on_failure=(block)
      @failure = block
    end

    def retries
      @retries ||= 0
    end

    def increment_retries
      @retries ||= 0
      @retries += 1
    end

    def max_retries
      @max_retries ||= 40
    end

    def max_retries?
      retries >= max_retries
    end

    def reset
      @retries = 0
      @response_code = 0
      @response_header = ""
      @response_body = ""
      @easy.reset
    end

    # @todo Curl.version needs to be added to curl-ff
    def curl_version
      version
    end

  end
end

require "addressable/uri"
require 'open-uri'

module Rack #:nodoc:
  class GoogleAnalyticsMobile
    GIF = [0x47, 0x49, 0x46, 0x38, 0x39, 0x61,
      0x01, 0x00, 0x01, 0x00, 0x80, 0xff,
      0x00, 0xff, 0xff, 0xff, 0x00, 0x00,
      0x00, 0x2c, 0x00, 0x00, 0x00, 0x00,
      0x01, 0x00, 0x01, 0x00, 0x00, 0x02,
      0x02, 0x44, 0x01, 0x00, 0x3b].pack('c*')

    GA_VERSION = "4.4sh"

    COOKIE_NAME = "__utmmobile"
    COOKIE_PATH = "/"
    COOKIE_USER_PERSISTENCE = 63072000

    def initialize(app, options = {})
      @app = app
      @options = options
    end
    
    def call(env)
      if env["PATH_INFO"] == '/ga.gif'
        track_page_view(env)
      else
        status, headers, response = @app.call(env)

        if headers["Content-Type"] =~ /text\/html|application\/xhtml\+xml/
          body = response.body
          index = body.rindex("</body>")

          if index
            body.insert(index, tracking_image(env, @options[:ga_account]))
            headers["Content-Length"] = body.length.to_s
            response = [body]
          end
        end

        [status, headers, response]
      end
    end

    protected
      def get_random_number; rand(0x7fffffff).to_s; end

      def get_visitor_id(env, account, cookie)
        return cookie if cookie

        user_agent = env["HTTP_USER_AGENT"] || ''

        guid = env["HTTP_X_DCMGUID"]
        guid ||= env["HTTP_X_UP_SUBNO"]
        guid ||= env["HTTP_X_JPHONE_UID"]
        guid ||= env["HTTP_X_EM_UID"]

        message = if guid && guid.length > 0
          guid + account
        else
          user_agent + Digest::MD5.hexdigest(get_random_number)
        end

        return "0x#{Digest::MD5.hexdigest(message)}"
      end

      def get_ip(remote_address)
        return "" unless remote_address

        regex = /^([^.]+\.[^.]+\.[^.]+\.).*/
        if matches = remote_address.scan(regex)
          return matches[0][0] + "0"
        else
          return ""
        end
      end

      def send_page_view(env, url)
        options = {
          "method" => "GET",
          "user_agent" => env["HTTP_USER_AGENT"],
          "header" => "Accepts-Language: #{env["HTTP_ACCEPT_LANGUAGE"]}"
        }
    
        OpenURI::open_uri(url, options)
      end

      def tracking_image(env, ga_account)
        uri = Addressable::URI.new
        uri.path = "/ga.gif"
        uri.query_values = {
          utmac: ga_account,
          utmn: get_random_number,
          utmr: env['HTTP_REFERER'] || '-',
          utmp: env['REQUEST_URI'],
          guid: 'ON'
        }

         "<img src=\"#{uri}\" alt=\"\" />"
      end

      def track_page_view(env)
        request = Rack::Request.new(env)

        account = request.params["utmac"] || ''
        cookie = request.cookies[COOKIE_NAME]

        visitor_id = get_visitor_id(env, account, cookie)

        uri = Addressable::URI.parse("http://www.google-analytics.com/__utm.gif")
        uri.query_values = {
          utmwv: GA_VERSION,
          utmn: get_random_number,
          utmhn: env["SERVER_NAME"] || '',
          utmr: request.params['utmr'] || '-',
          utmp: request.params['utmp'] || '',
          utmac: account,
          utmcc: "__utma%3D999.999.999.999.999.1%3B",
          utmvid: visitor_id,
          utmip: get_ip(env["REMOTE_ADDR"])
        }

        puts "URI: #{uri}"

        send_page_view(env, uri)
        send_response(visitor_id)
      end

      def send_response(visitor_id)
        headers = {
          "Content-Type" => "image/gif",
          "Cache-Control" => "private, no-cache, no-cache=Set-Cookie, proxy-revalidate",
          "Pragma" => "no-cache",
          "Expires" => "Wed, 17 Sep 1975 21:32:10 GMT"
        }

        response = Rack::Response.new([GIF], 200, headers)
        response.set_cookie(COOKIE_NAME, {:value => visitor_id, :path => COOKIE_PATH, :expires => Time.now + COOKIE_USER_PERSISTENCE})
        response.finish
      end
  end
end

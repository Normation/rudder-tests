require "net/http"
require "json"

# Register the api_call as a resource
module Serverspec
  module Helper
    module Type
      def api_call(type, url, token, body)
        Serverspec::Type::ApiCall.new(type, url, token, body)
      end
    end
  end
end

module Serverspec
  module Type
    class ApiCall < Base

      def initialize(type, url, token, body)
        uri = URI(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http.use_ssl = true

        header = {"X-API-TOKEN": token}

        request = Net::HTTP::Get.new(uri.request_uri, header)
        if body.nil? || body.empty?
          request.body = body.to_json
        end
        response = http.request(request)

        @type = type.upcase
        @url = url
        @code = response.code
        @body = response.body
      end

      # Print test header:
      # Api call "GET https://example.com"
      def to_s
        type = self.class.name.split(":")[-1]
        type.capitalize!
        %Q!#{type} "#{@type} #{@url}"!
      end

      # its(:return_code) { should be "200" }
      def return_code
        @code
      end

      def content
        @body
      end

      def content_as_json
        JSON.parse(@body)
      end

      def data
        content_as_json["data"]
      end

      def exit_status
        @code.to_i
      end

      private

    end
  end
end

include Serverspec::Type

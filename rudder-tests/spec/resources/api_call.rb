require "net/http"
require 'faraday'
require "json"

# Register the api_call as a resource
module Serverspec
  module Helper
    module Type
      def api_call(method, url, token, body)
        Serverspec::Type::ApiCall.new(method, url, token, body)
      end
    end
  end
end

module Serverspec
  module Type
    class ApiCall < Base

      def initialize(method, url, token, body)
        conn = Faraday.new(
          url: url,
          headers: {'X-API-TOKEN' => token, 'Content-Type' => 'application/json'},
          ssl:  {:verify => false}
        )

        response = case method.upcase
          when "GET"
            conn.get ""
          when "DELETE"
            conn.delete ""
          when "POST"
            conn.post "", body.to_json
          when "PUT"
            conn.put "", body.to_json
        end

        # print the curl equivalent for debugging purposes
        #puts "curl -k --header \"X-API-Token: #{token}\" --header \"Content-Type: application/json\" --request #{method.upcase} \"#{url}\" -d \'#{body.to_json}\'"

        @method = method.upcase
        @url = url
        @request_body = $body
        @status = response.status
        @body = response.body
      end

      # Print test header:
      # Api call "GET https://example.com"
      def to_s
        method = self.class.name.split(":")[-1]
        method.capitalize!
        %Q!#{method} "#{@method} #{@url} #{@request_body}"!
      end

      # its(:return_status) { should be "200" }
      def return_code
        @status
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

      private

    end
  end
end

include Serverspec::Type

require 'json'
require 'open-uri'
require 'uri'
require 'net/http/persistent'

class Firebase
  class Request

    attr_reader :base_uri

    def initialize(base_uri)
      @base_uri = base_uri
    end

    def get(path, query_options)
      process(:get, path, nil, query_options)
    end

    def put(path, value, query_options)
      process(:put, path, value.to_json, query_options)
    end

    def post(path, value, query_options)
      process(:post, path, value.to_json, query_options)
    end

    def delete(path, query_options)
      process(:delete, path, nil, query_options)
    end

    def delete_multiple(base_path, nodes, query_options)
      process_multiple(:delete, base_path, nodes, query_options)
    end

    def patch(path, value, query_options)
      process(:patch, path, value.to_json, query_options)
    end

    def build_url(path, auth=nil)
      path = "#{path}.json"
      path = "#{path}?auth=#{auth}" if auth
      url = URI.join(base_uri, path)
      url.to_s
    end

    private

    def process_multiple(method, path, nodes, query_options={})
      auth = query_options.delete(:auth)
      options = query_options.empty? ? nil : query_options.to_json
      Faraday.new do |faraday|
        faraday.adapter :net_http_persistent
        nodes.map do |node|
          url = "#{path}/#{node}"
          Firebase::Response.new faraday.send(method, build_url(url, auth), options)
        end
      end
    end

    def process(method, path, body=nil, query_options={})
      auth = query_options.delete(:auth)
      options = query_options.empty? ? nil : query_options.to_json
      conn = Faraday.send(method, build_url(path, auth), options) do |faraday|
        faraday.body = body if body
      end
      Firebase::Response.new(conn)
    end
  end
end

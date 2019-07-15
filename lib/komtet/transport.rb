require 'faraday'
require 'faraday_middleware'
require 'openssl'

module Komtet

  class Transport

    DEFAULT_API_URL='https://kassa.komtet.ru/api/shop/v1/'

    # middleware for request signatures
    class RequestSignatureMiddleware < Faraday::Middleware
      def initialize(app, shop_id, signature_key)
        @app = app
        @authorization = shop_id
        @signature_key = signature_key
      end

      def call(env)
        env.request_headers['Authorization'] = @authorization
        env.request_headers['X-HMAC-Signature'] = OpenSSL::HMAC.hexdigest(
          OpenSSL::Digest::MD5.new, @signature_key, "#{env.method.to_s.upcase}#{env.url}#{env.body}"
        )
        @app.call(env)
      end
    end

    def initialize(api_url, shop_id, signature_key, queue_id=nil)
      @api_url = api_url
      @authorization = shop_id
      @signature_key = signature_key
      @queue_id = queue_id
    end

    def transport
      @transport ||= Faraday.new(url: @api_url) do |conn|
        conn.headers['User-Agent'] = "KomtetRuby/#{Komtet::VERSION}"
        conn.headers['Accept'] = "application/json"
        conn.request(:json)
        conn.use(RequestSignatureMiddleware, @authorization, @signature_key)
        conn.response :json, content_type: /\bjson$/
        conn.adapter(Faraday.default_adapter)
      end
    end

    def post_task(content, queue_id=@queue_id)
      raise ArgumentError, "queue_id is not integer" unless queue_id.is_a?(Integer)
      res = transport.post("queues/#{queue_id}/task", content)
      raise "non success: #{res.status}: #{res.body}" unless res.success?
      res.body
    end

    def task_result(task_id)
      res = transport.get("tasks/#{task_id}")
      raise "non success: #{res.status}: #{res.body}" unless res.success?
      res.body
    end

  end

end
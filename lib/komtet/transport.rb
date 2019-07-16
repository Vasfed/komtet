require 'faraday'
require 'faraday_middleware'
require 'openssl'

module Komtet

  class Transport

    # See https://kassa.komtet.ru/integration/api

    DEFAULT_API_URL='https://kassa.komtet.ru/api/shop/v1/'

    # middleware for request signatures
    class RequestSignatureMiddleware < Faraday::Middleware
      def initialize(app, credentials)
        @app = app
        @credentials = credentials
      end

      def call(env)
        env.request_headers['Authorization'] = @credentials.shop_id
        env.request_headers['X-HMAC-Signature'] = @credentials.signature(env.method, env.url, env.body)
        @app.call(env)
      end
    end

    def initialize(api_url, credentials)
      @api_url = api_url
      @credentials = credentials
    end

    def transport
      @transport ||= Faraday.new(url: @api_url) do |conn|
        conn.headers['User-Agent'] = "KomtetRuby/#{Komtet::VERSION}"
        conn.headers['Accept'] = "application/json"
        conn.request(:json)
        conn.use(RequestSignatureMiddleware, @credentials)
        conn.response :json, content_type: /\bjson$/
        conn.adapter(Faraday.default_adapter)
      end
    end

    def post_task(content, queue_id=@credentials.queue_id)
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
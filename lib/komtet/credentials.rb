require 'openssl'
require 'base64'

module Komtet

  # relates to a task queue (a set of registrators)
  class Credentials

    attr_accessor :shop_id, :signature_key, :queue_id

    def initialize(shop_id:, signature_key:, queue_id:nil)
      # TODO: also LLC data here
      @shop_id = shop_id
      @signature_key = signature_key
      @queue_id = queue_id
    end

    def self.from_hash(hash, key_pass:nil)
      unless (decoded_signature = hash[:signature_key] || hash["signature_key"])
        cipher = OpenSSL::Cipher.new('aes-256-cbc')
        cipher.decrypt
        cipher.key = key_pass
        cipher.iv  = Base64.strict_decode64(hash[:signature_key_iv] || hash["signature_key_iv"])
        decoded_signature = cipher.update(
          Base64.strict_decode64(hash[:signature_key_enc] || hash["signature_key_enc"])
          ) + cipher.final
        unless Digest::MD5.hexdigest(decoded_signature) == (hash[:signature_key_hash] || hash["signature_key_hash"])
          # actually there's usually OpenSSL::Cipher::CipherError, but not guaranteed
          raise "Signature md5 does not match, probably wrong key_pass (bad decrypt)"
        end
      end

      new(
        shop_id: hash[:shop_id] || hash["shop_id"],
        signature_key: decoded_signature,
        queue_id: hash[:queue_id] || hash["queue_id"],
      )
    end

    def to_hash(key_pass:)
      cipher = OpenSSL::Cipher.new('aes-256-cbc')
      cipher.encrypt
      cipher.key = key_pass
      signature_key_iv = Base64.strict_encode64(cipher.random_iv)

      {
        shop_id: shop_id,
        queue_id: queue_id,
        signature_key_iv: signature_key_iv,
        signature_key_hash: Digest::MD5.hexdigest(signature_key), # may be unsafe, but we a guarding mostly against production data in development
        signature_key_enc: Base64.strict_encode64(cipher.update(signature_key) + cipher.final),
      }
    end

    def signature(http_method, full_url, body=nil)
      OpenSSL::HMAC.hexdigest(
          OpenSSL::Digest::MD5.new,
          @signature_key,
          "#{http_method.to_s.upcase}#{full_url}#{body}"
      )
    end

  end

end

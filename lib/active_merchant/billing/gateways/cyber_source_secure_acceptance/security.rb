require 'openssl'
require 'base64'

module ActiveMerchant
  module Billing
    module Security
      def self.generate_signature params, secret_key
        sign(build_data_to_sign(params), secret_key)
      end

      def self.valid? params
        signature = generate_signature params
        signature.strip.eql? params['signature'].strip
      end

      private

      def self.sign data, secret_key
        digest = OpenSSL::Digest::SHA256.new
        mac = OpenSSL::HMAC.new(secret_key, digest)
        mac << data
        Base64.encode64(mac.digest).gsub "\n", ''
      end

      def self.build_data_to_sign params
        signed_field_names = params[:signed_field_names].split ','
        data_to_sign = Array.new
        signed_field_names.each { |signed_field_name|
            data_to_sign << signed_field_name + '=' + params[signed_field_name.to_sym].to_s
        }
        comma_separate data_to_sign
      end

      def self.comma_separate data_to_sign
        csv = ''
        data_to_sign.length.times do |i|
          csv << data_to_sign[i]
          csv << ',' if i != data_to_sign.length-1
        end
        csv
      end
    end
  end
end
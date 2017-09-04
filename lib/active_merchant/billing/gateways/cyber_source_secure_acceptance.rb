require 'active_merchant/billing/gateways/cyber_source_secure_acceptance/security'
require 'nokogiri'
module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class CyberSourceSecureAcceptanceGateway < Gateway
      self.test_url = 'https://testsecureacceptance.cybersource.com/pay'
      self.live_url = 'https://secureacceptance.cybersource.com/pay'

      self.supported_cardtypes = [:visa, :master, :american_express, :discover, :diners_club, :jcb, :switch, :dankort, :maestro]
      self.supported_countries = %w(US BR CA CN DK FI FR DE JP MX NO SE GB SG LB)

      self.default_currency = 'USD'
      self.currencies_without_fractions = %w(JPY)

      self.homepage_url = 'http://www.cybersource.com'
      self.display_name = 'CyberSource'

      @@credit_card_codes = {
        :visa  => '001',
        :master => '002',
        :american_express => '003',
        :discover => '004',
        :diners_club => '005',
        :jcb => '007',
        :switch => '024',
        :dankort => '034',
        :maestro => '042'
      }

      @@response_codes = {
        :r100 => "Successful transaction",
        :r101 => "Request is missing one or more required fields" ,
        :r102 => "One or more fields contains invalid data",
        :r150 => "General failure",
        :r151 => "The request was received but a server time-out occurred",
        :r152 => "The request was received, but a service timed out",
        :r200 => "The authorization request was approved by the issuing bank but declined by CyberSource because it did not pass the AVS check",
        :r201 => "The issuing bank has questions about the request",
        :r202 => "Expired card",
        :r203 => "General decline of the card",
        :r204 => "Insufficient funds in the account",
        :r205 => "Stolen or lost card",
        :r207 => "Issuing bank unavailable",
        :r208 => "Inactive card or card not authorized for card-not-present transactions",
        :r209 => "American Express Card Identifiction Digits (CID) did not match",
        :r210 => "The card has reached the credit limit",
        :r211 => "Invalid card verification number",
        :r221 => "The customer matched an entry on the processor's negative file",
        :r230 => "The authorization request was approved by the issuing bank but declined by CyberSource because it did not pass the card verification check",
        :r231 => "Invalid account number",
        :r232 => "The card type is not accepted by the payment processor",
        :r233 => "General decline by the processor",
        :r234 => "A problem exists with your CyberSource merchant configuration",
        :r235 => "The requested amount exceeds the originally authorized amount",
        :r236 => "Processor failure",
        :r237 => "The authorization has already been reversed",
        :r238 => "The authorization has already been captured",
        :r239 => "The requested transaction amount must match the previous transaction amount",
        :r240 => "The card type sent is invalid or does not correlate with the credit card number",
        :r241 => "The request ID is invalid",
        :r242 => "You requested a capture, but there is no corresponding, unused authorization record.",
        :r243 => "The transaction has already been settled or reversed",
        :r244 => "The bank account number failed the validation check",
        :r246 => "The capture or credit is not voidable because the capture or credit information has already been submitted to your processor",
        :r247 => "You requested a credit for a capture that was previously voided",
        :r250 => "The request was received, but a time-out occurred with the payment processor",
        :r254 => "Your CyberSource account is prohibited from processing stand-alone refunds",
        :r255 => "Your CyberSource account is not configured to process the service in the country you specified"
      }

      def initialize(options = {})
        requires!(options, :login, :password, :secret_key)
        super
      end

      def authorize(money, creditcard_or_reference, options = {})
        setup_address_hash(options)
        commit(build_auth_request(money, creditcard_or_reference, options), :authorize, money, options )
      end

      def purchase(money, creditcard_or_reference, options = {})
        setup_address_hash(options)
        commit(build_purchase_request(money, creditcard_or_reference, options), :purchase, money, options )
      end

      private

      # Create all address hash key value pairs so that we still function if we
      # were only provided with one or two of them or even none
      def setup_address_hash(options)
        default_address = {
          :address1 => 'Unspecified',
          :city => 'Unspecified',
          :state => 'NC',
          :zip => '00000',
          :country => 'US'
        }
        options[:billing_address] = options[:billing_address] || options[:address] || default_address
        options[:shipping_address] = options[:shipping_address] || {}
      end

      def build_auth_request(money, creditcard_or_reference, options)
        request_hash = {}
        request_hash[:access_key] = @options[:password]
        request_hash[:profile_id] = @options[:login]
        request_hash[:transaction_uuid] = SecureRandom.hex(16)
        request_hash[:signed_field_names] = "access_key,profile_id,transaction_uuid,signed_field_names,unsigned_field_names,signed_date_time,locale,transaction_type,reference_number,amount,currency,payment_method,bill_to_forename,bill_to_surname,bill_to_email,bill_to_phone,bill_to_address_line1,bill_to_address_city,bill_to_address_state,bill_to_address_country,bill_to_address_postal_code"
        request_hash[:unsigned_field_names] = "card_type,card_number,card_expiry_date"
        request_hash[:locale] = "en"
        request_hash[:transaction_type] = "authorization"
        request_hash[:reference_number] = SecureRandom.rand(999999999999999)
        request_hash[:amount] = 100
        request_hash[:currency] = 'USD'
        request_hash[:payment_method] = 'card'
        request_hash[:bill_to_forename] = creditcard_or_reference.first_name
        request_hash[:bill_to_surname] = creditcard_or_reference.last_name
        request_hash[:bill_to_email] = options[:email]
        request_hash[:bill_to_phone] = "434424234234" 
        request_hash[:bill_to_address_line1] = "adasd 345"
        request_hash[:bill_to_address_city] = "Mountain View"
        request_hash[:bill_to_address_state] = "CA"
        request_hash[:bill_to_address_country] = "US"
        request_hash[:bill_to_address_postal_code] = "94043"
        #request_hash[:ignore_cvn] = "false"

        request_hash[:card_type] = @@credit_card_codes[card_brand(creditcard_or_reference).to_sym]
        request_hash[:card_number] = creditcard_or_reference.number
        request_hash[:card_expiry_date] = format(creditcard_or_reference.month, :two_digits) + "-" + format(creditcard_or_reference.year, :four_digits)

        #add_payment_method_or_subscription(request_hash, money, creditcard_or_reference, options)
        add_signature(request_hash, options)
        request_hash
      end

      def build_purchase_request(money, creditcard_or_reference, options)
        request_hash = {}
        request_hash[:access_key] = @options[:password]
        request_hash[:profile_id] = @options[:login]
        request_hash[:transaction_uuid] = SecureRandom.hex(16)
        request_hash[:signed_field_names] = "access_key,profile_id,transaction_uuid,signed_field_names,unsigned_field_names,signed_date_time,locale,transaction_type,reference_number,amount,currency,payment_method,bill_to_forename,bill_to_surname,bill_to_email,bill_to_phone,bill_to_address_line1,bill_to_address_city,bill_to_address_state,bill_to_address_country,bill_to_address_postal_code"
        request_hash[:unsigned_field_names] = "card_type,card_number,card_expiry_date"
        request_hash[:locale] = "en"
        request_hash[:transaction_type] = "sale"
        request_hash[:reference_number] = SecureRandom.rand(999999999999999)
        
        add_payment_method_or_subscription(request_hash, money, creditcard_or_reference, options)
        add_signature(request_hash, options)
        request_hash
      end

      def add_purchase_data(request_hash, money = 0, include_grand_total = false, options={})
        request_hash[:amount] = 100 #localized_amount(money.to_i, options[:currency] || default_currency)
        request_hash[:currency] = options[:currency] || currency(money)
      end

      def add_address(request_hash, payment_method, address, options, shipTo = false)
        request_hash.merge!({
          bill_to_forename: payment_method.first_name,
          bill_to_surname: payment_method.last_name,
          bill_to_email: options[:email],
          bill_to_phone: address[:phone],
          bill_to_address_line1: address[:address1],
          bill_to_address_city: address[:city],
          bill_to_address_state: address[:state],
          bill_to_address_country: address[:country],
          bill_to_address_postal_code: address[:zip]
        })
      end

      def add_creditcard(request_hash, creditcard)
        request_hash.merge!({
          card_type: @@credit_card_codes[card_brand(creditcard).to_sym],
          card_number: creditcard.number,
          card_expiry_date: format(creditcard.month, :two_digits) + "-" + format(creditcard.year, :four_digits),
          card_cvn: creditcard.verification_value
        })
      end

      def add_creditcard_payment_method(request_hash)
        request_hash[:payment_method] = 'card'
      end

      def add_payment_method_or_subscription(request_hash, money, payment_method_or_reference, options)
        if payment_method_or_reference.is_a?(String)
          add_purchase_data(request_hash, money, true, options)
          #add_subscription(xml, options, payment_method_or_reference)
        elsif card_brand(payment_method_or_reference) == 'check'
          add_address(request_hash, payment_method_or_reference, options[:billing_address], options)
          add_purchase_data(request_hash, money, true, options)
          #add_check(xml, payment_method_or_reference)
        else
          add_purchase_data(request_hash, money, true, options)
          add_creditcard_payment_method(request_hash)
          add_address(request_hash, payment_method_or_reference, options[:billing_address], options)
          add_creditcard(request_hash, payment_method_or_reference)
        end
      end

      def generate_signature(request_hash)
        Security.generate_signature(request_hash, @options[:secret_key])
      end

      def add_signature(request_hash, options)
        current_utc_xml_date_time = Time.now.utc.strftime "%Y-%m-%dT%H:%M:%S%z"
        current_utc_xml_date_time = current_utc_xml_date_time[0, current_utc_xml_date_time.length-5]
        current_utc_xml_date_time << 'Z'
        
        request_hash[:signed_date_time] = current_utc_xml_date_time
        request_hash[:signature] = generate_signature(request_hash)
      end

      def commit(request, action, amount, options)
        byebug
        begin
          resp = parse_pay(ssl_post(test? ? self.test_url : self.live_url, build_request(request)))
          response = ssl_post('https://testsecureacceptance.cybersource.com/checkout_update', build_request(resp), { 'Cookie' => @cookie })

        rescue ResponseError => e
          response = parse(e.response.body)
        end

        success = response[:decision] == "ACCEPT"
        message = response[:message]

        authorization = success ? [response[:auth_trans_ref_no], response[:request_token], action, amount, options[:currency]].compact.join(";") : nil

        Response.new(success, message, response,
          :test => test?,
          :authorization => authorization,
          :avs_result => { :code => response[:auth_avs_code] },
          :cvv_result => response[:cvCode]
        )
      end

      def build_request(params)
        return nil unless params

        params.map do |key, value|
          next if value.blank?
          "#{key}=#{CGI.escape(value.to_s)}"
        end.compact.join("&")
      end

      def parse_pay(html)
        byebug
        doc = Nokogiri::HTML(html)
        a = doc.xpath("//input[@type!='submit' and @type!='button']").inject({}){|m, v| m.merge({v.attr(:name).to_sym => v.attr(:value)}) }
        b = doc.xpath("//select").inject({}){|m, v| m.merge({v.attr(:name).to_sym => v.attr(:value)}) }
        a.merge(b).merge({
          card_cvn: '123', 
          card_type: '001',
          card_expiry_month: '12',
          card_expiry_year: '2022',
          customer_utc_offset: '180'
        })
      end

      def parse(html)
        #card_number_masked???
        #card_cvn_masked???
        #authenticity_token
        #session_uuid
        #payment_method
        #card_type
        #card_number???
        #card_cvn
        #customer_utc_offset???
        #card_expiry_month
        #card_expiry_year

        byebug
        doc = Nokogiri::HTML(html)
        doc.xpath("//input[@type!='submit' and @type!='button']").inject({}){|m, v| m.merge({v.attr(:name).to_sym => v.attr(:value)}) }
      end

      def build_checkout_request(params)
      end

      def handle_response(response)
        case response.code.to_i
        when 200...300
          response.body
        when 302
          handle_redirect(response)
        else
          raise ResponseError.new(response)
        end
      end

      def handle_redirect(response)
        @cookie = response['Set-Cookie']
        cookie = response['Set-Cookie']
        uri_str = response['location']
        url = URI.parse(uri_str)
        http = Net::HTTP.new(url.host, url.port)
        params = { 'Accept' => '*/*', 'Cookie' => cookie }
        request = Net::HTTP::Get.new(url.path, params)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        r = http.request(request)
        r.body
      end

      def reason_message(reason_code)
        return if reason_code.blank?
        @@response_codes[:"r#{reason_code}"]
      end
    end
  end
end

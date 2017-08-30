require 'test_helper'
require 'nokogiri'

class CyberSourceSecureAcceptanceTest < Test::Unit::TestCase
  include CommStub

  def setup
    Base.mode = :test

    @gateway = CyberSourceSecureAcceptanceGateway.new(fixtures(:cyber_source_secure_acceptance))

    @amount = 100
    @credit_card = credit_card('4111111111111111', :brand => 'visa')
    @declined_card = credit_card('801111111111111', :brand => 'visa')

    @options = {
      :currency => 'USD'
    }
  end

  def test_successful_auth_request
    @gateway.stubs(:ssl_post).returns(successful_authorization_response)
    assert response = @gateway.authorize(@amount, @credit_card, @options)
    assert_equal Response, response.class
    assert response.success?
    assert response.test?
  end

  def test_default_currency
    assert_equal 'USD', CyberSourceSecureAcceptanceGateway.default_currency
  end

  private

  def successful_authorization_response
    <<-HTML
      <form id="custom_redirect" action="http://9cdd97ac.ngrok.io/receipt" accept-charset="UTF-8" method="post"><input name="utf8" type="hidden" value="&#x2713;" />
        <input type="hidden" name="req_card_number" id="req_card_number" value="xxxxxxxxxxxx1111" />
        <input type="hidden" name="req_locale" id="req_locale" value="en" />
        <input type="hidden" name="signature" id="signature" value="AqKGVfTlJyXKHZl0WUHsmBqCtRUpul91FZISXywnU3A=" />
        <input type="hidden" name="auth_trans_ref_no" id="auth_trans_ref_no" value="5040439007026572404107" />
        <input type="hidden" name="req_bill_to_surname" id="req_bill_to_surname" value="Longsen" />
        <input type="hidden" name="req_bill_to_address_city" id="req_bill_to_address_city" value="Mountain View" />
        <input type="hidden" name="req_card_expiry_date" id="req_card_expiry_date" value="12-2022" />
        <input type="hidden" name="req_bill_to_address_postal_code" id="req_bill_to_address_postal_code" value="94043" />
        <input type="hidden" name="req_bill_to_phone" id="req_bill_to_phone" value="323232332" />
        <input type="hidden" name="reason_code" id="reason_code" value="100" />
        <input type="hidden" name="auth_amount" id="auth_amount" value="1.00" />
        <input type="hidden" name="auth_response" id="auth_response" value="00" />
        <input type="hidden" name="req_bill_to_forename" id="req_bill_to_forename" value="Longbob" />
        <input type="hidden" name="req_payment_method" id="req_payment_method" value="card" />
        <input type="hidden" name="request_token" id="request_token" value="Ahj/7wSTET4km4ARf6WLQizVg0YNGblgwbsGTZq3ZNGDRiwbpcdgF1JQClx2AXUlaQHyOJMMmkmXoxXM+eQJyYifEk3ACL/SxYAAGCjc" />
        <input type="hidden" name="auth_time" id="auth_time" value="2017-08-29T215820Z" />
        <input type="hidden" name="req_amount" id="req_amount" value="1.00" />
        <input type="hidden" name="req_bill_to_email" id="req_bill_to_email" value="test@activemerchant.com" />
        <input type="hidden" name="auth_avs_code_raw" id="auth_avs_code_raw" value="Y" />
        <input type="hidden" name="transaction_id" id="transaction_id" value="5040439007026572404107" />
        <input type="hidden" name="req_currency" id="req_currency" value="USD" />
        <input type="hidden" name="req_card_type" id="req_card_type" value="001" />
        <input type="hidden" name="decision" id="decision" value="ACCEPT" />
        <input type="hidden" name="message" id="message" value="Request was processed successfully." />
        <input type="hidden" name="signed_field_names" id="signed_field_names" value="transaction_id,decision,req_access_key,req_profile_id,req_transaction_uuid,req_transaction_type,req_reference_number,req_amount,req_currency,req_locale,req_payment_method,req_bill_to_forename,req_bill_to_surname,req_bill_to_email,req_bill_to_phone,req_bill_to_address_line1,req_bill_to_address_city,req_bill_to_address_state,req_bill_to_address_country,req_bill_to_address_postal_code,req_card_number,req_card_type,req_card_expiry_date,message,reason_code,auth_avs_code,auth_avs_code_raw,auth_response,auth_amount,auth_code,auth_trans_ref_no,auth_time,request_token,signed_field_names,signed_date_time" />
        <input type="hidden" name="req_transaction_uuid" id="req_transaction_uuid" value="dfb21b42b76ae854ac4613fb43eb4838" />
        <input type="hidden" name="auth_avs_code" id="auth_avs_code" value="Y" />
        <input type="hidden" name="auth_code" id="auth_code" value="831000" />
        <input type="hidden" name="req_bill_to_address_country" id="req_bill_to_address_country" value="US" />
        <input type="hidden" name="req_transaction_type" id="req_transaction_type" value="authorization" />
        <input type="hidden" name="req_access_key" id="req_access_key" value="56371a9ca74e397da3e214c0e31ceb48" />
        <input type="hidden" name="req_profile_id" id="req_profile_id" value="098D7786-1A3B-4B88-9B1B-D0B14CFD1CA8" />
        <input type="hidden" name="req_reference_number" id="req_reference_number" value="467422689692129" />
        <input type="hidden" name="req_bill_to_address_state" id="req_bill_to_address_state" value="CA" />
        <input type="hidden" name="signed_date_time" id="signed_date_time" value="2017-08-29T21:58:20Z" />
        <input type="hidden" name="req_bill_to_address_line1" id="req_bill_to_address_line1" value="False Street" />
      </form>
    HTML
  end

  def unsuccessful_authorization_response
  end
end

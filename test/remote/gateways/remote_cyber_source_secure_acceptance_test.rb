require 'test_helper'
require "byebug"
class RemoteCyberSourceSecureAcceptanceTest < Test::Unit::TestCase
  def setup
    Base.mode = :test

    @gateway = CyberSourceSecureAcceptanceGateway.new(fixtures(:cyber_source_secure_acceptance))
    @credit_card = credit_card('4111111111111111', verification_value: '123', month: 12, year: 2022, first_name: 'noreal', last_name: 'name')
    @declined_card = credit_card('801111111111111')
    @amount = 100
    @options = {
      :currency => 'USD',
      :ignore_avs => 'true',
      :ignore_cvv => 'false',
      :email => "null@cybersource.com",
      :phone => "323232332",
      :address => {
        :address1 => '1295 Charleston Road',
        :city => 'Mountain View',
        :state => 'CA',
        :zip => '94043',
        :country => 'US'
      }
    }
  end

  def test_successful_authorization
    assert response = @gateway.authorize(@amount, @credit_card, @options)
    assert_equal 'Request was processed successfully.', response.message
    assert_success response
    assert response.test?
    assert !response.authorization.blank?
  end
=begin
  def test_unsuccessful_authorization
    assert response = @gateway.authorize(@amount, @declined_card, @options)
    assert response.test?
    assert_equal 'Request parameters are invalid or missing', response.message
    assert_equal false,  response.success?
  end

  def test_successful_purchase
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_equal 'Request was processed successfully.', response.message
    assert_success response
    assert response.test?
  end

  def test_unsuccessful_purchase
    assert response = @gateway.purchase(@amount, @declined_card, @options)
    assert response.test?
    assert_equal 'Request parameters are invalid or missing', response.message
    assert_equal false,  response.success?
  end
=end
end

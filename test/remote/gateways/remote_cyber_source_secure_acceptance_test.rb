require 'test_helper'
require "byebug"
class RemoteCyberSourceSecureAcceptanceTest < Test::Unit::TestCase
  def setup
    Base.mode = :test

    @gateway = CyberSourceSecureAcceptanceGateway.new(fixtures(:cyber_source_secure_acceptance))

    @credit_card = credit_card('4111111111111111', verification_value: '123', month: 12, year: 2022)
    @declined_card = credit_card('801111111111111')
    @pinless_debit_card = credit_card('4002269999999999')

    @amount = 100

    @options = {
      :currency => 'USD',
      :ignore_avs => 'true',
      :ignore_cvv => 'true',
      :email => "test@activemerchant.com",
      :phone => "323232332",
      :address => {
        :address1 => 'False Street',
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

  #def test_unsuccessful_authorization
  #  assert response = @gateway.authorize(@amount, @declined_card, @options)
  #  assert response.test?
  #  assert_equal 'Invalid account number', response.message
  #  assert_equal false,  response.success?
  #end
end

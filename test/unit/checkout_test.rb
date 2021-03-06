require 'test_helper'

class CheckoutTest < ActiveSupport::TestCase
  fixtures :gateways

  should_belong_to :bill_address
  should_not_allow_values_for :email, "blah", "b lah", "blah@blah"
  
  context Checkout do
    setup { @checkout = Factory(:checkout) }
    context "in payment state w/no auto capture" do
      setup do 
        @checkout.state = "payment"
        Spree::Config.set(:auto_capture => false) 
      end
      context "next" do
        setup { @checkout.next! }
        should_change("@checkout.state", :to => "complete") { @checkout.state }
        should_change("@checkout.order.completed_at", :from => nil) { @checkout.order.completed_at }
        should_change("@checkout.order.state", :from => "in_progress", :to => "new") { @checkout.order.state }        
        should_change("@checkout.order.creditcard_payments.count", :by => 1) { @checkout.order.creditcard_payments.count }
        should_change("CreditcardTxn.count", :by => 1) { CreditcardTxn.count }
      end
      context "next with declineable creditcard" do
        setup do
          @checkout.creditcard.number = "4111111111111110"
          begin @checkout.next! rescue Spree::GatewayError end
        end
        should_not_change("Creditcard.count") { Creditcard.count }
        should_not_change("CreditcardPayment.count") { CreditcardPayment.count }
        should_not_change("CreditcardTxn.count") { CreditcardTxn.count }
        should_not_change("@checkout.state") { @checkout.state }
      end
    end
    context "in payment state w/auto capture" do
      setup do    
        @order = Factory(:order_with_totals)
        @checkout = Factory(:checkout, :order => @order, :state => "payment")
        Spree::Config.set(:auto_capture => true) 
      end
      context "next" do
        setup { @checkout.next! }
        should_change("@checkout.state", :to => "complete") { @checkout.state }
        should_change("@checkout.order.completed_at", :from => nil) { @checkout.order.completed_at }
        should_change("@checkout.order.state", :from => "in_progress", :to => "paid") { @checkout.order.state }        
        should_change("@checkout.order.creditcard_payments.count", :by => 1) { @checkout.order.creditcard_payments.count }
        should_change("CreditcardTxn.count", :by => 1) { CreditcardTxn.count }
      end
    end
  end
end

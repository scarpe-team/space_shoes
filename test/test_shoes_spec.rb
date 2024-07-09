# frozen_string_literal: true

require "test_helper"

# Use Capybara and Selenium to run ShoesSpec tests
class Scarpe::TestShoesSpecInfrastructure < SpaceShoesPackagedTest
  def test_basic_sspec_test_succeeds
    with_app("/sspec_test.html") do
      assert_selector("div.minitest_result", wait: 5)
      result = page.evaluate_script('document.shoes_spec.passed')
      assert_equal true, result
    end
  end
end

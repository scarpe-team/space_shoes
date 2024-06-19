# frozen_string_literal: true

require "test_helper"

# These tests start up Selenium and headless Chrome. They
# run a local build of SpaceShoes and then check Capybara
# assertions (based on Selenium) for what DOM elements
# appear, and run Capybara actions to do things like press
# buttons.
class Scarpe::TestUnifiedPackageWasm < SpaceShoesPackagedTest
  def test_app_runs
    with_app("/app_tiny_button.html") do
      assert_selector("button")
    end
  end

  def test_button_creates_alert
    with_app("/app_tiny_button.html") do
      assert_selector("button")
      assert_no_text("Aha!")
      click_button("OK")
      assert_text("Aha!")
    end
  end

#  def test_widgets_exist
#    with_app("widgets_basic") do
#      assert_selector("button", wait: 5)
#      assert_text("Here I am")
#      assert_text("Push me")
#      assert_text("I am an alert")
#      assert page.html.include?("edit_line here")
#    end
#  end
end

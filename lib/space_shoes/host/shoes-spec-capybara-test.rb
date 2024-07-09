# frozen_string_literal: true

# For Capybara/Minitest testing
require "minitest"
require "selenium-webdriver"
require "scarpe/components/unit_test_helpers"
require "capybara"
require "capybara/minitest"

Capybara.register_driver :logging_selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_option("goog:loggingPrefs", {browser: 'ALL'})
  options.add_argument("--headless")

  Capybara::Selenium::Driver.new(app,
                                 options:,
                                 browser: :chrome,
                                 )
end
Capybara.default_driver = :logging_selenium_chrome_headless
Capybara.run_server = false
Capybara.app_host = "http://localhost:8080"
# In setup, this will change the Capybara driver
#Capybara.current_driver = :selenium_headless # example: use headless Firefox

# SpaceShoes Shoes-Spec test
module SpaceShoes
  class ShoesSpecTest < Minitest::Test
    include Scarpe::Test::Helpers
    include Capybara::DSL
    include Capybara::Minitest::Assertions

    # Make sure to call super in child-class teardown if there is one
    def teardown
      Capybara.reset_sessions!
      Capybara.use_default_driver
      super if defined?(super)
    end
  end
end

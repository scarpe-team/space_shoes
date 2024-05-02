# frozen_string_literal: true

# Can set in individual tests *before* requiring test_helper. Otherwise it will default to space_shoes.
ENV["SCARPE_DISPLAY_SERVICE"] ||= "space_shoes"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "space_shoes"

require "fileutils"
require "socket"

require 'selenium-webdriver'

require "scarpe/components/unit_test_helpers"
#require_relative "../lib/scarpe/space_shoes/shoes-spec"

## Capybara Setup

require "capybara"
require 'capybara/minitest'

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

require "minitest/autorun"

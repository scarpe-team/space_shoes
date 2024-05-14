# frozen_string_literal: true

# Can set in individual tests *before* requiring test_helper. Otherwise it will default to space_shoes.
ENV["SCARPE_DISPLAY_SERVICE"] ||= "space_shoes"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "space_shoes/host/packaging"

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

class SpaceShoesCLITest < Minitest::Test
  ROOT_DIR = File.expand_path(File.join(__dir__, ".."))

  include Scarpe::Test::Helpers
  include Scarpe::Components::ProcessHelpers # May be patched via space_shoes/packaging.rb!

  def out_or_fail(cmd)
    out, err, success = run_out_err_result(cmd)
    unless success
      STDERR.puts "Output:\n#{out}\n=======\n#{err}\n=======\n"
      raise SpaceShoes::Error, "Failed while trying to run command: #{cmd.inspect}"
    end
    out
  end
end

require "minitest/autorun"

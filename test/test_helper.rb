# frozen_string_literal: true

# Can set in individual tests *before* requiring test_helper. Otherwise it will default to space_shoes.
ENV["SCARPE_DISPLAY_SERVICE"] ||= "space_shoes"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

SPACESHOES_ROOT = File.expand_path("..", __dir__)

require "space_shoes/host/packaging"

require "fileutils"
require "socket"

require 'selenium-webdriver'

require "scarpe/components/unit_test_helpers"
#require_relative "../lib/scarpe/space_shoes/shoes-spec"

## Capybara Setup

require "capybara"
require 'capybara/minitest'

# Submit a PR to Scarpe-Components?
module Scarpe::Components
  module PortUtils
    MAX_SERVER_STARTUP_WAIT = 5.0

    def port_working?(ip, port_num)
      begin
        TCPSocket.new(ip, port_num)
      rescue Errno::ECONNREFUSED
        return false
      end
      return true
    end

    def wait_until_port_working(ip, port_num, max_wait: MAX_SERVER_STARTUP_WAIT)
      t_start = Time.now
      loop do
        if Time.now - t_start > max_wait
          raise "Server on port #{port_num} didn't start up in time!"
        end

        sleep 0.1
        return if port_working?(ip, port_num)
      end
    end
  end
end

SS_TEST_DATA = { wasm_build: false, }

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

class SSCapybaraTestCase < Minitest::Test
  include Capybara::DSL
  include Capybara::Minitest::Assertions

  # Make sure to call super in child-class teardown if there is one
  def teardown
    Capybara.reset_sessions!
    Capybara.use_default_driver
    super if defined?(super)
  end

  # Run the ShoesSpec code within the supplied block
  #
  # @raise [Shoes::Error,Scarpe::Error,SpaceShoes::Error] Exception raised if the application didn't start or the spec code raises an uncaught exception
  #
  # @yield the code to run using the ShoesSpec API
  def run_shoes_spec_code(index_uri = nil)
    visit(index_uri) if index_uri

    if has_selector?("#wrapper-wvroot div", wait: 10, visible: :all)
      # Load Shoes-Spec test code into the browser as Wasm
      page.execute_script "window.RubyVM.eval('require \"spaceshoes/guest/shoes-spec-browser\"')"

      yield
    else
      require 'pp'
      logs = page.driver.browser.logs.get(:browser)
      reduced_logs = logs.select do |log|
        log.level != "INFO" &&
          (log.level != "WARNING" || !log.message.include?("its extensions are not built"))
      end.map { |log| [log.level, log.message] }
      severe_logs = logs.select { |log| log.level == "SEVERE" }
      severe_msgs = severe_logs.map(&:message)
      STDERR.puts "LOGS:\n#{pp reduced_logs}"

      # Looks like the Shoes app never loaded
      # TODO: add a proper error class for this to Lacci and/or Scarpe-Wasm
      page_body = page.evaluate_script("document.body.outerHTML")
      raise Shoes::Error, "Scarpe-Wasm application never started! #{page_body} SEVERE LOGS: #{severe_msgs.inspect}"
    end
  end
end

class SpaceShoesPackagedTest < SSCapybaraTestCase
  TEST_CACHE_DIR = File.expand_path(File.join __dir__, "cache")

  include Scarpe::Components::PortUtils

  def setup
    build_wasm_package
  end

  def build_wasm_package
    return if SS_TEST_DATA[:wasm_built]
    SS_TEST_DATA[:wasm_built] = true

    Dir.chdir(SPACESHOES_ROOT) do
      system("./exe/space-shoes --dev build-default")
    end
    #Dir.chdir(TEST_CACHE_DIR) do
    #end
  end

  def with_app(url, &block)
    server_pid = nil
    Dir.chdir(TEST_CACHE_DIR) do
      server_pid = Kernel.spawn("bundle exec ruby -run -e httpd . -p 8080")
      wait_until_port_working("127.0.0.1", 8080)

      visit(url)
      assert_selector("#wrapper-wvroot", wait: 5)
      assert_selector("#wrapper-wvroot div", wait: 5)

      yield
    end
  ensure
    Process.kill(9, server_pid) if server_pid
  end
end

require "minitest/autorun"

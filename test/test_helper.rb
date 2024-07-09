# frozen_string_literal: true

# Can set in individual tests *before* requiring test_helper. Otherwise it will default to space_shoes.
ENV["SCARPE_DISPLAY_SERVICE"] ||= "space_shoes"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

SPACESHOES_ROOT = File.expand_path("..", __dir__)

require "space_shoes/host/packaging"

require "fileutils"
require "socket"

require "scarpe/components/unit_test_helpers"
#require_relative "../lib/scarpe/space_shoes/shoes-spec"

require "space_shoes/host/shoes-spec-capybara-test"

SS_TEST_DATA = { wasm_built: false, }

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

class SpaceShoesPackagedTest < SpaceShoes::ShoesSpecTest
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

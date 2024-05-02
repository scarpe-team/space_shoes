# frozen_string_literal: true

require "test_helper"

class TestSpaceShoes < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::SpaceShoes::VERSION
  end
end

class TestSpaceShoesCommand < Minitest::Test
  ROOT_DIR = File.expand_path(File.join(__dir__, ".."))

  def out_or_fail(cmd)
    out = `#{cmd}`
    unless $?.success?
      raise SpaceShoes::Error, "Failed while trying to run command: #{cmd.inspect}"
    end
    out
  end

  def test_space_shoes_cmd_with_dash_v
    Dir.chdir(ROOT_DIR) do
      out = out_or_fail "exe/space_shoes --dev -v"
      assert_includes out, "SpaceShoes"
      assert_includes out, "Scarpe-Components"
      assert_includes out, "Lacci"
    end
  end

  def test_space_shoes_dash_cmd
    Dir.chdir(ROOT_DIR) do
      out = out_or_fail "exe/space-shoes --dev -v"
      assert_includes out, "SpaceShoes"
    end
  end
end

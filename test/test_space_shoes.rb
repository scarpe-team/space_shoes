# frozen_string_literal: true

require "test_helper"

class TestSpaceShoes < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::SpaceShoes::VERSION
  end
end

class TestSpaceShoesSimpleCommands < SpaceShoesCLITest
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

  def test_space_shoes_env
    Dir.chdir(ROOT_DIR) do
      out = out_or_fail "exe/space_shoes --dev env"
      assert_includes out, "SpaceShoes environment"
      assert_includes out, "Ruby and Shell environment"
    end
  end
end

class TestSpaceShoesBuild < SpaceShoesCLITest
  def test_space_shoes_build_ruby_basic
    Dir.chdir(ROOT_DIR) do
      out = out_or_fail "exe/space-shoes --dev build-ruby"
    end
  end

  def test_space_shoes_build_ruby_basic
    Dir.chdir(ROOT_DIR) do
      out = out_or_fail "exe/space-shoes --dev build-default"
    end
  end
end

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

  def test_space_shoes_js_spacewalk_default
    Dir.chdir(ROOT_DIR) do
      begin
        out = out_or_fail "exe/space_shoes --dev js-spacewalk"
        assert_includes out, "Copied spacewalk.js file to"
      ensure
        FileUtils.rm_f "spacewalk.js" rescue nil
      end
    end
  end

  def test_space_shoes_js_spacewalk_target
    Dir.chdir(ROOT_DIR) do
      begin
        out = out_or_fail "exe/space_shoes --dev js-spacewalk out_spacewalk.js"
        assert_includes out, "Copied spacewalk.js file to"
        assert_includes out, "out_spacewalk.js"
      ensure
        FileUtils.rm_f "out_spacewalk.js" rescue nil
      end
    end
  end
end

class TestSpaceShoesBuild < SpaceShoesCLITest
  def test_space_shoes_build_ruby_default
    Dir.chdir(ROOT_DIR) do
      out_or_fail "exe/space-shoes --dev build-default"
      assert File.exist?("packaging/packed_ruby.wasm"), "In build-default, didn't create packed_ruby.wasm"
      assert File.exist?("packaging/spacewalk.js"), "In build-default, didn't create spacewalk.js"
    end
  end
end

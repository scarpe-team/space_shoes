# frozen_string_literal: true

require "test_helper"

class TestSpaceShoes < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::SpaceShoes::VERSION
  end
end

class TestSpaceShoesCommand
  def test_with_dash_v
  end
end

# frozen_string_literal: true

# Anything in this file is intended to be required by *both* the
# App-Side and Host-Side SpaceShoes environments.

require_relative "version"

module SpaceShoes
  class Error < StandardError; end
end

# Guest errors, used by Wasm code
module SpaceShoes::Errors
  class MissingDocRootError < SpaceShoes::Error; end
  class BadDisplayClassType < SpaceShoes::Error; end
  class MissingClassError < SpaceShoes::Error; end
  class MissingAttributeError < SpaceShoes::Error; end
  class DuplicateCallbackError < SpaceShoes::Error; end
  class UnknownEventTypeError < SpaceShoes::Error; end
  class UnknownShoesEventAPIError < SpaceShoes::Error; end
end

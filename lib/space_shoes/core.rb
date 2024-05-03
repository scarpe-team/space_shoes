# frozen_string_literal: true

# Anything in this file is intended to be required by *both* the
# App-Side and Host-Side SpaceShoes environments.

require_relative "version"

module SpaceShoes
  class Error < StandardError; end
end

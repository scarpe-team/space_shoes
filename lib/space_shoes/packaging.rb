# frozen_string_literal: true

require "space_shoes/core"

require "scarpe/components/file_helpers"
require "scarpe/components/process_helpers"

module SpaceShoes
  SOURCE_ROOT = File.expand_path(File.join(__dir__, "../.."))
  PACKAGING_ROOT = File.expand_path(File.join(SOURCE_ROOT, "packaging"))

  module Packaging;end

  module PackagingCommands
    include Scarpe::Components::ProcessHelpers

    def run_or_raise(cmd)
      out, err, success = run_out_err_result(cmd)
      unless success
        STDERR.puts "Running #{cmd.inspect} failed in dir #{Dir.pwd.inspect}!\n=======\n#{out}\n=======\n#{err}\n=======\n"
        raise SpaceShoes::Error, "Failed while trying to run command: #{cmd.inspect}"
      end
      out
    end

    # This builds unconditionally, and is very slow the first time.
    # TODO: move the built ruby.wasm binary to a shared dir outside the packaging dirs.
    def build_ruby_wasm_binary
      Dir.chdir(PACKAGING_ROOT) do
        # Use the packaging dir's Bundler setup, not what the outer program was run with
        Bundler.with_unbundled_env do
          run_or_raise("bundle exec rbwasm build -o ruby.wasm")
        end
      end
    end

    def build_ruby_wasm_binary_if_stale
      Dir.chdir(PACKAGING_ROOT) do
      end
    end

    # Note: built Ruby and packed Ruby+source package should *both* be outside the app dir (a.k.a. src dir)
    def build_default_wasm_package
      build_ruby_wasm_binary
      Dir.chdir(PACKAGING_ROOT + "/default") do
        # Does this wind up double-packaging anything? Do we need a src subdir to make this work?
        run_or_raise("bundle exec rbwasm pack ../ruby.wasm --mapdir /src::. -o ../packed_ruby.wasm")
      end
    end

    Packaging.extend PackagingCommands
  end
end

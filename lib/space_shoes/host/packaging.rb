# frozen_string_literal: true

require "space_shoes/core"

require "scarpe/components/file_helpers"
require "scarpe/components/process_helpers"

require "ruby_wasm/version"

module SpaceShoes
  module Packaging
    include Scarpe::Components::ProcessHelpers

    SOURCE_ROOT = File.expand_path(File.join(__dir__, "../../.."))
    PACKAGING_ROOT = File.join(SOURCE_ROOT, "packaging")
    LIB_ROOT = File.join(SOURCE_ROOT, "lib")

    private

    def run_or_raise(cmd)
      out, err, success = run_out_err_result(cmd)
      unless success
        STDERR.puts "Running #{cmd.inspect} failed in dir #{Dir.pwd.inspect}!\n=======\n#{out}\n=======\n#{err}\n=======\n"
        raise SpaceShoes::Error, "Failed while trying to run command: #{cmd.inspect}"
      end
      out
    end

    public

    def write_spacewalk_file(out_file:)
      spacewalk_file = File.join(SOURCE_ROOT, "test/cache/spacewalk.js")
      FileUtils.cp spacewalk_file, out_file
      out_file
    end

    def build_packed_wasm_file(pack_root: ".", out_file:)
      unless File.exist?(pack_root) && File.directory?(pack_root)
        raise SpaceShoes::Error, "Can't pack wasm file when source directory doesn't exist! source path: #{pack_root.inspect}"
      end

      out_dir = File.dirname(out_file)
      unless File.exist?(out_dir) && File.directory?(out_dir)
        raise SpaceShoes::Error, "Can't pack wasm file when output directory doesn't exist! output path: #{out_dir.inspect}"
      end

      Dir.chdir(pack_root) do
        # Use the packaging dir's Bundler setup, not what the outer program was run with
        Bundler.with_unbundled_env do
          FileUtils.rm out_file if File.exist?(out_file)
          run_or_raise("bundle exec rbwasm build -o #{out_file}")
        end
      end

      out_file
    end

    # Note: packed Ruby+source package should be outside the app dir (a.k.a. src dir)
    def build_default_wasm_package
      out_file = PACKAGING_ROOT + "/packed_ruby.wasm"

      # without parens on this call, Ruby grabs the next line as part of this one. Weird.
      build_packed_wasm_file(pack_root: PACKAGING_ROOT, out_file:)

      out_file
    end
  end
end

# frozen_string_literal: true

# WHY DO REPEATED BUILDS OF RUBY KEEP MAKING IT BIGGER IN CACHE DIR?

require "space_shoes/core"

require "scarpe/components/file_helpers"
require "scarpe/components/process_helpers"

require "ruby_wasm/version"

# Okay, we're picking up a bunch of intermediate build files
# and I'm not sure what to do with it. Gemfiles aren't always
# easy to relocate. We can remove all intermediate files?
# But then it's a full clean build-from-nothing every time,
# which is very slow.
#
# We could write the packed-Ruby-plus-gems file outside the
# app dir, but actually that's one of the ones we *want*
# there, so I'm not sure that's useful. If we do the Ruby
# build in a different non-app dir, that would keep the
# intermediate files from being packed. But then we need
# the Gemfile and Gemfile.lock to be relocatable to a new dir.
#
# While rbwasm pack looks like it should allow packing
# only specified files, that doesn't seem to happen. Other
# files not given to the CLI but in the same dir seem to
# be picked up by rbwasm pack, which is the same as
# wasi-vfs pack.

module SpaceShoes
  module Packaging
    include Scarpe::Components::ProcessHelpers

    SOURCE_ROOT = File.expand_path(File.join(__dir__, "../../.."))
    PACKAGING_ROOT = File.join(SOURCE_ROOT, "packaging")
    if ENV["HOME"] && File.exist?(ENV["HOME"])
      BUILT_RUBY_CACHE_DIR = File.expand_path(File.join(ENV["HOME"], ".space_shoes"))
    else
      BUILT_RUBY_CACHE_DIR = SOURCE_ROOT # This isn't great, but it'll sometimes do
    end
    BUILT_RUBY_WASM = File.join(BUILT_RUBY_CACHE_DIR, "ruby.wasm")

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

    def packaging_setup
      unless File.exist?(BUILT_RUBY_CACHE_DIR)
        FileUtils.mkdir_p BUILT_RUBY_CACHE_DIR
      end
    end

    public

    # This builds unconditionally, and is very slow the first time.
    def build_ruby_wasm_binary
      packaging_setup

      Dir.chdir(PACKAGING_ROOT) do
        FileUtils.rm(BUILT_RUBY_WASM) if File.exist?(BUILT_RUBY_WASM)

        # Use the packaging dir's Bundler setup, not what the outer program was run with
        Bundler.with_unbundled_env do
          run_or_raise("bundle exec rbwasm build -o #{BUILT_RUBY_WASM}")
        end
      end
    end

    def build_packed_wasm_file(
      pack_root: ".",
      built_ruby: BUILT_RUBY_WASM,
      out_file:,
      map_dirs: {
        "/src" => ".",
        "/spaceshoes_lib" => LIB_ROOT,
      }
      )
      packaging_setup

      unless File.exist?(built_ruby)
        raise SpaceShoes::Error, "Can't pack wasm file when built Ruby doesn't exist! ruby path: #{built_ruby.inspect}"
      end

      unless File.exist?(pack_root) && File.directory?(pack_root)
        raise SpaceShoes::Error, "Can't pack wasm file when source directory doesn't exist! source path: #{pack_root.inspect}"
      end

      out_dir = File.dirname(out_file)
      unless File.exist?(out_dir) && File.directory?(out_dir)
        raise SpaceShoes::Error, "Can't pack wasm file when output directory doesn't exist! output path: #{out_dir.inspect}"
      end

      FileUtils.rm(out_file) if File.exist?(out_file)

      if map_dirs.nil? || map_dirs.empty?
        map_dirs_args = ""
      else
        map_dirs_args = "--mapdir " + map_dirs.map { |guest, host| "#{guest}::#{host}" }.join(" ")
      end

      Dir.chdir(pack_root) do
        run_or_raise("bundle exec rbwasm pack #{built_ruby} #{map_dirs_args} -o #{out_file}")
      end
    end

    # Note: packed Ruby+source package should be outside the app dir (a.k.a. src dir)
    def build_default_wasm_package
      out_file = PACKAGING_ROOT + "/packed_ruby.wasm"

      # without parens on this call, Ruby grabs the next line as part of this one. Weird.
      build_packed_wasm_file(pack_root: PACKAGING_ROOT + "/default", out_file:)

      out_file
    end

    # TODO: index for prebuilt single-file Shoes app w/ no Gemfile
    def build_html_index(wasm_url: "./packed_ruby.wasm")
      rbwasm_version = RubyWasm::VERSION
      <<~INDEX
        <!DOCTYPE html>
        <html lang="en">
          <head>

          <script type="module">
            import { DefaultRubyVM } from "https://cdn.jsdelivr.net/npm/@ruby/wasm-wasi@#{rbwasm_version}/dist/browser/+esm";

            // For Locally-compiled Ruby.wasm VM:
            const response = await fetch("#{wasm_url}");
            const module = await WebAssembly.compileStreaming(response);

            const { vm } = await DefaultRubyVM(module);

            window.rubyVM = vm;

            vm.eval(`
              require "/bundle/setup"
              require "js" # Needed even with /bundle/setup
              $LOAD_PATH.unshift "/spaceshoes_lib"
              require "space_shoes/core"
              require "scarpe/space_shoes" # Scarpe display service
            `);

          </script>

          </head>
          <body>
          </body>
        </html>
      INDEX
    end
  end
end

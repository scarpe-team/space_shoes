# frozen_string_literal: true

require "space_shoes/core"

require "scarpe/components/file_helpers"
require "scarpe/components/process_helpers"

module SpaceShoes
  module Packaging
    include Scarpe::Components::ProcessHelpers

    SOURCE_ROOT = File.expand_path(File.join(__dir__, "../.."))
    PACKAGING_ROOT = File.expand_path(File.join(SOURCE_ROOT, "packaging"))
    if ENV["HOME"] && File.exist?(ENV["HOME"])
      BUILT_RUBY_CACHE_DIR = File.expand_path(File.join(ENV["HOME"], ".space_shoes"))
    else
      BUILT_RUBY_CACHE_DIR = SOURCE_ROOT # This isn't great, but it'll sometimes do
    end
    BUILT_RUBY_WASM = File.join(BUILT_RUBY_CACHE_DIR, "ruby.wasm")

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
        # Use the packaging dir's Bundler setup, not what the outer program was run with
        Bundler.with_unbundled_env do
          run_or_raise("bundle exec rbwasm build -o #{BUILT_RUBY_WASM}")
        end
      end
    end

    def build_packed_wasm_file(pack_root: ".", built_ruby: BUILT_RUBY_WASM, out_file:, map_dirs: { "/src" => "." })
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
      build_packed_wasm_file pack_root: PACKAGING_ROOT + "/default", out_file:
      out_file
    end
  end
end

# frozen_string_literal: true

require "space_shoes/core"

require "scarpe/components/file_helpers"
#require "scarpe/components/process_helpers"

# THIS WILL BE PART OF LACCI - REMOVE AFTER UPGRADING SUFFICIENTLY
#
module Scarpe::Components
  module ProcessHelpers
    include FileHelpers

    # Run the command and capture its stdout and stderr output, and whether
    # it succeeded or failed. Return after the command has completed.
    # The awkward name is because this is normally a component of another
    # library. Ordinarily you'd want to raise a library-specific exception
    # on failure, print a library-specific message or delimiter, or otherwise
    # handle success and failure. This is too general as-is.
    #
    # @param cmd [String,Array<String>] the command to run in Kernel#spawn format
    # @return [Array(String,String,bool)] the stdout output, stderr output and success/failure of the command in a 3-element Array
    def run_out_err_result(cmd)
      out_str = ""
      err_str = ""
      success = nil

      with_tempfiles([
        ["scarpe_cmd_stdout", ""],
        ["scarpe_cmd_stderr", ""],
      ]) do |stdout_file, stderr_file|
        pid = Kernel.spawn(cmd, out: stdout_file, err: stderr_file)
        Process.wait(pid)
        success = $?.success?
        out_str = File.read stdout_file
        err_str = File.read stderr_file
      end

      [out_str, err_str, success]
    end
  end
end

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
    def build_ruby_wasm_binary(out_file: "ruby_wasm")
      Dir.chdir(PACKAGING_ROOT) do
        # Use the packaging dir's Bundler setup, not what the outer program was run with
        Bundler.with_unbundled_env do
          run_or_raise("bundle exec rbwasm build -o #{out_file}")
        end
      end
    end

    def build_ruby_wasm_binary_if_stale
      Dir.chdir(PACKAGING_ROOT) do
      end
    end

    Packaging.extend PackagingCommands
  end
end

# frozen_string_literal: true

ENV['SCARPE_DISPLAY_SERVICE'] = "space_shoes"

require "shoes"
require "lacci/scarpe_core"
require "space_shoes/core"

require "scarpe/components/string_helpers"

# For Wasm, use simple no-dependency printing logger
require "scarpe/components/print_logger"
Shoes::Log.instance = Scarpe::Components::PrintLogImpl.new
Shoes::Log.configure_logger(Shoes::Log::DEFAULT_LOG_CONFIG)

Shoes::FONTS.push(
  "Helvetica",
  "Arial",
  "Arial Black",
  "Verdana",
  "Tahoma",
  "Trebuchet MS",
  "Impact",
  "Gill Sans",
  "Times New Roman",
  "Georgia",
  "Palatino",
  "Baskerville",
  "Courier",
  "Lucida",
  "Monaco",
)

# When we require SpaceShoes' shoes-spec it will fill this in on the host side
module Scarpe; module Test; end; end
require "shoes-spec"
Shoes::Spec.instance = Scarpe::Test

require "scarpe/components/html"
module SpaceShoes
  HTML = Scarpe::Components::HTML

  require "scarpe/components/segmented_file_loader"
  loader = Scarpe::Components::SegmentedFileLoader.new
  Shoes.add_file_loader loader

  DEFAULT_FILE_LOADER = loader

  class Drawable < Shoes::Linkable
    require "scarpe/components/calzini"
    # This is where we would make the HTML renderer modular by choosing another
    include Scarpe::Components::Calzini
  end
end

# Scarpe Wasm Display Service

# This file should be required on the Wasm side, not the Ruby side.
# So it's used to link to JS, and to instantiate drawables, but not
# for e.g. packaging.

require "space_shoes/version"
require "space_shoes/guest/display_service"
require "space_shoes/guest/drawable"

#require "space_shoes/wasm_calls"
#require "space_shoes/web_wrangler"
#require "space_shoes/control_interface"
#
#require "space_shoes/radio"
#
#require "space_shoes/art_drawables"
#
#require "space_shoes/app"
#require "space_shoes/para"
#require "space_shoes/slot"
#require "space_shoes/stack"
#require "space_shoes/flow"
#require "space_shoes/document_root"
#require "space_shoes/subscription_item"
#require "space_shoes/button"
#require "space_shoes/progress"
#require "space_shoes/image"
#require "space_shoes/edit_box"
#require "space_shoes/edit_line"
#require "space_shoes/list_box"
#require "space_shoes/shape"
#
#require "space_shoes/text_drawable"
#require "space_shoes/link"
#require "space_shoes/video"
#require "space_shoes/check"

Shoes::DisplayService.set_display_service_class(SpaceShoes::DisplayService)

# Called when loading a Shoes app into the browser.
def browser_shoes_code(url, code)
  if url.end_with?(".sspec") || url.end_with?(".scas")
    # Segmented app - host will run the test code, we'll run the app
    _fm, segmap = Scarpe::Components::SegmentedFileLoader.front_matter_and_segments_from_file(code)
    app_code = segmap.values.first
    eval app_code
  elsif url.end_with?(".rb")
    # Standard Ruby Shoes app, just load it
    eval code
  else
    raise "ERROR! Unknown file extension for browser URL #{url.inspect}! Should end in .rb or .sspec!"
  end
end

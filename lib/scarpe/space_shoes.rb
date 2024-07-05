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

require "space_shoes/guest/shoes-spec"
Shoes::Spec.instance = SpaceShoes::ShoesSpec

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

require "space_shoes/guest/web_wrangler"
require "space_shoes/guest/control_interface"
require "space_shoes/guest/app"

require "space_shoes/guest/slot"
require "space_shoes/guest/document_root"

require "space_shoes/guest/art_drawables"
require "space_shoes/guest/radio"
require "space_shoes/guest/para"
require "space_shoes/guest/subscription_item"
require "space_shoes/guest/button"
require "space_shoes/guest/progress"
require "space_shoes/guest/image"
require "space_shoes/guest/edit_box"
require "space_shoes/guest/edit_line"
require "space_shoes/guest/list_box"
require "space_shoes/guest/shape"
require "space_shoes/guest/text_drawable"
require "space_shoes/guest/link"
require "space_shoes/guest/video"
require "space_shoes/guest/check"

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

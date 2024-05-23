# frozen_string_literal: true

module SpaceShoes
  class Video < Drawable
    SUPPORTED_FORMATS = {
      "video/mp4" => [".mp4"],
      "video/webp" => [".webp"],
      "video/quicktime" => [".mov"],
      "video/x-matroska" => [".mkv"],
      # Add more formats and their associated file extensions if needed
    }.freeze
    FORMAT_FOR_EXT = {}
    SUPPORTED_FORMATS.each do |format, extensions|
      extensions.each do |ext|
        if FORMAT_FOR_EXT.key?(ext)
          raise "Internal error! Must have a specific format for each extension!"
        end
        FORMAT_FOR_EXT[ext] = format
      end
    end
    FORMAT_FOR_EXT.freeze

    def initialize(properties)
      @url = properties[:url]
      super
      @format = FORMAT_FOR_EXT[File.extname(@url)]
    end

    def element
      render "video", shoes_styles.merge("format" => @format)
    end
  end
end

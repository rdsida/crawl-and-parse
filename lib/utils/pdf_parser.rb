# frozen_string_literal: true

require 'open-uri'
require 'pdf-reader'

module Utils
  # General PDF handler, pass it the url to whatever file you're interested in,
  # as a string. Doesn't currently save it anywhere.
  class PdfParser
    def initialize(uri)
      @uri = URI.parse(uri)
    end

    # Pass a regex with a single capture group which is the number you want.
    def get_int(regex)
      StringConverter
        .new(to_s.match(regex)[1])
        .to_i
    end

    def to_s
      @to_s ||= reader.pages
                      .map(&:text)
                      .join("\n")
    end

    def reader
      @reader ||= PDF::Reader.new(@uri.open)
    end
  end
end

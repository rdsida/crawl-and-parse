# frozen_string_literal: true

require 'open-uri'
require 'pdf-reader'

module Utils
  # General PDF handler, pass it the url to whatever file you're interested in,
  # as a string. Saves file to download dir
  class PdfParser
    attr_reader :uri
    # State code is required to know where to save the file.
    def initialize(uri, state_code)
      @uri = uri
      @state_code = state_code

      save_file
    end

    # Pass a regex with a single capture group which is the number you want.
    def get_int(regex)
      StringConverter
        .new(to_s.match(regex)[1])
        .to_i
    end

    def filetime
      Time.now.strftime('%Y-%m-%e.%H.%M.%S')
    end

    # BASEDIR/data/xx/2020-05-12-17.34.41.pdf
    def filename
      File.join BASEDIR, 'data', @state_code, filetime + '.pdf'
    end

    def save_file
      IO.copy_stream(file_stream, filename)
    end

    def file_stream
      @file_stream ||= URI.parse(@uri).open
    end

    def to_s
      @to_s ||= reader.pages
                      .map(&:text)
                      .join("\n")
    end

    def reader
      @reader ||= PDF::Reader.new(file_stream)
    end
  end
end

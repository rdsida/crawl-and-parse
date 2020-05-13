require 'optparse'

# Eventually this will be the top level namespace.
module CrawlAndParse
  Options = Struct.new(:auto, :nofail, :debug, keyword_init: true)

  # This allows us to call CrawlAndParse.(property), saving us from
  # having to pass a bunch of arguments to all the different constructors
  class << self
    attr_accessor :options

    # Delegate missing methods to the options hash. Allows us to call things
    # like CrawlAndParse.nofail instead of CrawlAndParse.options.nofail
    def method_missing(method, *args)
      super unless options.respond_to? method

      options.send(method, *args)
    end

    def respond_to_missing?(method)
      super || options.respond_to?(method)
    end
  end

  # Parses Command line args, passes them to the main crawler
  class CLI
    def initialize(argv)
      @argv = argv
      @options = defaults

      # Handles flagged arguments
      parser.parse!(@argv, into: @options)
    end

    def call
      CrawlAndParse.options = options
      Crawler.new(crawl_list).run
    end

    private

    # Parses remaining (unflagged) arguments
    def crawl_list
      help unless @argv.any? || @options[:auto]

      # TODO: Verify that state arguments make sense.
      @crawl_list = @argv.map(&:downcase)
    end

    def options
      Options.new(@options)
    end

    def defaults
      { auto: false, nofail: false, debug: false }
    end

    def parser
      OptionParser.new do |opts|
        opts.banner = banner

        opts.on('-a', '--auto', 'Automatically crawl all states')
        opts.on('-h', '--help', 'Print Help') { help }
        opts.on('-n', '--nofail', 'Catch all exceptions')
        opts.on('-d', '--debug',
                "I'm not actually sure. I think it starts a debugger on errors")
      end
    end

    def banner
      <<~BANNER

        Usage: crawl [options] [states]
        
        You must either give some states or pass the auto flag.

      BANNER
    end

    def help
      puts parser
      exit
    end
  end
end

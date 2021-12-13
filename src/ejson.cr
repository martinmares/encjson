require "monocypher"
require "option_parser"
require "colorize"

require "../src/secure_string"
require "../src/string_utils"

module Ejson

  VERSION = "1.0.0"
  NAME = "ejson"

  COMMAND_INIT = :init
  COMMAND_ENCRYPT = :encrypt
  COMMAND_DECRYPT = :decrypt

  DEFAULT_KEY_SIZE = 32

  COMMANDS = [COMMAND_INIT, COMMAND_ENCRYPT, COMMAND_DECRYPT]

  class App

    @key_dir : String | Nil
    @key_size : Int32

    def initialize
      @command = :help
      @file_name = ""
      @file_name_out = ""
      @key_size = DEFAULT_KEY_SIZE
      @debug = false
      ENV["EJSON_KEYDIR"] ||= Path["~/.ejson"].expand(home: true).to_s
      @key_dir ||= ENV["EJSON_KEYDIR"]
      parse_opts()
      puts "Run command #{@command.colorize(:cyan)} ..." if @debug
    end

    def run
      case @command
      when COMMAND_INIT
        command_init()        
      else
        "Nothing to do ..."
      end
    end

    private def command_init
      secure = SecureString.new()
      str = secure.random_str(@key_size)

      h = StringUtils.str_to_hex(str)
      s = StringUtils.hex_to_str(h)

      p "str => #{str}"
      p "h => #{h}"
      p "s => #{s}"
    end

    private def parse_opts
      parser = OptionParser.new do |parser|
        parser.banner = "Usage: ejson [subcommand] [arguments]"

        parser.on("init", "Init private and public key") do
          @command = COMMAND_INIT
          parser.banner = "Usage: #{NAME} #{COMMAND_INIT} [arguments]"
          parser.on("-o DIR", "--out=DIR", "Specify the directory name where the private and public keys are to be stored") { |_name| @file_name_out = _name }
          parser.on("-s SIZE", "--out=SIZE", "Key length") { |_name| @key_size = _name.to_i }
        end

        parser.on("encode", "Encode JSON") do
          @command = COMMAND_ENCRYPT
          parser.banner = "Usage: #{NAME} #{COMMAND_ENCRYPT} [arguments]"
          parser.on("-f NAME", "--file=NAME", "Specify JSON input file name") { |_name| @file_name = _name }
          parser.on("-o NAME", "--output=NAME", "Specify JSON output file name") { |_name| @file_name_out = _name }
        end

        parser.on("decode", "Decode JSON") do
          @command = COMMAND_DECRYPT
          parser.banner = "Usage: #{NAME} #{COMMAND_DECRYPT} [arguments]"
          parser.on("-f NAME", "--file=NAME", "Specify JSON input file name") { |_name| @file_name = _name }
          parser.on("-o NAME", "--output=NAME", "Specify JSON output file name") { |_name| @file_name_out = _name }
        end

        parser.on("-d", "--debug", "Enabled debug output") { @debug = true }
        parser.on("-h", "--help", "Show this help") do
          puts parser
          exit
        end
      end

      parser.parse

      unless COMMANDS.includes? @command
        puts parser
        exit(1)
      end
    end

  end

  app = App.new
  app.run()

end

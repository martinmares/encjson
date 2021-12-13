require "monocypher"
require "option_parser"
require "colorize"

require "../src/secure_string"
require "../src/string_utils"
require "../src/utils"
require "../src/json_utils"

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
      puts "Key dir #{@key_dir.colorize(:cyan)}"
    end

    def run
      case @command
      when COMMAND_INIT
        command_init()
      when COMMAND_ENCRYPT
        command_encrypt()
      else
        puts "Not implemented yet!"
      end
    end

    private def command_init
      secure = SecureString.new()

      priv_str = secure.random_str(@key_size)
      priv_hex = StringUtils.str_to_hex(priv_str)
      pub_str = secure.random_str(@key_size)
      pub_hex = StringUtils.str_to_hex(pub_str)

      puts "Generated key pair (hex digit):"
      puts " => 🔑 private: #{priv_hex}"
      puts " => 🍺 public: #{pub_hex}"

      Utils.with_dir(@key_dir) do |dir|
        save_to = Path[dir] / pub_hex
        Utils.with_file(save_to, "w") do |f|
          f.puts priv_hex
        end
        puts " => 💾 saved to: #{save_to.to_s.colorize(:green)}"
      end
    end

    private def command_encrypt
      puts "@file_name: #{@file_name}"
      puts "@file_name_out: #{@file_name_out}"

      JsonUtils.with_file(@file_name) do |content|
        JsonUtils.with_content(content) do |json|
          if JsonUtils.has_priv_key? json
            JsonUtils.encrypt(json)
            # encrypted = JsonUtils.encrypt(json)
            # puts encrypted.to_pretty_json
            # puts encrypted.dig("alias").as_h
            # puts encrypted.dig("alias").dig("bar").as_s?
          end
        end
      end
    end

    private def parse_opts
      parser = OptionParser.new do |parser|
        parser.banner = "Usage: ejson [subcommand] [arguments]"

        parser.on(COMMAND_INIT.to_s, "#{COMMAND_INIT.to_s.capitalize} private and public key") do
          @command = COMMAND_INIT
          parser.banner = "Usage: #{NAME} #{COMMAND_INIT} [arguments]"
          parser.on("-k DIR", "--keydir=DIR", "Specify the directory name where the private and public keys are to be stored") { |_name| @key_dir = _name }
          parser.on("-s SIZE", "--out=SIZE", "Key length") { |_name| @key_size = _name.to_i }
        end

        parser.on(COMMAND_ENCRYPT.to_s, "#{COMMAND_ENCRYPT.to_s.capitalize} JSON") do
          @command = COMMAND_ENCRYPT
          parser.banner = "Usage: #{NAME} #{COMMAND_ENCRYPT} [arguments]"
          parser.on("-k DIR", "--keydir=DIR", "Specify the directory name where the private and public keys are stored") { |_name| @key_dir = _name }
          parser.on("-f NAME", "--file=NAME", "Specify JSON input file name") { |_name| @file_name = _name }
          parser.on("-o NAME", "--output=NAME", "Specify JSON output file name") { |_name| @file_name_out = _name }
        end

        parser.on(COMMAND_DECRYPT.to_s, "#{COMMAND_DECRYPT.to_s.capitalize} JSON") do
          @command = COMMAND_DECRYPT
          parser.banner = "Usage: #{NAME} #{COMMAND_DECRYPT} [arguments]"
          parser.on("-k DIR", "--keydir=DIR", "Specify the directory name where the private and public keys are stored") { |_name| @key_dir = _name }
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

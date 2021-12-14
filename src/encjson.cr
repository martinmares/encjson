require "monocypher"
require "option_parser"
require "colorize"

require "../src/secure_string"
require "../src/string_utils"
require "../src/utils"
require "../src/json_utils"
require "../src/crypto_utils"

module EncJson

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
      @stdin = true
      @rewrite = false
      ENV["EJSON_KEYDIR"] ||= Path["~/.ejson"].expand(home: true).to_s
      @key_dir ||= ENV["EJSON_KEYDIR"]
      parse_opts()
      @stdin = false if @command == COMMAND_INIT
      puts "Run command #{@command.colorize(:cyan)} ..." if @debug
      puts "Key dir #{@key_dir.colorize(:cyan)}" if @debug
      puts "STDIN enabled: #{@stdin.to_s.colorize(:cyan)}" if @debug
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

      priv_str = secure.random_str(@key_size, set: :extended)
      priv_hex = StringUtils.str_to_hex(priv_str)
      pub_str = secure.random_str(@key_size, set: :extended)
      pub_hex = StringUtils.str_to_hex(pub_str)

      puts "Generated key pair (hex):"
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
      puts " => 💾 file_name: #{@file_name}" if @debug
      puts " => 💾 file_name_out: #{@file_name_out}" if @debug

      JsonUtils.with_file(@file_name, @stdin) do |content|
        JsonUtils.with_content(content) do |json|
          if JsonUtils.has_public_key?(json)
            utils = JsonUtils.new(json, @key_dir, @debug)
            encrypted = utils.encrypt()
            if @rewrite
              rewrite_file = @file_name
              puts "Try rewrite content:"
              Utils.with_file(rewrite_file, "w") do |f|
                f.puts encrypted
              end
              puts " => 💾 rewrited: #{rewrite_file.to_s.colorize(:green)}"
            else
              puts encrypted
            end
          else
            puts content
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
          parser.on("-f NAME", "--file=NAME", "Specify JSON input file name") do |_name|
            @file_name = _name
            @stdin = false
          end
          parser.on("-o NAME", "--output=NAME", "Specify JSON output file name") { |_name| @file_name_out = _name }
          parser.on("-w", "--rewrite", "Rewrite input file!") { @rewrite = true }
        end

        parser.on(COMMAND_DECRYPT.to_s, "#{COMMAND_DECRYPT.to_s.capitalize} JSON") do
          @command = COMMAND_DECRYPT
          parser.banner = "Usage: #{NAME} #{COMMAND_DECRYPT} [arguments]"
          parser.on("-k DIR", "--keydir=DIR", "Specify the directory name where the private and public keys are stored") { |_name| @key_dir = _name }
          parser.on("-f NAME", "--file=NAME", "Specify JSON input file name") do |_name|
            @file_name = _name
            @stdin = false
          end
          parser.on("-o NAME", "--output=NAME", "Specify JSON output file name") { |_name| @file_name_out = _name }
        end

        parser.on("-v", "--verbose", "Enabled verbose output") { @debug = true }
        parser.on("-h", "--help", "Show this help") do
          puts parser
          exit
        end

        parser.invalid_option do |flag|
          STDERR.puts "ERROR: #{flag} is not a valid option."
          STDERR.puts parser
          exit(1)
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

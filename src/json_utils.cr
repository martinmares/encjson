require "json"
require "colorize"

require "../src/utils"
require "../src/string_utils"
require "../src/secure_box"
require "../src/encjson"

module EncJson

  class JsonUtils

    JSON_PUBLIC_KEY_NAME = "_public_key"

    @pub_key : String | Nil

    def initialize(@json : JSON::Any, @key_dir : String | Nil, @command : Symbol, @debug : Bool = false)
      @pub_key = @json[JSON_PUBLIC_KEY_NAME].as_s if @json[JSON_PUBLIC_KEY_NAME]?
      @pub_key ||= nil
      @secure_box = SecureBox.new(pub_key: @pub_key, key_dir: @key_dir, debug: @debug)
    end

    def self.with_file(file_name, from_stdin : Bool = false)
      if from_stdin
        content = read_from_stdin
      else
        content = Utils.read_file(file_name)
      end
      yield(content)
    end

    def self.with_content(content)
      if StringUtils.has_content?(content)
        json = JSON.parse(content)
        yield(json)
      end
    end

    def self.has_public_key?(json : JSON::Any)
      ! json[JSON_PUBLIC_KEY_NAME]?.nil?
    end

    def priv_key_not_found?
      @secure_box.priv_key_not_found?
    end

    private def self.read_from_stdin : String
      STDIN.gets_to_end
    end

    # https://crystal-lang.org/reference/1.2/syntax_and_semantics/alias.html
    alias JsonType = Nil | Bool | Int32 | Float64 | String | Array(JsonType) | Hash(String, JsonType)

    def enc_dec
      if @json.as_h?
        result = parse_hash(@json)
      elsif @json.as_a?
        result = parse_array(@json)
      end

      if @command == App::COMMAND_ENV && result.is_a?(Hash(String, EncJson::JsonUtils::JsonType))
        env_vars = Hash(String, EncJson::JsonUtils::JsonType).new
        env_vars = result["env"].as?(Hash(String, EncJson::JsonUtils::JsonType)) if result.has_key? "env"
        env_vars = result["environment"].as?(Hash(String, EncJson::JsonUtils::JsonType)) if result.has_key? "environment"
        if env_vars
          str = String.build do |sb|
            env_vars.each do |k, v|
              sb << "export #{k}=\"#{v}\"\n"
            end
          end
          result = str
        end
        result
      else
        result.to_pretty_json
      end
    end

    def parse_hash(any : JSON::Any, level : Int32 = 0) : JsonType
      result : JsonType = Hash(String, JsonType).new
      any.as_h.each do |key, val|
        # puts "[#{level}] key: #{key.colorize(:blue)}, val: #{val}"
        if val.as_h?
          result[key] = parse_hash(val, level + 1)
        elsif val.as_a?
          result[key] = parse_array(val, level + 1)
        elsif val.as_i?
          result[key] = val.as_i
        elsif val.as_f?
          result[key] = val.as_f
        elsif val.as_bool?
          result[key] = val.as_bool
        elsif val.as_s?
          if @command == App::COMMAND_ENCRYPT
            result[key] = @secure_box.encrypt(key: key, val: val.as_s)
          elsif @command == App::COMMAND_DECRYPT || @command == App::COMMAND_ENV
            decrypted_val = @secure_box.decrypt(key: key, val: val.as_s)
            decrypted_val = escape_special_chars(decrypted_val) if @command == App::COMMAND_ENV
            result[key] = decrypted_val
          else
            result[key] = val.as_s # if you don't know, don't touch it!
          end
        else
          result[key] = nil
        end
      end
      result
    end

    def parse_array(any : JSON::Any, level : Int32 = 0) : JsonType
      result : JsonType = Array(JsonType).new
      any.as_a.each do |val|
        if val.as_h?
          result << parse_hash(val, level + 1)
        elsif val.as_a?
          result << parse_array(val, level + 1)
        elsif val.as_i?
          result << val.as_i
        elsif val.as_f?
          result << val.as_f
        elsif val.as_bool?
          result << val.as_bool
        elsif val.as_s?
          if @command == App::COMMAND_ENCRYPT
            result << @secure_box.encrypt(key: nil, val: val.as_s)
          elsif @command == App::COMMAND_DECRYPT || @command == App::COMMAND_ENV
            decrypted_val = @secure_box.decrypt(key: nil, val: val.as_s)
            decrypted_val = escape_special_chars(decrypted_val) if @command == App::COMMAND_ENV
            result << decrypted_val
          else
            result << val.as_s # if you don't know, don't touch it!
          end
        else
          result << nil
        end
      end
      result
    end

    def escape_special_chars(value)
      if value
        value.gsub("$", "\\$").gsub("\"", "\\\"").gsub("`", "\\`")
      else
        value
      end
    end

  end

end

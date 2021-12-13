require "json"
require "colorize"
require "../src/utils"
require "../src/string_utils"

module Ejson


  JSON_PUBLIC_KEY_NAME = "_public_key"

  class JsonUtils

    def self.with_file(file_name)
      content = Utils.read_file(file_name)
      yield(content)
    end

    def self.with_content(content)
      if StringUtils.has_content?(content)
        json = JSON.parse(content)
        yield(json)
      end
    end

    def self.has_priv_key?(json : JSON::Any)
      ! json[JSON_PUBLIC_KEY_NAME]?.nil?
    end

    # https://crystal-lang.org/reference/1.2/syntax_and_semantics/alias.html
    alias JsonType = Nil | Bool | Int32 | Float64 | String | Array(JsonType) | Hash(String, JsonType)

    def self.encrypt(any : JSON::Any)
      if any.as_h?
        result = self.encrypt_hash(any)
      elsif (array = any.as_a?)
        result = self.encrypt_array(any)
      end
      puts "class: #{result.class}"
      puts "result: #{result}"
      puts result.to_pretty_json
    end

    def self.encrypt_hash(any : JSON::Any, level : Int32 = 0) : JsonType
      result : JsonType = Hash(String, JsonType).new
      any.as_h.each do |key, val|
        puts "[#{level}] key: #{key.colorize(:blue)}, val: #{val}"
        if val.as_h?
          result[key] = self.encrypt_hash(val, level + 1)
        elsif val.as_a?
          result[key] = self.encrypt_array(val, level + 1)
        elsif val.as_i?
          result[key] = val.as_i
        elsif val.as_f?
          result[key] = val.as_f
        elsif val.as_bool?
          result[key] = val.as_bool
        elsif val.as_s?
          result[key] = val.as_s
        else
          result[key] = nil
        end
      end
      result
    end

    def self.encrypt_array(any : JSON::Any, level : Int32 = 0) : JsonType
      result : JsonType = Array(JsonType).new
      any.as_a.each do |val|
        if val.as_h?
          result << self.encrypt_hash(val, level + 1)
        elsif val.as_a?
          result << self.encrypt_array(val, level + 1)
        elsif val.as_i?
          result << val.as_i
        elsif val.as_f?
          result << val.as_f
        elsif val.as_bool?
          result << val.as_bool
        elsif val.as_s?
          result << val.as_s
        else
          result << nil
        end
      end
      result
    end

  end

end

require "base64"

require "../src/json_utils"
require "../src/crypto_utils"

module EncJson

  class SecureBox

    TYPE = "EncJson"
    API = "1.0"
    BEGIN = "["
    END = "]"

    @crypto_shared : Crypto::SymmetricKey

    def initialize(@pub_key : String | Nil, @key_dir : String | Nil, @debug : Bool = false)
      @priv_key = ""
      @priv_key_not_found = true

      # Temporary only!
      @crypto_private = Crypto::SecretKey.new
      @crypto_public = Crypto::PublicKey.new(secret: @crypto_private)
      @crypto_shared = CryptoUtils.shared_key(private_key: @crypto_private, public_key: @crypto_public)

      if @pub_key
        puts "Creating SecureBox:" if @debug
        if ENV["ENCJSON_PRIVATE_KEY"]?
          puts " => 💾 read private key from env var ENCJSON_PRIVATE_KEY" if @debug
          puts " => 👷 prepare encryption key pair ..." if @debug
          @crypto_private = CryptoUtils.private_key(ENV["ENCJSON_PRIVATE_KEY"].chomp)
          @crypto_public = CryptoUtils.public_key(@pub_key.as(String))
          @crypto_shared = CryptoUtils.shared_key(private_key: @crypto_private, public_key: @crypto_public)
          @priv_key_not_found = false
        else
          Utils.with_dir(@key_dir) do |dir|
            read_from = Path[dir] / @pub_key.as(String)
            if File.exists? read_from
              @priv_key = File.read(read_from).chomp
              puts " => 💾 read private key from: #{read_from.to_s.colorize(:green)}" if @debug
              puts " => 👷 prepare encryption key pair ..." if @debug
              @crypto_private = CryptoUtils.private_key(@priv_key)
              @crypto_public = CryptoUtils.public_key(@pub_key.as(String))
              @crypto_shared = CryptoUtils.shared_key(private_key: @crypto_private, public_key: @crypto_public)
              @priv_key_not_found = false
            end
          end
        end
      end
    end

    def priv_key_not_found?
      @priv_key_not_found
    end

    def encrypt(key, val)
      if key == JsonUtils::JSON_PUBLIC_KEY_NAME
        val # no encrypt public key!
      elsif encrypted?(val)
        k = key || "(empty)"
        puts " => 💪 value for key #{k.to_s.colorize(:magenta)} is already encrypted" if @debug
        val # value is already encrypted, don't touch it!
      else
        crypted : Slice(UInt8) = CryptoUtils.encrypt(message: val, shared_key: @crypto_shared) # Bytes = Slice(UInt8)
        crypted_b64 = Base64.strict_encode(crypted)

        "#{TYPE}#{BEGIN}@api=#{API}:@box=#{crypted_b64}#{END}"
      end
    end

    def decrypt(key, val)
      if key == JsonUtils::JSON_PUBLIC_KEY_NAME
        val # no decrypt public key!
      elsif decrypted?(val)
        k = key || "(empty)"
        puts " => 💪 value for key #{k.to_s.colorize(:magenta)} is already decrypted" if @debug
        val # value is already decrypted, don't touch it!
      else
        box_field = get_box_field(val)
        box_b64_decoded : Bytes = Base64.decode(box_field)
        decrypted = CryptoUtils.decrypt(message: box_b64_decoded, shared_key: @crypto_shared)

        decrypted
      end

    end

    def get_box_field(val)
      match = /^EncJson\[\@api\=(.*):\@box\=(.*)\]$/ix.match(val)
      if match
        match[2]
      else
        val
      end
    end

    def encrypted?(val)
      match = /^EncJson\[\@api\=(.*):\@box\=(.*)\]$/ix.match(val)
      if match
        true
      else
        false
      end
    end

    def decrypted?(val)
      ! encrypted?(val)
    end

  end

end

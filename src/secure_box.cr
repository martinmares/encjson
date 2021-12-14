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

    def initialize(@pub_key : String, @key_dir : String | Nil, @debug : Bool = false)
      @priv_key = ""
      @priv_key_not_found = false

      # Temporary only!
      @crypto_private = Crypto::SecretKey.new
      @crypto_public = Crypto::PublicKey.new(secret: @crypto_private)
      @crypto_shared = CryptoUtils.shared_key(private_key: @crypto_private, public_key: @crypto_public)

      puts "Created SecureBox:" if @debug
      Utils.with_dir(@key_dir) do |dir|
        read_from = Path[dir] / @pub_key
        if File.exists? read_from
          @priv_key = File.read(read_from).chomp
          puts " => 💾 read private key from: #{read_from.to_s.colorize(:green)}" if @debug
          puts " => 👷 prepare encryption key pair ..." if @debug
          @crypto_private = CryptoUtils.private_key(@priv_key)
          @crypto_public = CryptoUtils.public_key(@pub_key)
          @crypto_shared = CryptoUtils.shared_key(private_key: @crypto_private, public_key: @crypto_public)
        else
          @priv_key_not_found = true
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
        crypted_base64 = Base64.strict_encode(crypted)

        blake2b : Slice(UInt8) = CryptoUtils.blake2b(message: crypted_base64, key: @priv_key.to_slice)
        blake2b_base64 = Base64.strict_encode(blake2b)

        "#{TYPE}#{BEGIN}@api=#{API}:@data=#{crypted_base64}:@hash=#{blake2b_base64}#{END}"
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
        data_field = get_data_field(val)
        data_base64_decoded : Bytes = Base64.decode(data_field)

        hash_field = get_hash_field(val)
        hash_base64_decoded : Bytes = Base64.decode(hash_field)

        decrypted = CryptoUtils.decrypt(message: data_base64_decoded, shared_key: @crypto_shared)

        # check hash
        blake2b : Slice(UInt8) = CryptoUtils.blake2b(message: data_field, key: @priv_key.to_slice)
        if blake2b == hash_base64_decoded.to_slice
          decrypted
        else
          k = key || "(empty)"
          puts " => ❗ hash doesn't match for key #{k.to_s.colorize(:magenta)} can't decrypt!" if @debug
          val # don't encrypt if hash fail!
        end
      end
    end

    def get_data_field(val)
      match = /^EncJson\[\@api\=(.*):\@data\=(.*):\@hash\=(.*)\]$/ix.match(val)
      if match
        match[2]
      else
        val
      end
    end
    
    def get_hash_field(val)
      match = /^EncJson\[\@api\=(.*):\@data\=(.*):\@hash\=(.*)\]$/ix.match(val)
      if match
        match[3]
      else
        val
      end
    end

    def encrypted?(val)
      match = /^EncJson\[\@api\=(.*):\@data\=(.*):\@hash\=(.*)\]$/ix.match(val)
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

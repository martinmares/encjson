require "base64"

require "../src/json_utils"
require "../src/crypto_utils"

module Ejson

  class SecureBox

    TYPE = "ENCJ"
    API = "1.0"
    BEGIN = "["
    END = "]"

    @crypto_shared : Crypto::SymmetricKey

    def initialize(@pub_key : String, @key_dir : String | Nil)
      @priv_key = ""
      puts "Created SecureBox:"
      Utils.with_dir(@key_dir) do |dir|
        read_from = Path[dir] / @pub_key
        @priv_key = File.read(read_from).chomp
        puts " => 💾 read private key from: #{read_from.to_s.colorize(:green)}"
      end
      @crypto_private = CryptoUtils.private_key(@priv_key)
      @crypto_public = CryptoUtils.public_key(@pub_key)
      @crypto_shared = CryptoUtils.shared_key(private_key: @crypto_private, public_key: @crypto_public)
    end

    def encrypt(key, val)
      if key == JsonUtils::JSON_PUBLIC_KEY_NAME
        val # no encrypt public key!
      else
        crypted = CryptoUtils.encrypt(message: val, shared_key: @crypto_shared)
        base64 = Base64.strict_encode(crypted)
        "#{TYPE}#{BEGIN}@api=#{API}:@data=#{base64}#{END}"
      end
    end

  end

end

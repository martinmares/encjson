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
      else
        crypted = CryptoUtils.encrypt(message: val, shared_key: @crypto_shared)
        base64 = Base64.strict_encode(crypted)
        "#{TYPE}#{BEGIN}@api=#{API}:@data=#{base64}#{END}"
      end
    end

  end

end

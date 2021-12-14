require "monocypher"

module EncJson

  class CryptoUtils

    def self.blake2b(str)
      Crypto.blake2b(str.to_slice).hexstring
    end

    def self.private_key(str)
      Crypto::SecretKey.new(str)
    end

    def self.public_key(str)
      Crypto::PublicKey.new(str)
    end

    def self.shared_key(private_key, public_key)
      Crypto::SymmetricKey.new(our_secret: private_key, their_public: public_key)
    end

    def self.encrypt(message, shared_key)
      message_bytes = message.to_slice
      ciphertext = Bytes.new(message_bytes.size + Crypto::OVERHEAD_SYMMETRIC)
      Crypto.encrypt(key: shared_key, input: message_bytes, output: ciphertext)
      ciphertext
    end

    def self.decrypt(message, shared_key)
      message_bytes = message.to_slice
      ciphertext = Bytes.new(message_bytes.size - Crypto::OVERHEAD_SYMMETRIC)
      Crypto.decrypt(key: shared_key, input: message_bytes, output: ciphertext)
      String.new(ciphertext)
    end
  
  end

end

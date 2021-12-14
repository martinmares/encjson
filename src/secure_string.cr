module EncJson

  class SecureString

    SIMPLE_CHARS = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".chars
    EXTENDED_CHARS = "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~".chars

    getter :simple_chars

    def initialize
    end

    def random_str(how_long, set : Symbol = :simple) : String
      io = IO::Memory.new
      case set
      when :extended
        len = EXTENDED_CHARS.size
        from_chars = EXTENDED_CHARS
      else
        len = SIMPLE_CHARS.size        
        from_chars = SIMPLE_CHARS
      end

      (0..how_long-1).each do |i|
        rnd = Random::Secure.rand(len)
        from_chars[rnd].to_s(io)
      end
      io.to_s
    end

  end

end

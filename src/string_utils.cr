module EncJson

  class StringUtils

    MAPPING = "0123456789abcdef".chars

    def self.hex_to_str(hex) : String
      result = Array(UInt8).new
      hex.chars.each_slice(2) do |pair|
        result << (MAPPING.index(pair.first).to_s.to_u8 << 4)
        result[result.size - 1] |= MAPPING.index(pair.last).to_s.to_u8
      end

      d = result.to_unsafe.to_slice(result.size)
      String.new(d)
    end

    def self.str_to_hex(str) : String
      str.to_slice.hexstring
    end

    def self.has_content?(str)
      ! str.empty?
    end

  end

end

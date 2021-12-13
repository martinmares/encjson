module Ejson

  class SecureBox

    TYPE = "ENCJ"
    BEGIN = "["
    END = "]"

    def initialize(@type : String, @version : String, @content : String)
    end

  end

end

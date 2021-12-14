module EncJson


  class Utils

    def self.with_dir(dir_name)
      unless dir_name.nil?
        unless dir_name.empty?
          unless File.directory? dir_name
            Dir.mkdir_p(dir_name)
          end
          yield(dir_name)
        end
      end
    end

    def self.with_file(file_name, mode)
      File.open(Path[file_name], mode) do |f|
        yield(f)
      end
    end

    def self.read_file(file_name) : String
      result = ""
      path = Path[file_name]
      if File.exists? path
        result = File.read(path)
      end
      result
    end

    #def self.str_to_json(str)

  end

end

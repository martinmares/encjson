module Ejson


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

  end

end

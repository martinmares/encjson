require "kemal"
require "json"
require "uuid"

module Encjson::Web
  class App
    def run

      get "/" do
        render "src/views/index.ecr", "src/views/layout.ecr"
      end

      get "/encrypt" do
        render "src/views/get/encrypt.ecr", "src/views/layout.ecr"
      end

      get "/decrypt" do
        render "src/views/get/decrypt.ecr", "src/views/layout.ecr"
      end

      post "/encrypt" do |env|
        private_key = env.params.body["private_key"]
        content_decrypted = env.params.body["content"]
        tempfile = App.create_temp with: content_decrypted
        exit_code, cmd_result = App.run cmd: "encjson",
                                        env: {"ENCJSON_PRIVATE_KEY" => "#{private_key}"},
                                        args: ["encrypt", "-f", "#{tempfile.path}"]
        tempfile.delete
        if exit_code == 0
          content = cmd_result
        else
          content = content_decrypted
        end
        render "src/views/post/encrypt.ecr", "src/views/layout.ecr"
      end

      post "/decrypt" do |env|
        private_key = env.params.body["private_key"]
        content_encrypted = env.params.body["content"]
        tempfile = App.create_temp with: content_encrypted
        exit_code, cmd_result = App.run cmd: "encjson",
                                        env: {"ENCJSON_PRIVATE_KEY" => "#{private_key}"},
                                        args: ["decrypt", "-f", "#{tempfile.path}"]
        tempfile.delete
        if exit_code == 0
          content = cmd_result
        else
          content = content_encrypted
        end
        render "src/views/post/decrypt.ecr", "src/views/layout.ecr"
      end

      Kemal.run
    end

    def self.run(*, cmd, env, args)
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      status = Process.run(cmd, args: args, output: stdout, error: stderr)
      if status.success?
        {status.exit_code, stdout.to_s}
      else
        {status.exit_code, stderr.to_s}
      end
    end

    def self.create_temp(with content)
      tempfile = File.tempfile(UUID.random.to_s) do |file|
        file.print(content)
      end
      tempfile
    end
    
  end

  app = App.new
  app.run
end

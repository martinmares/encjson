require "kemal"
require "json"
require "../src/crypto_utils"
require "../src/secure_string"
require "../src/string_utils"

module Encjson::Web

  ENV_ENCJSON_PRIVATE_KEY = "ENCJSON_PRIVATE_KEY"
  class App

    DEFAULT_KEY_SIZE = 32

    def run

      get "/" do
        render "src/views/index.ecr", "src/views/layout.ecr"
      end

      get "/healthz" do |env|
        env.response.content_type = "application/json"
        {"status": "UP"}.to_json
      end

      get "/init" do
        secure = EncJson::SecureString.new()
        priv_str = secure.random_str(DEFAULT_KEY_SIZE, set: :extended)
        private_key = EncJson::StringUtils.str_to_hex(priv_str)
        pub_str = secure.random_str(DEFAULT_KEY_SIZE, set: :extended)
        public_key = EncJson::StringUtils.str_to_hex(pub_str)
        render "src/views/get/init.ecr", "src/views/layout.ecr"
      end

      get "/encrypt" do
        render "src/views/get/encrypt.ecr", "src/views/layout.ecr"
      end

      get "/decrypt" do
        render "src/views/get/decrypt.ecr", "src/views/layout.ecr"
      end

      post "/encrypt" do |env|
        with_temp(env, :encrypt) do |result|
          content = result
          render "src/views/post/encrypt.ecr", "src/views/layout.ecr"
        end
      end

      post "/decrypt" do |env|
        with_temp(env, :decrypt) do |result|
          content = result
          render "src/views/post/decrypt.ecr", "src/views/layout.ecr"
        end
      end

      Kemal.run
    end

    def with_temp(env, cmd)
      private_key = env.params.body["private_key"]
      content = env.params.body["content"]
      tempfile = create_temp with: content
      begin
        exit_code, cmd_result = run cmd: "encjson",
                                        env: {ENV_ENCJSON_PRIVATE_KEY => "#{private_key}"},
                                        args: [cmd.to_s, "-f", "#{tempfile.path}"]
        if exit_code == 0
          content = cmd_result
        end
      ensure
        tempfile.delete if File.exists?(tempfile.path)
      end
      yield(content)
    end

    def run(*, cmd, env, args)
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      status = Process.run(cmd, args: args, env: env, output: stdout, error: stderr)
      if status.success?
        {status.exit_code, stdout.to_s}
      else
        {status.exit_code, stderr.to_s}
      end
    end

    def create_temp(with content)
      tempfile = File.tempfile() do |file|
        file.print(content)
      end
      tempfile
    end
    
  end

  app = App.new
  app.run
end

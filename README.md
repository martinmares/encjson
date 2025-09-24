# encjson

TODO: Write a description here

## Installation

TODO: Write installation instructions here

## Usage

TODO: Write usage instructions here

## Build Linux static bin

  * start container

```bash
$ docker run --rm -it --platform linux/amd64 --entrypoint /bin/bash -v $(pwd):/user/local/src/encjson 84codes/crystal:latest-ubuntu-22.04

$ docker run --rm -it --platform linux/amd64 --entrypoint /bin/sh -v $(pwd):/user/local/src/encjson 84codes/crystal:master-alpine-latest

```
  * inside contaier run

```bash
$ cd /user/local/src
$ git clone https://github.com/martinmares/encjson.git encjson-github
$ cd encjson-github
$ shards update
```

  * output is ...

```
/user/local/src/encjson-github # shards update
Resolving dependencies
Fetching https://github.com/konovod/monocypher.git
Installing monocypher (3.1.2 at 0d24e95)
Postinstall of monocypher: mkdir ./.build; cc ./ext/monocypher.c -c -o ./.build/monocypher.o -O3 -march=native -std=gnu99; cc ./ext/monocypher-ed25519.c -c -o ./.build/monocypher-ed25519.o -O3 -march=native -std=gnu99; ar rcs ./.build/libmonocypher.a ./.build/monocypher.o ./.build/monocypher-ed25519.o
Writing shard.lock
```

  * next steps

```bash
$ shards build --production --static
$ strip bin/encjson
$ strip bin/encjson-web
$ mkdir -p /user/local/src/encjson/bin/alpine-bin/
$ cp bin/encjson /user/local/src/encjson/bin/alpine-bin/encjson-static
$ cp bin/encjson-web /user/local/src/encjson/bin/alpine-bin/encjson-web-static
```
## Development

```bash
$ sentry -b "crystal build ./src/encjson-web.cr -o ./bin/encjson-web" \
         -r "./bin/encjson-web"
```

## Contributing

1. Fork it (<https://github.com/your-github-user/encjson/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Martin Mareš](https://github.com/your-github-user) - creator and maintainer

## Notes

```
Bytes is defined as just alias Bytes = Slice(UInt8).
With this in mind your question could be rephrased to “Can I get a Slice … without creating a new Slice …?” :)
```

# encjson (Crystal, archived)

> **Status:** Archived.  
> This repository contains the original Crystal implementation of `encjson`.  
> New development happens in the Rust rewrite: `encjson-rs`.

`encjson` is a small command‑line helper for storing secrets in JSON files using a simple public/private key scheme built on top of [Monocypher](https://monocypher.org/).

Typical use case: you want to commit configuration files into Git, but keep passwords and API keys encrypted while still being able to decrypt them easily at application startup.

## How it works

A typical `env.secured.json` looks like this:

```json
{
  "_public_key": "4c016009ce7246bebb08ec6856e76839a5c690cf01b30357914020aac9eebc8b",
  "environment": {
    "DB_PASS": "super-secret-password",
    "DB_PORT": 5432,
    "KAFKA_PASS": "another-secret"
  }
}
```

`encjson`:

- generates a random public/private key pair (`encjson init`),
- stores the private key on disk (by default under `~/.encjson/<public_hex>`),
- keeps the public key inside the JSON (`_public_key`),
- encrypts only **string** values,
- leaves `_public_key` and non‑string values (numbers, booleans, null) untouched.

Encrypted strings are wrapped in a marker:

```text
EncJson[@api=1.0:@box=<base64(nonce || ciphertext || mac)>]
```

The shared secret is derived from the public/private key pair using Monocypher, and encryption uses its AEAD construction.

> ⚠️ The exact key derivation and crypto format used here is **not compatible** with the newer Rust implementation (`@api=2.0`).  
> If you plan to keep using this tool, treat it as a frozen implementation.

## Commands

The Crystal CLI supports four main commands:

### `init` – generate keys

```bash
encjson init
```

This prints a randomly generated public/private key pair and stores the private key locally, e.g.:

```text
Generated key pair (hex):
 => 🍺 public:  4c016009ce7246bebb08ec6856e76839a5c690cf01b30357914020aac9eebc8b
 => 🔑 private: 24e55b25c598d4df78387de983b455144e197e3e63239d0c1fc92f862bbd7c0c
 => 💾 saved to: /home/user/.encjson/4c016009ce7246bebb08ec6856e76839a5c690cf01b30357914020aac9eebc8b
```

The key directory can be customised using the `ENCJSON_KEYDIR` environment variable.

### `encrypt` – encrypt JSON file

```bash
encjson encrypt -f env.secured.json -w
```

- Reads `env.secured.json`.
- Uses `_public_key` to look up the matching private key.
- Encrypts all string values (recursively, including inside arrays).
- Writes the result back to the same file (`-w`).

Strings that are already in `EncJson[@api=1.0:@box=…]` format are left unchanged.

### `decrypt` – decrypt JSON file

```bash
encjson decrypt -f env.secured.json -w
```

- Reads `env.secured.json`.
- Decrypts strings in `EncJson[@api=1.0:@box=…]` format.
- Writes the decrypted JSON back to the same file.

Strings that are not in the `EncJson[...]` format are left as‑is.

### `env` – export environment variables

```bash
encjson env -f env.secured.json
```

This command is intended for use in shell startup scripts (Docker entrypoints, Kubernetes init containers, etc.).

It:

- decrypts the JSON in memory,
- looks for an object named `env` or `environment` at the top level,
- prints one `export` line per key:

```bash
export DB_PASS="super-secret-password"
export KAFKA_PASS="another-secret"
```

Special characters (`\`, `"`, `` ` ``, `$`) are escaped so that the output can be safely `eval`‑ed:

```bash
eval "$(encjson env -f env.secured.json)"
```

## Version

The Crystal implementation prints its version using:

```bash
encjson -v
# e.g. 1.7.4
```

## Migration to the Rust implementation

The Rust rewrite (`encjson-rs`) is intended to replace this Crystal project in the long term.

Important points:

- The Crystal implementation uses `@api=1.0`.
- The Rust implementation uses `@api=2.0`.
- The two formats are **not compatible** at the ciphertext level.

Recommended migration:

1. Using the Crystal `encjson`, decrypt your existing `env.secured.json` files:
   ```bash
   encjson decrypt -f env.secured.json -w
   ```
2. Using the Rust `encjson-rs`, re‑encrypt them and commit:
   ```bash
   encjson encrypt -f env.secured.json -w
   ```
3. Update your containers / scripts to use the Rust binary going forward.

You can keep this repository as **archived** for historical reference and reproducibility, while new projects should prefer the Rust implementation.

## License

See the `LICENSE` file in this repository for licensing information.

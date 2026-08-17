# Encrypted automation

This repository holds three encrypted archives and the scripts that run them on a
schedule. Everything inside — the code, its data and its logs — is private work.
The archives are AES-256 ciphertext and the key is not in this repository, so
there is nothing here to read.

The repository is public for one reason only: GitHub Actions minutes are free for
public repositories, and this automation runs on a schedule several times an hour.

* `vault.sh` — encrypt and decrypt the archives with `openssl`.
* `run.sh` — decrypt into a temporary directory, run one script, filter the
  output, encrypt the state back.
* `code.enc`, `state.enc`, `harvest.enc` — the archives.

No issues or pull requests, please. Nothing here is meant to be reused.

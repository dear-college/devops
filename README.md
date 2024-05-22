# Devops

We deploy https://dear.college to AWS using [Colmena](https://github.com/colmena/colmena), a stateless deployment tool for [Nix](https://nixos.org/).

## File Structure

The project should have the following structure:

```
dear.college
├── server ── cloned from https://github.com/dear-college/server
├── client ── cloned from https://github.com/dear-college/client
└── devops ── cloned from https://github.com/dear-college/devops
```

To set up this structure, clone the repositories:
```bash
mkdir dear.college
cd dear.college
git clone https://github.com/dear-college/server.git
git clone https://github.com/dear-college/client.git
git clone https://github.com/dear-college/devops.git
```

Note that the `client` repository is not needed to run the server.

## dotenv

Most of the environment is set up in `hive.nix` but there are two other files required:

- `key.bin` a 256-byte binary file used as a symmetric key for signing JWTs, and
- `google.key` which is the client secret for OAuth.

In this repository, these secrets are protected with [git-crypt](https://github.com/AGWA/git-crypt).

## Deploy using colmena

```bash
nix-shell -p colmena --run "colmena apply"
```

# dotfile

This is my dotfiles.

## Setup

```sh
# see: https://determinate.systems/nix-installer/
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

### setup develop eviroments

```bash
# install package
nix profile install
bash ./scripts/install_neovim.sh

# update package
nix profile upgrade --all
bash ./scripts/install_neovim.sh
```

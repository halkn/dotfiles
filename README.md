# dotfile

This is my dotfiles.

## Setup

```sh
# Link .config
ln -s ~/.dotfiles/.config ~/.config

# See: https://docs.deno.com/runtime/getting_started/installation/
curl -fsSL https://deno.land/install.sh | sh
deno install -g -A --name markdownlint-cli2 npm:markdownlint-cli2
deno install -g -A --name bash-language-server npm:bash-language-server
```

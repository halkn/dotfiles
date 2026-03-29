# dotfile

This is my dotfiles.

## Setup

```sh
# Link .config
ln -s ~/.dotfiles/.config ~/.config

# See: https://github.com/astral-sh/uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install all tools
uv run scripts/tools.py install

# See: https://docs.deno.com/runtime/getting_started/installation/
curl -fsSL https://deno.land/install.sh | sh
deno install -g -A --name markdownlint-cli2 npm:markdownlint-cli2
deno install -g -A --name bash-language-server npm:bash-language-server
```

## Tool Manager

```sh
# List all tools and installed versions
uv run scripts/tools.py list

# Check installed vs latest versions
uv run scripts/tools.py check

# Install a specific tool
uv run scripts/tools.py install <name>

# Update all tools
uv run scripts/tools.py update

# Update a specific tool
uv run scripts/tools.py update <name>
```

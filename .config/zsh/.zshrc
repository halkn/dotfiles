# mkdir for zsh.
mkdir -p "${ZDATADIR}"
mkdir -p "${ZCACHEDIR}"
mkdir -p "${ZPLUGINDIR}"

# load conf.d/*.zsh.
for f in "${ZDOTDIR}/conf.d"/*.zsh; do
  [[ ! -f "${f}.zwc" || "$f" -nt "${f}.zwc" ]] && zcompile "$f"
  source "$f"
done

# compile zshrc.
[[ ! -f "${ZDOTDIR}/.zshrc.zwc" || "${ZDOTDIR}/.zshrc" -nt "${ZDOTDIR}/.zshrc.zwc" ]] \
  && zcompile "${ZDOTDIR}/.zshrc"


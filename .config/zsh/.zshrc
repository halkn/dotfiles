# mkdir for zsh.
mkdir -p "${ZDATADIR}"
mkdir -p "${ZCACHEDIR}"
mkdir -p "${ZSTATEDIR}"
mkdir -p "${ZPLUGINDIR}"
mkdir -p "${ZCACHEDIR}/zwc/conf.d"

# load conf.d/*.zsh.
for f in "${ZDOTDIR}/conf.d"/*.zsh; do
  zwc_file="${ZCACHEDIR}/zwc/conf.d/${f:t}.zwc"
  [[ ! -f "$zwc_file" || "$f" -nt "$zwc_file" ]] && zcompile "$zwc_file" "$f"
  source "$f"
done

# compile zshrc.
[[ ! -f "${ZCACHEDIR}/zwc/.zshrc.zwc" || "${ZDOTDIR}/.zshrc" -nt "${ZCACHEDIR}/zwc/.zshrc.zwc" ]] &&
  zcompile "${ZCACHEDIR}/zwc/.zshrc.zwc" "${ZDOTDIR}/.zshrc"

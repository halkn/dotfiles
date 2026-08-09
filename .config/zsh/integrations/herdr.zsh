# `exec` replaces the shell, so this must stay last in the integrations order.
# HERDR_ENV is set inside herdr-managed shells and stops the recursion.
HERDR_AUTO_START=${HERDR_AUTO_START:-1}

if command -v herdr >/dev/null 2>&1 &&
  [[ -o interactive ]] &&
  [[ -z $HERDR_ENV ]] &&
  [[ -t 0 ]] &&
  [[ -t 1 ]] &&
  [[ $HERDR_AUTO_START == 1 ]]; then
  exec herdr
fi

# Sanitize inherited locales in every Zsh, including noninteractive shells.
# LANG provides the default; valid category overrides remain intact.
zen0x_locale_init() {
  local available locale_var value normalized
  available="$(locale -a 2>/dev/null)"
  available="${available:l}"
  available="${available//-/}"
  for locale_var in LANG LC_ALL LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT LC_IDENTIFICATION; do
    value="${(P)locale_var}"
    [[ -n "$value" ]] || continue
    normalized="${value:l}"
    normalized="${normalized//-/}"
    if ! [[ $'\n'"$available"$'\n' == *$'\n'"$normalized"$'\n'* ]]; then
      unset "$locale_var"
    fi
  done
  export LANG="${LANG:-C.UTF-8}"
}
zen0x_locale_init
unfunction zen0x_locale_init

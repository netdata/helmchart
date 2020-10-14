#!/bin/sh

save_argv() {
  for i; do
    printf %s\\n "$i" | sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/' \\\\/"
  done
  echo " "
}

restore_argv() {
  eval "set -- $*"
}

fnmatch() {
  case "$2" in
    "$1")
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

parse_version() {
  r="${1}"
  s="${2}"
  if echo "${r}" | grep -q '^v.*'; then
    # shellcheck disable=SC2001
    # XXX: Need a regex group subsitutation here.
    r="$(echo "${r}" | sed -e 's/^v\(.*\)/\1/')"
  fi

  old="$(save_argv)"
  eval "set -- $(echo "${r}" | tr '-' ' ')"

  v="$1"
  b="$2"

  if [ -z "$b" ] || fnmatch '*[!0-9]*' "$b"; then
    b=
  fi

  eval "set -- $(echo "${v}" | tr '.' ' ')"
  if [ -n "$b" ]; then
    printf "%03d%s%03d%s%03d%s%03d" "$1" "$s" "$2" "$s" "$3" "$s" "$b"
  else
    printf "%03d%s%03d%s%03d" "$1" "$s" "$2" "$s" "$3"
  fi
  restore_argv "$old"
}

bump_version() {
  v="$1"
  n="$2"

  old="$(save_argv)"
  eval "set -- $(parse_version "$v" " ")"

  major="${1#0*}"
  minor="${2#0*}"
  patch="${3#0*}"
  build="${4#0*}"

  restore_argv "$old"

  case "$n" in
    0)
      major=$((major + 1))
      minor=0
      patch=0
      [ -n "$build" ] && build=0
      ;;
    1)
      minor=$((minor + 1))
      patch=0
      [ -n "$build" ] && build=0
      ;;
    2)
      patch=$((patch + 1))
      [ -n "$build" ] && build=0
      ;;
    3)
      if [ -n "$build" ]; then
        build=$((build + 1))
      fi
      ;;
    *)
      patch=$((patch + 1))
      [ -n "$build" ] && build=0
      ;;
  esac

  if [ -n "$build" ]; then
    printf "%d.%d.%d-%d" "$major" "$minor" "$patch" "$build"
  else
    printf "%d.%d.%d" "$major" "$minor" "$patch"
  fi
}

_main() {
  old_version="$(grep -o -E '^version\:[[:space:]]+([0-9.]+)$' charts/netdata/Chart.yaml | sed -E -e 's/^version\:[[:space:]]+([0-9.]+)$/\1/')"
  old_appVersion="$(grep -o -E '^appVersion\:[[:space:]]+(v[0-9.]+)$' charts/netdata/Chart.yaml | sed -E -e 's/^appVersion\:[[:space:]]+(v[0-9.]+)$/\1/')"
  printf "Old Chart version:    %s\n" "$old_version"
  printf "Old Chart appVersion: %s\n" "$old_appVersion"

  if [ -z "$1" ]; then
    new_appVersion="$(bump_version "$old_appVersion")"
  else
    new_appVersion="$1"
  fi

  new_version="$(bump_version "$old_version")"

  printf "\n"
  printf "New Chart version:    %s\n" "$new_version"
  printf "New Chart appVersion: v%s\n" "$new_appVersion"

  git checkout -b "bump_$new_appVersion"

  sed -i.bak \
    -e "s/$old_version/$new_version/g" \
    -e "s/$old_appVersion/v$new_appVersion/g" \
    README.md charts/netdata/Chart.yaml

  git add -A -p
  git commit -m "Bump Netdata Helm Chart from $old_appVersion => v$new_appVersion"
  git push -u
}

if [ -n "$0" ] && [ x"$0" != x"-bash" ]; then
  _main "$@"
fi

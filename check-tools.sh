#!/usr/bin/env bash

RED=$'\033[31m'
GREEN=$'\033[32m'
RESET=$'\033[0m'

if [ ! -t 1 ]; then RED=""; GREEN=""; RESET=""; fi

echo "System : $(uname -s) $(uname -m) — $(hostname)"
echo "Bash   : $BASH_VERSION"
echo

# Structure: "command_name|version_command"

TOOLS=(
  "git|git --version"
  "curl|curl --version"
  "ssh|ssh -V 2>&1"
  "python3|python3 --version"
  "docker|docker --version"
  "multipass|multipass version"
  "virsh|virsh --version"
  "kubectl|kubectl version --client"
  "helm|helm version --short"
  "terraform|terraform -version"
  "ansible|ansible --version"
  "jq|jq --version"
)

missing=0
for entry in "${TOOLS[@]}"; do
  name="${entry%%|*}"     # | before
  cmd="${entry#*|}"       # | after

  if command -v "$name" >/dev/null 2>&1; then
    version="$(eval "$cmd" 2>/dev/null | head -n 1)"
    printf "%s%-10s%s %s\n" "$GREEN" "$name" "$RESET" "${version:-version could not read}"
  else
    printf "%s%-10s MISSING%s\n" "$RED" "$name" "$RESET"
    missing=$((missing + 1))
  fi
done

echo
echo "Missing tool: $missing"
exit "$missing"
#!/usr/bin/env bash
set -e

echo "Terraform pre-commit hook running"
# Formats any *.tf files according to the hashicorp convention
files=$(git diff --cached --name-only)

for f in $files; do
  if [ -e "$f" ] && [[ "${f##*.}" =~ ^(tf|tfvars)$ ]]; then
    /usr/local/bin/terraform fmt -check=true "$f"
  fi
done

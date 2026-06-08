#!/usr/bin/env bash
set -euo pipefail

# Master bibliography file
MASTER="assets/bib/gatas_cv_bibertool.bib"
OUT_DIR="assets/bib"

# Corresponding lists of output names and keyword tokens
names=(journal conference talk poster preprint)
keys=("cv-journal" "cv-proceedings" "cv-talk" "cv-poster" "cv-preprint")

# Ensure output directory exists
mkdir -p "$OUT_DIR"

for i in "${!names[@]}"; do
  out_name="${names[i]}"
  keyword="${keys[i]}"
  output="$OUT_DIR/cv-${out_name}.bib"
  echo "Generating $output for keyword $keyword"
  # Create a temporary copy with unknown entry types normalized to @misc
  tmp=$(mktemp)
  sed -E 's/@(online|software|report)/@misc/g' "$MASTER" > "$tmp"
  # Use BibTool's select with proper quoting (field=keyword)
  bibtool --select'{keywords "$keyword"}' "$tmp" -o "$output"
  rm -f "$tmp"
done

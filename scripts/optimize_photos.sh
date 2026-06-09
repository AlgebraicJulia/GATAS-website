#!/usr/bin/env bash
set -euo pipefail

ROOT="assets/photos"
MAX_DIM=2560
QUALITY=82

if ! command -v mogrify >/dev/null 2>&1; then
  echo "optimize-photos-webp: ImageMagick 'mogrify' is required but was not found in PATH."
  exit 1
fi

if [[ ! -d "$ROOT" ]]; then
  exit 0
fi

declare -a candidates=()

if [[ $# -gt 0 ]]; then
  for arg in "$@"; do
    candidates+=("$arg")
  done
elif [[ ! -t 0 ]]; then
  while IFS= read -r p; do
    [[ -n "$p" ]] && candidates+=("$p")
  done
fi

if [[ ${#candidates[@]} -eq 0 ]]; then
  exit 0
fi

changed=0

for src in "${candidates[@]}"; do
  case "$src" in
    "$ROOT"/*) ;;
    *) continue ;;
  esac

  if [[ ! -f "$src" ]]; then
    continue
  fi

  ext="${src##*.}"
  ext="${ext,,}"

  case "$ext" in
    jpg|jpeg|png|webp) ;;
    *) continue ;;
  esac

  info=$(identify -format '%m %w %h' "$src" 2>/dev/null || true)
  if [[ -z "$info" ]]; then
    continue
  fi

  format=$(awk '{print tolower($1)}' <<<"$info")
  width=$(awk '{print $2}' <<<"$info")
  height=$(awk '{print $3}' <<<"$info")

  if [[ ! "$width" =~ ^[0-9]+$ || ! "$height" =~ ^[0-9]+$ ]]; then
    continue
  fi

  longest=$width
  if (( height > width )); then
    longest=$height
  fi

  if [[ "$format" == "webp" ]]; then
    if (( longest > MAX_DIM )); then
      mogrify \
        -auto-orient \
        -resize "${MAX_DIM}x${MAX_DIM}>" \
        -strip \
        -quality "$QUALITY" \
        -define webp:method=6 \
        "$src"
      echo "optimized: $src"
      changed=1
    fi
    continue
  fi

  dst="${src%.*}.webp"

  mogrify \
    -auto-orient \
    -resize "${MAX_DIM}x${MAX_DIM}>" \
    -strip \
    -quality "$QUALITY" \
    -define webp:method=6 \
    -format webp \
    "$src"

  if [[ -f "$dst" ]]; then
    rm -f "$src"
    echo "optimized: $src -> $dst"
    changed=1
  fi
done

if (( changed == 1 )); then
  echo "Updated images in assets/photos. Re-stage changes and commit again."
  exit 1
fi

exit 0
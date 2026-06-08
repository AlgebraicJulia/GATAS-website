#!/usr/bin/env bash
# =============================================================================
# zotero_dump.sh – Export Zotero items for the "CV" saved search into BibLaTeX.
#
# This script is deliberately defensive:
#   • `set -euo pipefail` aborts on any error, undefined variable or pipe failure.
#   • All commands are logged to *stderr* with timestamps.
#   • Required tools are verified before execution.
#   • The output directory is created if missing.
#   • Each download is checked for a successful HTTP status (curl -f).
#   • The script can be reused with optional environment overrides.
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Logging helpers – write to stderr with ISO‑8601 timestamps
# -----------------------------------------------------------------------------
log()   { echo "$(date +'%Y-%m-%d %H:%M:%S') [INFO]  $*" >&2; }
error() { echo "$(date +'%Y-%m-%d %H:%M:%S') [ERROR] $*" >&2; }

# -----------------------------------------------------------------------------
# Configuration – can be overridden via environment variables before running.
# -----------------------------------------------------------------------------
: "${ZOTERO_API:=http://localhost:23119/api}"   # Base API URL
: "${ZOTERO_USER:=0}"                           # Zotero user ID (local API always 0)
: "${ZOTERO_SEARCH:=Z72JGWEB}"                  # Saved‑search key for "CV"
: "${BIBDIR:=assets/bib}"                        # Destination directory for .bib files

ZOTERO_URL="${ZOTERO_API}/users/${ZOTERO_USER}/searches/${ZOTERO_SEARCH}/items"

# -----------------------------------------------------------------------------
# Ensure required binaries are available
# -----------------------------------------------------------------------------
for cmd in curl mkdir; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    error "Required command '$cmd' not found in PATH. Aborting."
    exit 1
  fi
done

# -----------------------------------------------------------------------------
# Create the output directory if it does not exist
# -----------------------------------------------------------------------------
if [[ ! -d "$BIBDIR" ]]; then
  log "Creating bibliography directory: $BIBDIR"
  mkdir -p "$BIBDIR"
fi

# -----------------------------------------------------------------------------
# Mapping of Zotero tag (URL‑encoded) → destination filename (without extension)
# -----------------------------------------------------------------------------
declare -A TAGS=(
  ["cv%2Dtalk"]="cv_talks"
  ["cv%2Dproceedings"]="cv_proceedings"
  ["cv%2Djournal"]="cv_journals"
  ["cv%2Dpreprint"]="cv_preprints"
  ["cv%2Dposter"]="cv_posters"
)

# -----------------------------------------------------------------------------
# Download each bibliography file
# -----------------------------------------------------------------------------
for tag in "${!TAGS[@]}"; do
  filename="${TAGS[$tag]}.bib"
  outpath="${BIBDIR}/${filename}"
  url="${ZOTERO_URL}?tag=${tag}&format=biblatex"

  log "Downloading ${tag} → ${outpath}"
  # -f makes curl exit on HTTP errors, -S shows error message, -L follows redirects
  if ! curl -f -S -L "${url}" -o "${outpath}"; then
    error "Failed to download ${url}. See above for curl error."
    exit 1
  fi
  log "Successfully wrote ${outpath}"
done

log "All bibliography files have been exported successfully."

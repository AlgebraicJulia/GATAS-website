# GATAS Lab Website

This repository builds the GATAS Lab website that and deploys it on Netlify.

To update the website, file a PR against the pages that you want to update. The github actions will:

1. Render the site
2. Post a preview to a private url on netlify on your PR
3. Once merged, deploy the site.

This repo has automated merging of PRs. Once a PR passes CI and is approved by another contributor, it will be automatically merged and deployed.

We use Quarto for this website.

## Zotero Bibliography Export

`scripts/zotero_dump.sh` is a defensive Bash utility that exports items from your local Zotero library (saved‑search **CV**) into CSL JSON (`.json`) files. The script:

- Queries the Zotero local API for each CV‑related tag (`cv‑talk`, `cv‑proceedings`, `cv‑journal`, `cv‑preprint`, `cv‑poster`).
- Writes the results to `assets/bib/` with clear filenames (`cv_talks.json`, `cv_proceedings.json`, …).
- Logs progress and errors to **stderr** with timestamps.
- Aborts on any failure (missing tools, HTTP error, etc.) for safe CI integration.

### Usage
```bash
# Make the script executable (once) and run it
chmod +x scripts/zotero_dump.sh
./scripts/zotero_dump.sh
```
Or simply invoke via Bash:
```bash
bash scripts/zotero_dump.sh
```

### Configuration (environment variables)
| Variable | Default | Description |
|----------|---------|-------------|
| `ZOTERO_API` | `http://localhost:23119/api` | Base URL of the Zotero local API. |
| `ZOTERO_USER` | `0` | User ID for the local API (always `0`). |
| `ZOTERO_SEARCH` | `Z72JGWEB` | Saved‑search key that groups the CV items. |
| `BIBDIR` | `assets/bib` | Directory where the `.json` files will be written. |

You can override any of these variables on the command line, e.g.:
```bash
ZOTERO_SEARCH=MYSEARCH ./scripts/zotero_dump.sh
```

### Requirements
- Bash (≥ 4) with `set -euo pipefail` support.
- `curl` (used with `-f -S -L`).
- Write permission to the `BIBDIR` directory.

The script is safe to run in CI pipelines; it will fail fast and clearly report any problem.

# License

The code in this repository is MIT licensed, feel free to copy and redistribute the code. 

The copy on the pages of the website is copyright James Fairbanks all rights reserved.

#!/usr/bin/env bash
# Compiles main.tex. Must run from the repo root (main.tex uses root-relative
# \include / \addbibresource paths), but keeps all build byproducts out of
# the repo root by relocating/cleaning them after the run.
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SELF_DIR" rev-parse --show-toplevel)"
REL_DIR="${SELF_DIR#"$REPO_ROOT"/}"
TEX="$REL_DIR/main.tex"

cd "$REPO_ROOT"

pdflatex -interaction=nonstopmode "$TEX"
biber main
pdflatex -interaction=nonstopmode "$TEX"
pdflatex -interaction=nonstopmode "$TEX"

mv -f main.pdf "$SELF_DIR/main.pdf"
rm -f main.aux main.bbl main.bcf main.blg main.log main.out main.run.xml main.toc

echo "Built: $SELF_DIR/main.pdf"

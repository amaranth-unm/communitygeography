#!/usr/bin/env bash
# Community Geography adaptation of Xanthan's Optimize Images entry point.
set -euo pipefail
script_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
exec python3 "$script_dir/optimize-images.py" "$@"

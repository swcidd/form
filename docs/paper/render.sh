#!/usr/bin/env bash
# Renders the final project paper to the repository root.
#
#   docs/paper/render.sh
#
# Needs WeasyPrint (pip install weasyprint) on PATH, or set WEASYPRINT to the
# interpreter that has it:
#
#   WEASYPRINT=/path/to/venv/bin/python docs/paper/render.sh
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/../.." && pwd)"
python="${WEASYPRINT:-python3}"

"$python" - "$here" "$root" <<'PY'
import pathlib
import sys

from weasyprint import HTML

here, root = (pathlib.Path(arg) for arg in sys.argv[1:3])
HTML(here / "paper.html", base_url=str(here)).write_pdf(
    root / "SE2142_FinalProject_letmesolothis.pdf"
)
print("wrote", root / "SE2142_FinalProject_letmesolothis.pdf")
PY

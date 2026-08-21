"""
doctor.py -- is the environment healthy, and has _lib drifted?

Two jobs.

1. Environment. Tell you exactly which capability is missing and the single
   command that restores it. Optional dependencies are reported as optional,
   because a missing video encoder should never look like a broken project.

2. Integrity. _lib is shared infrastructure: every visual depends on it, so
   an edit made to fix one figure can silently break forty. This checks the
   recorded hashes and reports any drift loudly. Drift is not forbidden --
   sometimes the harness genuinely needs to grow -- but it should always be
   a deliberate, visible act rather than something that happened in passing.
"""

from __future__ import annotations

import hashlib
import json
import shutil
import subprocess
import sys
from pathlib import Path

LIB = Path(__file__).resolve().parent
INTEGRITY = LIB / ".integrity.json"
SKIP = {".integrity.json", "__pycache__", ".DS_Store"}

OK, WARN, BAD = "  ok  ", " warn ", " FAIL "


# --------------------------------------------------------------------------
# integrity
# --------------------------------------------------------------------------

def _iter_lib_files():
    for p in sorted(LIB.rglob("*")):
        if not p.is_file():
            continue
        rel = p.relative_to(LIB)
        if any(part in SKIP for part in rel.parts):
            continue
        if rel.parts and rel.parts[0] == "vendor":
            continue          # vendored third-party assets are not our code
        yield rel, p


def _hash(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()[:16]


def seal(quiet: bool = False) -> Path:
    """Record current hashes. Run once at install, and again -- deliberately --
    after any sanctioned upgrade to _lib."""
    data = {
        "version": _version(),
        "files": {str(rel): _hash(p) for rel, p in _iter_lib_files()},
    }
    INTEGRITY.write_text(json.dumps(data, indent=2, sort_keys=True), encoding="utf-8")
    if not quiet:
        print(f"  sealed   {len(data['files'])} files in _lib at v{data['version']}")
    return INTEGRITY


def verify() -> tuple[bool, list[str]]:
    if not INTEGRITY.exists():
        return False, ["no .integrity.json -- run:  python _lib/viz.py seal"]

    recorded = json.loads(INTEGRITY.read_text(encoding="utf-8"))["files"]
    current = {str(rel): _hash(p) for rel, p in _iter_lib_files()}

    problems = []
    for name, h in recorded.items():
        if name not in current:
            problems.append(f"deleted:  {name}")
        elif current[name] != h:
            problems.append(f"modified: {name}")
    for name in current:
        if name not in recorded:
            problems.append(f"added:    {name}")
    return (not problems), problems


def _version() -> str:
    vf = LIB / "VERSION"
    return vf.read_text(encoding="utf-8").strip() if vf.exists() else "0"


# --------------------------------------------------------------------------
# environment
# --------------------------------------------------------------------------

def _check_import(mod: str):
    try:
        m = __import__(mod)
        return True, getattr(m, "__version__", "")
    except Exception:
        return False, ""


def check(quiet: bool = False) -> bool:
    rows, healthy = [], True

    rows.append((OK, "python", sys.version.split()[0]))

    for mod, why, fix in [
        ("numpy", "required", "pip install numpy"),
        ("pandas", "required", "pip install pandas"),
        ("plotly", "required", "pip install plotly"),
        ("yaml", "required", "pip install pyyaml"),
    ]:
        got, ver = _check_import(mod)
        if got:
            rows.append((OK, mod, ver))
        else:
            healthy = False
            rows.append((BAD, mod, f"{why} -- {fix}"))

    got, ver = _check_import("pyarrow")
    rows.append((OK, "pyarrow", ver) if got else
                (WARN, "pyarrow", "optional -- only needed for .parquet data"))

    # image export: kaleido present is not enough, it also wants a browser
    png_ok = False
    got, _ = _check_import("kaleido")
    if not got:
        rows.append((WARN, "png export", "optional -- pip install kaleido"))
    else:
        try:
            import plotly.graph_objects as go
            import tempfile
            with tempfile.NamedTemporaryFile(suffix=".png") as tf:
                go.Figure(go.Scatter(x=[0, 1], y=[0, 1])).write_image(
                    tf.name, width=200, height=150)
            png_ok = True
            rows.append((OK, "png export", "kaleido + browser"))
        except Exception as exc:
            msg = str(exc).lower()
            hint = ("run:  plotly_get_chrome" if "chrome" in msg or "browser" in msg
                    else str(exc).splitlines()[0][:70])
            rows.append((WARN, "png export", f"optional -- {hint}"))

    ff = shutil.which("ffmpeg")
    if ff and png_ok:
        rows.append((OK, "mp4 export", "ffmpeg + png export"))
    elif ff:
        rows.append((WARN, "mp4 export", "optional -- needs png export too"))
    else:
        rows.append((WARN, "mp4 export", "optional -- install ffmpeg"))

    rs = shutil.which("Rscript")
    rows.append((OK, "R models", _rversion(rs)) if rs else
                (WARN, "R models", "optional -- only needed for model.R visuals"))

    vend = (LIB / "vendor" / "plotly.min.js").exists()
    rows.append((OK, "offline assets", "vendored") if vend else
                (WARN, "offline assets", "using CDN -- run: viz.py vendor"))

    intact, problems = verify()
    if intact:
        rows.append((OK, "_lib integrity", f"v{_version()} unmodified"))
    else:
        rows.append((WARN, "_lib integrity", f"{len(problems)} change(s)"))

    if not quiet:
        print()
        for status, name, detail in rows:
            print(f"  [{status}] {name:<16} {detail}")
        if not intact:
            print("\n  _lib has drifted from its sealed state:")
            for p in problems:
                print(f"      {p}")
            print("\n  If this was deliberate (a sanctioned upgrade), re-seal:")
            print("      python _lib/viz.py seal")
            print("  If not, restore _lib from the installer skill or version control.")
        print()
    return healthy


def _rversion(rscript: str) -> str:
    try:
        out = subprocess.run([rscript, "--version"], capture_output=True,
                             text=True, timeout=10)
        return (out.stdout or out.stderr).strip().splitlines()[0][:40]
    except Exception:
        return "present"

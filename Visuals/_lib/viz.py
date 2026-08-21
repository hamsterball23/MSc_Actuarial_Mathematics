#!/usr/bin/env python3
"""
viz.py -- the only command you need to remember.

    python _lib/viz.py new <name> --course MathFin [--lang r]
    python _lib/viz.py render <name> [--formats html,png,mp4] [--force]
    python _lib/viz.py render --all
    python _lib/viz.py site
    python _lib/viz.py build            # render --all, then site
    python _lib/viz.py doctor
    python _lib/viz.py seal
    python _lib/viz.py vendor

Run it from anywhere; paths are resolved relative to this file.
"""

from __future__ import annotations

import argparse
import sys
import traceback
from pathlib import Path

LIB = Path(__file__).resolve().parent
ROOT = LIB.parent                      # the Visuals/ folder
sys.path.insert(0, str(LIB))

PROJECT = ROOT.parent.name.replace("_", " ")


def _resolve(name: str) -> Path:
    p = ROOT / name
    if (p / "meta.yaml").exists():
        return p
    p2 = Path(name).resolve()
    if (p2 / "meta.yaml").exists():
        return p2
    raise SystemExit(f"no visual named '{name}' in {ROOT}")


def cmd_new(a):
    import scaffold
    scaffold.create(ROOT, a.name, course=a.course or "",
                    language=a.lang, title=a.title or "")


def cmd_render(a):
    import render
    formats = [f.strip() for f in a.formats.split(",")] if a.formats else None
    if a.all:
        import gallery as _gallery
        targets = _gallery.discover(ROOT)
        if not targets:
            raise SystemExit(f"no visuals found in {ROOT}")
    else:
        if not a.name:
            raise SystemExit("give a visual name, or use --all")
        targets = [_resolve(a.name)]

    failures = []
    for t in targets:
        try:
            render.render_visual(t, formats=formats, force_model=a.force)
        except Exception as exc:
            failures.append((t.name, exc))
            print(f"  {t.name}\n    FAIL   {type(exc).__name__}: {exc}")
            if a.traceback:
                traceback.print_exc()

    if failures:
        print(f"\n  {len(failures)} of {len(targets)} failed. "
              f"Re-run one with --traceback for detail.")
        return 1
    return 0


def cmd_site(a):
    import gallery as _gallery
    _gallery.build(ROOT, project_name=PROJECT)


def cmd_build(a):
    a.all, a.name, a.formats, a.force, a.traceback = True, None, None, False, False
    rc = cmd_render(a)
    cmd_site(a)
    print(f"\n  open  {ROOT / '_site' / 'index.html'}")
    return rc


def cmd_doctor(a):
    import doctor
    ok = doctor.check()
    return 0 if ok else 1


def cmd_seal(a):
    import doctor
    doctor.seal()


def cmd_vendor(a):
    """Download plotly.js locally so the gallery works offline and does not
    depend on a CDN that may not exist in a few years."""
    import urllib.request
    vend = LIB / "vendor"
    vend.mkdir(exist_ok=True)
    assets = {
        "plotly.min.js": "https://cdn.plot.ly/plotly-3.0.1.min.js",
        "marked.min.js": "https://cdn.jsdelivr.net/npm/marked@11.1.1/marked.min.js",
        "katex.min.js": "https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.js",
        "katex.min.css": "https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.css",
        "katex-auto-render.min.js":
            "https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/contrib/auto-render.min.js",
    }
    for name, url in assets.items():
        dest = vend / name
        if dest.exists() and not a.force:
            print(f"  have     {name}")
            continue
        try:
            print(f"  fetching {name} ...", end=" ", flush=True)
            urllib.request.urlretrieve(url, dest)
            print(f"{dest.stat().st_size // 1024} KB")
        except Exception as exc:
            print(f"failed ({exc})")
    print("\n  Re-render so pages pick up the local copies:")
    print("      python _lib/viz.py build")


def main(argv=None):
    ap = argparse.ArgumentParser(
        prog="viz", description="Study-visual harness.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__.split("Run it from")[0].split("viz.py --", 1)[0])
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("new", help="scaffold a new visual")
    p.add_argument("name")
    p.add_argument("--course", help="e.g. MathFin, StatIns, QRM")
    p.add_argument("--lang", default="python", choices=["python", "r"])
    p.add_argument("--title")
    p.set_defaults(fn=cmd_new)

    p = sub.add_parser("render", help="render one visual, or --all")
    p.add_argument("name", nargs="?")
    p.add_argument("--all", action="store_true")
    p.add_argument("--formats", help="comma list: html,png,mp4")
    p.add_argument("--force", action="store_true", help="re-run the model")
    p.add_argument("--traceback", action="store_true")
    p.set_defaults(fn=cmd_render)

    p = sub.add_parser("site", help="rebuild the gallery index")
    p.set_defaults(fn=cmd_site)

    p = sub.add_parser("build", help="render everything, then the gallery")
    p.set_defaults(fn=cmd_build)

    p = sub.add_parser("doctor", help="check environment and _lib integrity")
    p.set_defaults(fn=cmd_doctor)

    p = sub.add_parser("seal", help="re-record _lib hashes after an upgrade")
    p.set_defaults(fn=cmd_seal)

    p = sub.add_parser("vendor", help="download js/css locally for offline use")
    p.add_argument("--force", action="store_true")
    p.set_defaults(fn=cmd_vendor)

    a = ap.parse_args(argv)
    return a.fn(a) or 0


if __name__ == "__main__":
    sys.exit(main())

"""
gallery.py -- build the gallery index from whatever visuals exist on disk.

The manifest is inlined into the HTML rather than fetched as JSON. That is
deliberate: browsers block fetch() over file:// for local files, so an
inlined manifest is what lets you open _site/index.html by double-clicking
it, with no server. The same file also works unchanged if you later push
the folder to GitHub Pages.
"""

from __future__ import annotations

import datetime as _dt
import json
from pathlib import Path

LIB = Path(__file__).resolve().parent


def discover(visuals_root: Path) -> list[Path]:
    """Every directory holding a meta.yaml, excluding underscore folders."""
    visuals_root = Path(visuals_root)
    found = []
    for p in sorted(visuals_root.iterdir()):
        if not p.is_dir() or p.name.startswith("_") or p.name.startswith("."):
            continue
        if (p / "meta.yaml").exists():
            found.append(p)
    return found


def _entry(visual_dir: Path) -> dict:
    import yaml
    meta = yaml.safe_load((visual_dir / "meta.yaml").read_text(encoding="utf-8")) or {}
    out = visual_dir / "out"

    notes = ""
    notes_path = visual_dir / "notes.md"
    if notes_path.exists():
        notes = notes_path.read_text(encoding="utf-8")

    entry = {
        "id": meta.get("id", visual_dir.name),
        "dir": visual_dir.name,
        "title": meta.get("title", visual_dir.name),
        "summary": meta.get("summary", ""),
        "courses": meta.get("courses", []) or [],
        "topics": meta.get("topics", []) or [],
        "source": meta.get("source", ""),
        "has_png": (out / "thumb.png").exists(),
        "has_mp4": (out / "clip.mp4").exists(),
        "built": (out / "index.html").exists(),
    }
    entry["haystack"] = " ".join([
        entry["title"], entry["summary"], entry["source"],
        " ".join(entry["courses"]), " ".join(entry["topics"]), notes,
    ]).lower()
    return entry


def build(visuals_root: Path, project_name: str = "MSc Actuarial Mathematics",
          quiet: bool = False) -> Path:
    visuals_root = Path(visuals_root).resolve()
    site_dir = visuals_root / "_site"
    site_dir.mkdir(exist_ok=True)

    dirs = discover(visuals_root)
    manifest = [_entry(d) for d in dirs]
    manifest.sort(key=lambda e: (e["courses"][0] if e["courses"] else "zz",
                                 e["title"].lower()))

    tpl = (LIB / "templates" / "gallery.html").read_text(encoding="utf-8")
    page = (
        tpl.replace("__PROJECT__", _esc(project_name))
        .replace("__BUILT__", _dt.date.today().isoformat())
        .replace("/*__MANIFEST__*/[]", json.dumps(manifest, ensure_ascii=False, default=str))
    )
    index = site_dir / "index.html"
    index.write_text(page, encoding="utf-8")

    if not quiet:
        unbuilt = [e["id"] for e in manifest if not e["built"]]
        print(f"  gallery  {len(manifest)} visuals -> {index}")
        if unbuilt:
            print(f"  note     not yet rendered: {', '.join(unbuilt)}")
            print("           run:  python _lib/viz.py render --all")
    return index


def _esc(s: str) -> str:
    return (str(s).replace("&", "&amp;").replace("<", "&lt;")
            .replace(">", "&gt;").replace('"', "&quot;"))

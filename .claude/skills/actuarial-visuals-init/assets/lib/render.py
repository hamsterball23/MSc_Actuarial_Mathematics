"""
render.py -- turn one visual's Scene into every output format.

Design rule: HTML always works. PNG and MP4 depend on external binaries
(a headless Chrome for plotly's image export, ffmpeg for video) which are
exactly the things that break when you come back to a project after six
months. So they are best-effort: if a dependency is missing the render
still succeeds, the missing format is reported, and `viz.py doctor` tells
you the one command that fixes it.

Nothing here should ever need editing to support a new visual. If it seems
to, read references/lib-api.md in the authoring skill first.
"""

from __future__ import annotations

import hashlib
import importlib.util
import json
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

import plotly.graph_objects as go
import plotly.io as pio

import theme
from api import Context, Scene

LIB = Path(__file__).resolve().parent
PLOTLY_CDN = "https://cdn.plot.ly/plotly-3.0.1.min.js"


# --------------------------------------------------------------------------
# result reporting
# --------------------------------------------------------------------------

@dataclass
class RenderResult:
    visual_id: str
    written: list = None
    skipped: list = None
    warnings: list = None
    ran_model: bool = False
    root: Path = None

    def __post_init__(self):
        self.written = self.written or []
        self.skipped = self.skipped or []
        self.warnings = self.warnings or []

    def report(self) -> str:
        lines = [f"  {self.visual_id}"]
        if self.ran_model:
            lines.append("    model  ran")
        for w in self.written:
            size = ""
            if self.root:
                p = self.root / w
                if p.exists():
                    size = f"  ({_human(p.stat().st_size)})"
            lines.append(f"    ok     {w}{size}")
        for name, why in self.skipped:
            lines.append(f"    skip   {name} -- {why}")
        for w in self.warnings:
            lines.append(f"    warn   {w}")
        return "\n".join(lines)


def _human(n: int) -> str:
    for unit in ("B", "KB", "MB", "GB"):
        if n < 1024 or unit == "GB":
            return f"{n:.0f} {unit}" if unit == "B" else f"{n:.1f} {unit}"
        n /= 1024


# --------------------------------------------------------------------------
# meta
# --------------------------------------------------------------------------

def load_meta(visual_dir: Path) -> dict:
    import yaml
    path = visual_dir / "meta.yaml"
    if not path.exists():
        raise FileNotFoundError(f"{path} is missing -- every visual needs one.")
    meta = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    meta.setdefault("id", visual_dir.name)
    meta.setdefault("title", visual_dir.name.replace("-", " ").title())
    return meta


# --------------------------------------------------------------------------
# model step
# --------------------------------------------------------------------------

def _model_stamp(visual_dir: Path, meta: dict) -> str:
    """Fingerprint of everything that should invalidate cached data."""
    h = hashlib.sha256()
    for name in ("model.py", "model.R"):
        p = visual_dir / name
        if p.exists():
            h.update(p.read_bytes())
    h.update(json.dumps(
        {"seed": meta.get("seed"), "params": meta.get("params", {})},
        sort_keys=True, default=str,
    ).encode())
    return h.hexdigest()


def run_model(visual_dir: Path, meta: dict, force: bool = False) -> bool:
    """Run model.py or model.R if the inputs changed. Returns True if run."""
    py, r = visual_dir / "model.py", visual_dir / "model.R"
    if not py.exists() and not r.exists():
        return False

    data_dir = visual_dir / "data"
    stamp_file = data_dir / ".stamp"
    stamp = _model_stamp(visual_dir, meta)
    if not force and stamp_file.exists() and stamp_file.read_text().strip() == stamp:
        if any(p.name != ".stamp" for p in data_dir.glob("*")):
            return False

    data_dir.mkdir(parents=True, exist_ok=True)

    if py.exists():
        cmd = [sys.executable, str(py)]
    else:
        rscript = shutil.which("Rscript")
        if not rscript:
            raise RuntimeError(
                f"{r.name} needs Rscript on PATH but it was not found.\n"
                "Install R, or port the model to model.py."
            )
        cmd = [rscript, "--vanilla", str(r)]

    # Two forms of the same thing. JSON for Python models; a flat key/value
    # CSV for R, so that model.R needs no packages at all -- base R's
    # read.csv is enough. A model that depends on nothing is a model that
    # still runs in three years.
    (data_dir / ".meta.json").write_text(
        json.dumps(meta, indent=2, default=str), encoding="utf-8")
    _write_flat_meta(meta, data_dir / ".meta.csv")

    proc = subprocess.run(cmd, cwd=visual_dir, capture_output=True, text=True)
    if proc.returncode != 0:
        raise RuntimeError(
            f"model step failed for {visual_dir.name}\n"
            f"--- stdout ---\n{proc.stdout}\n--- stderr ---\n{proc.stderr}"
        )
    stamp_file.write_text(stamp)
    return True


# --------------------------------------------------------------------------
# scene step
# --------------------------------------------------------------------------

def build_scene(visual_dir: Path, meta: dict) -> Scene:
    scene_path = visual_dir / "scene.py"
    if not scene_path.exists():
        raise FileNotFoundError(f"{scene_path} is missing -- every visual needs one.")

    theme.install()

    spec = importlib.util.spec_from_file_location(
        f"visual_{visual_dir.name.replace('-', '_')}", scene_path
    )
    module = importlib.util.module_from_spec(spec)
    sys.path.insert(0, str(visual_dir))
    try:
        spec.loader.exec_module(module)
    finally:
        sys.path.pop(0)

    if not hasattr(module, "build"):
        raise AttributeError(
            f"{scene_path} must define build(ctx) -> Scene. See lib-api.md."
        )

    scene = module.build(Context(visual_dir, meta))
    if not isinstance(scene, Scene):
        raise TypeError(
            f"{scene_path}:build returned {type(scene).__name__}, expected Scene."
        )
    theme.apply(scene.figure)
    return scene


def compress(scene: Scene, precision: int = 5) -> int:
    """Round numeric arrays in frames and count the resulting payload.

    Plotly serialises float64 at full precision, which roughly doubles file
    size for no visible benefit -- nobody reads the seventeenth significant
    figure off a chart. Rounding is applied only to frame data, never to the
    base figure, so exported PNGs stay exact.

    Returns the total number of points across all frames, which the caller
    uses to warn when an animation is heading for an unusable file size.
    """
    import numpy as np

    total = 0
    for frame in scene.frames:
        for trace in frame.data:
            for attr in ("x", "y", "z"):
                val = getattr(trace, attr, None)
                if val is None:
                    continue
                arr = np.asarray(val)
                if arr.dtype.kind == "f":
                    setattr(trace, attr, np.round(arr, precision))
                total += arr.size
    return total


def attach_animation(scene: Scene, precision: int = 5,
                     budget: int = 2_000_000) -> tuple[go.Figure, list]:
    """Wire frames into plotly's slider + play controls.

    Returns the figure and a list of warnings worth surfacing.
    """
    fig = scene.figure
    warnings = []
    if not scene.animated:
        return fig, warnings

    points = compress(scene, precision)
    if points > budget:
        mb = points * 12 / 1e6
        warnings.append(
            f"animation carries ~{points:,} points (~{mb:.0f} MB of HTML). "
            f"Draw static context once in the base figure and set "
            f"Frame(targets=[...]) so frames only carry what moves."
        )

    fig.frames = [
        go.Frame(name=f.name, data=list(f.data),
                 traces=list(f.targets) if f.targets is not None else None,
                 layout=go.Layout(**f.layout) if f.layout else None)
        for f in scene.frames
    ]

    step_ms = 60
    fig.update_layout(
        updatemenus=[dict(
            type="buttons", direction="left",
            x=0.0, y=1.14, xanchor="left", yanchor="top",
            pad=dict(t=0, r=8), showactive=False,
            bgcolor="#ffffff", bordercolor=theme.C.grid, borderwidth=1,
            font=dict(size=12),
            buttons=[
                dict(label="Play", method="animate", args=[None, dict(
                    frame=dict(duration=step_ms, redraw=True),
                    transition=dict(duration=0), fromcurrent=True,
                    mode="immediate")]),
                dict(label="Pause", method="animate", args=[[None], dict(
                    frame=dict(duration=0, redraw=False),
                    transition=dict(duration=0), mode="immediate")]),
            ],
        )],
        sliders=[dict(
            active=0, x=0.0, y=0.0, len=1.0, xanchor="left", yanchor="top",
            pad=dict(t=44, b=8),
            currentvalue=dict(prefix=(scene.axis_label + "  ") if scene.axis_label else "",
                              font=dict(size=13, color=theme.C.muted),
                              xanchor="left"),
            tickcolor=theme.C.axis, font=dict(size=11),
            steps=[dict(label=f.name, method="animate",
                        args=[[f.name], dict(
                            frame=dict(duration=0, redraw=True),
                            transition=dict(duration=0), mode="immediate")])
                   for f in scene.frames],
        )],
    )
    return fig, warnings


# --------------------------------------------------------------------------
# output writers
# --------------------------------------------------------------------------

def _plotly_js_ref(site_relative: bool) -> str:
    """Prefer a vendored plotly.js so the gallery works offline and forever."""
    vendored = LIB / "vendor" / "plotly.min.js"
    if vendored.exists():
        return "../_lib/vendor/plotly.min.js" if site_relative else str(vendored)
    return PLOTLY_CDN


def write_html(fig: go.Figure, out: Path, meta: dict, scene: Scene) -> Path:
    """Self-contained page: figure + notes + parameters."""
    out.parent.mkdir(parents=True, exist_ok=True)

    vendored = LIB / "vendor" / "plotly.min.js"
    if vendored.exists():
        js_arg = vendored.read_text(encoding="utf-8")
        include = js_arg
    else:
        include = "cdn"

    fig_html = pio.to_html(
        fig, include_plotlyjs=include, full_html=False,
        div_id="figure", config=dict(
            displaylogo=False, responsive=True,
            toImageButtonOptions=dict(format="png", scale=2,
                                      filename=meta.get("id", "figure")),
            modeBarButtonsToRemove=["lasso2d", "select2d"],
        ),
    )

    notes_md = ""
    notes_path = out.parent.parent / "notes.md"
    if notes_path.exists():
        notes_md = notes_path.read_text(encoding="utf-8")

    tpl = (LIB / "templates" / "visual.html").read_text(encoding="utf-8")
    page = (
        tpl.replace("__TITLE__", _esc(meta.get("title", "")))
        .replace("__SUBTITLE__", _esc(scene.caption or meta.get("summary", "")))
        .replace("__FIGURE__", fig_html)
        .replace('/*__NOTES__*/""', json.dumps(notes_md))
        .replace("/*__META__*/{}", json.dumps(_public_meta(meta), default=str))
    )
    out.write_text(page, encoding="utf-8")
    return out


def write_png(fig: go.Figure, out: Path, width=1200, height=750, scale=2):
    out.parent.mkdir(parents=True, exist_ok=True)
    fig.write_image(str(out), width=width, height=height, scale=scale)
    return out


def write_mp4(scene: Scene, out: Path, fps: int = 15,
              width=1200, height=750) -> Path:
    """Frames -> PNG -> ffmpeg. Same Scene, no extra authoring."""
    import tempfile

    if not scene.animated:
        raise RuntimeError("no frames to animate")
    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        raise RuntimeError("ffmpeg not on PATH")

    out.parent.mkdir(parents=True, exist_ok=True)
    base = scene.figure

    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        base_traces = list(base.data)
        for i, frame in enumerate(scene.frames):
            if frame.targets is None:
                traces = list(frame.data)
            else:
                # Targeted frames only carry what moves, so rebuild the full
                # picture by overlaying them onto the static base.
                traces = list(base_traces)
                for idx, tr in zip(frame.targets, frame.data):
                    traces[idx] = tr
            snap = go.Figure(data=traces, layout=base.layout)
            snap.update_layout(updatemenus=[], sliders=[])
            if frame.layout:
                snap.update_layout(**frame.layout)
            label = f"{scene.axis_label}  {frame.name}".strip()
            snap.add_annotation(
                text=label, xref="paper", yref="paper", x=0.0, y=1.06,
                xanchor="left", yanchor="bottom", showarrow=False,
                font=dict(family="ui-monospace, monospace", size=13,
                          color=theme.C.muted),
            )
            snap.write_image(str(tmp / f"f{i:05d}.png"),
                             width=width, height=height, scale=1)

        cmd = [ffmpeg, "-y", "-loglevel", "error", "-framerate", str(fps),
               "-i", str(tmp / "f%05d.png"),
               "-c:v", "libx264", "-pix_fmt", "yuv420p",
               "-vf", "pad=ceil(iw/2)*2:ceil(ih/2)*2",
               "-movflags", "+faststart", str(out)]
        proc = subprocess.run(cmd, capture_output=True, text=True)
        if proc.returncode != 0:
            raise RuntimeError(f"ffmpeg failed:\n{proc.stderr[:800]}")
    return out


# --------------------------------------------------------------------------
# orchestration
# --------------------------------------------------------------------------

def render_visual(visual_dir: Path, formats=None, force_model=False,
                  quiet=False) -> RenderResult:
    visual_dir = Path(visual_dir).resolve()
    meta = load_meta(visual_dir)
    requested = formats or meta.get("formats") or ["html", "png"]
    result = RenderResult(visual_id=meta["id"], root=visual_dir)

    result.ran_model = run_model(visual_dir, meta, force=force_model)

    scene = build_scene(visual_dir, meta)
    fig, warnings = attach_animation(
        scene, precision=int(meta.get("precision", 5)))
    result.warnings.extend(warnings)

    out_dir = visual_dir / "out"
    out_dir.mkdir(exist_ok=True)

    if "html" in requested:
        write_html(fig, out_dir / "index.html", meta, scene)
        result.written.append("out/index.html")

    if "png" in requested:
        try:
            static = go.Figure(fig)
            static.update_layout(updatemenus=[], sliders=[])
            write_png(static, out_dir / "thumb.png")
            result.written.append("out/thumb.png")
        except Exception as exc:
            result.skipped.append(("out/thumb.png", _image_hint(exc)))

    if "mp4" in requested:
        if not scene.animated:
            result.skipped.append(("out/clip.mp4", "scene has no frames"))
        else:
            try:
                fps = int(meta.get("fps", 15))
                write_mp4(scene, out_dir / "clip.mp4", fps=fps)
                result.written.append("out/clip.mp4")
            except Exception as exc:
                result.skipped.append(("out/clip.mp4", _image_hint(exc)))

    if not quiet:
        print(result.report())
    return result


# --------------------------------------------------------------------------
# helpers
# --------------------------------------------------------------------------

def _write_flat_meta(meta: dict, path: Path) -> None:
    """Flatten meta to key,value rows. Nested params become 'params.<name>'."""
    import csv

    rows = []
    for key, val in meta.items():
        if key == "params" and isinstance(val, dict):
            for pk, pv in val.items():
                rows.append((f"params.{pk}", pv))
        elif isinstance(val, (list, tuple)):
            rows.append((key, "|".join(str(v) for v in val)))
        elif isinstance(val, dict):
            continue
        else:
            rows.append((key, val))

    with path.open("w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["key", "value"])
        for k, v in rows:
            w.writerow([k, v])


def _image_hint(exc: Exception) -> str:
    msg = str(exc)
    low = msg.lower()
    if "chrome" in low or "kaleido" in low:
        return ("needs a headless browser -- run:  plotly_get_chrome  "
                "(or: pip install kaleido)")
    if "ffmpeg" in low:
        return "needs ffmpeg on PATH -- e.g. brew install ffmpeg"
    return msg.strip().splitlines()[0][:160] if msg.strip() else type(exc).__name__


def _public_meta(meta: dict) -> dict:
    keep = ("id", "title", "summary", "courses", "topics", "source",
            "seed", "params", "created", "formats")
    return {k: meta[k] for k in keep if k in meta}


def _esc(s: str) -> str:
    return (str(s).replace("&", "&amp;").replace("<", "&lt;")
            .replace(">", "&gt;").replace('"', "&quot;"))

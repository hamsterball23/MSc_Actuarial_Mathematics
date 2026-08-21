"""
scaffold.py -- create a new visual folder with the contract already wired up.

Friction at creation time is what kills projects like this. One command
should get you to the point where you are writing maths, not boilerplate.
"""

from __future__ import annotations

import datetime as _dt
import re
from pathlib import Path

META_TPL = """\
# What this visual is, so the gallery and future-you can find it.
id: {vid}
title: "{title}"
summary: "One line. What does the picture show?"

# Filters in the gallery. A visual can belong to several courses.
courses: [{course}]
topics: []

# Where in the material this comes from -- lecture, chapter, exercise.
source: ""

# Reproducibility. Never use a literal seed in model.py; read ctx.seed.
seed: {seed}

# Model constants. Surfaced next to the figure, so they stay honest.
params: {{}}

# html always works. png needs a headless browser, mp4 needs frames + ffmpeg.
formats: [html, png]
fps: 15

created: {today}
"""

MODEL_PY_TPL = '''\
"""
model.py -- computation only. No plotting, no file layout decisions.

Runs with the visual folder as cwd. Write artifacts into data/.
Read parameters from meta.yaml so they stay visible in the gallery.
"""

import json
import sys
from pathlib import Path

import numpy as np
import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "_lib"))
from api import rng, save  # noqa: E402

HERE = Path(__file__).resolve().parent
DATA = HERE / "data"
META = json.loads((DATA / ".meta.json").read_text())
P = META.get("params", {{}})
SEED = int(META.get("seed", 0))


def main():
    r = rng(SEED)

    # --- your model here -------------------------------------------------
    n = int(P.get("n", 200))
    df = pd.DataFrame({{"x": np.arange(n), "y": r.standard_normal(n).cumsum()}})
    # ---------------------------------------------------------------------

    save(df, DATA / "series.csv")


if __name__ == "__main__":
    main()
'''

MODEL_R_TPL = '''\
# model.R -- computation only, in R. Runs with the visual folder as cwd.
# Write artifacts into data/ as CSV; the Python scene reads them back.
#
# Deliberately package-free: base R only. The harness writes data/.meta.csv
# as flat key,value rows, so no JSON parser is needed and this still runs
# on a fresh R install years from now.

meta <- read.csv("data/.meta.csv", stringsAsFactors = FALSE)
getp <- function(key, default) {
  hit <- meta$value[meta$key == key]
  if (length(hit) == 0 || is.na(hit[1]) || hit[1] == "") default else hit[1]
}

set.seed(as.integer(getp("seed", 0)))

# --- your model here ---------------------------------------------------
n  <- as.integer(getp("params.n", 200))
df <- data.frame(x = seq_len(n), y = cumsum(rnorm(n)))
# -----------------------------------------------------------------------

write.csv(df, "data/series.csv", row.names = FALSE)
'''

SCENE_TPL = '''\
"""
scene.py -- what gets drawn. No simulation, no file writing.

Return a Scene. The harness applies the house theme, wires up the slider,
and produces HTML / PNG / MP4 from the same object.
"""

import sys
from pathlib import Path

import plotly.graph_objects as go

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "_lib"))
from api import Frame, Scene  # noqa: E402
from theme import C, annotate  # noqa: E402


def build(ctx):
    df = ctx.load("series.csv")

    fig = go.Figure()
    fig.add_trace(go.Scatter(
        x=df["x"], y=df["y"], mode="lines",
        line=dict(color=C.diffusion, width=1.6),
        name="path", hovertemplate="x=%{{x}}<br>y=%{{y:.3f}}<extra></extra>",
    ))
    fig.update_layout(
        title="{title}",
        xaxis_title="x",
        yaxis_title="y",
        height=520,
    )
    annotate(fig, f"seed={{ctx.seed}}  n={{len(df)}}")

    return Scene(
        figure=fig,
        caption="Replace this with the thing worth noticing.",
    )
'''

NOTES_TPL = """\
## What this shows

One paragraph. State the object being drawn and the claim the picture makes.

## The maths

$$
\\text{{write the definition or result here}}
$$

Inline maths works too: $\\mathbb{{E}}[X_t] = 0$.

## What to notice

- The observation you would want to be reminded of before an exam.
- A second one, if there is one.

## Assumptions and limits

- Where this picture is misleading, or what it quietly assumes.

## Source

{source}
"""


def slugify(text: str) -> str:
    s = re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")
    return re.sub(r"-{2,}", "-", s)


def create(visuals_root: Path, name: str, course: str = "",
           language: str = "python", title: str = "",
           quiet: bool = False) -> Path:
    visuals_root = Path(visuals_root).resolve()
    vid = slugify(name)
    if not vid:
        raise ValueError("name produced an empty id")

    visual_dir = visuals_root / vid
    if visual_dir.exists():
        raise FileExistsError(f"{visual_dir} already exists")

    title = title or name.replace("-", " ").strip().capitalize()
    seed = abs(hash(vid)) % 90000 + 10000

    (visual_dir / "data").mkdir(parents=True)
    (visual_dir / "out").mkdir()

    (visual_dir / "meta.yaml").write_text(
        META_TPL.format(vid=vid, title=title, course=course, seed=seed,
                        today=_dt.date.today().isoformat()),
        encoding="utf-8")

    if language.lower() in ("r", "rlang"):
        (visual_dir / "model.R").write_text(MODEL_R_TPL, encoding="utf-8")
    else:
        (visual_dir / "model.py").write_text(
            MODEL_PY_TPL.format(), encoding="utf-8")

    (visual_dir / "scene.py").write_text(
        SCENE_TPL.format(title=title), encoding="utf-8")
    (visual_dir / "notes.md").write_text(
        NOTES_TPL.format(source=""), encoding="utf-8")
    (visual_dir / "data" / ".gitkeep").touch()

    if not quiet:
        print(f"  created  {visual_dir}")
        print(f"    edit   {vid}/meta.yaml     params, course, topics")
        model = "model.R" if language.lower().startswith("r") else "model.py"
        print(f"    edit   {vid}/{model}       the computation")
        print(f"    edit   {vid}/scene.py      the picture")
        print(f"    edit   {vid}/notes.md      the maths and what to notice")
        print(f"    then   python _lib/viz.py render {vid}")
    return visual_dir

"""
api.py -- the contract between a visual and the render harness.

A visual never imports plotly's renderers, never writes files, and never
worries about output formats. It builds a Scene; the harness turns that
Scene into HTML, PNG and MP4.

Everything a visual is allowed to rely on is in this file. If you find
yourself wanting something that is not here, see the "Extending" section
of the authoring skill -- the answer is almost never to edit _lib.

Stability: this module is versioned. Additive changes only.
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Sequence

API_VERSION = "1.0"


# --------------------------------------------------------------------------
# Frames -- one step along a swept parameter
# --------------------------------------------------------------------------

@dataclass
class Frame:
    """One step of an animation.

    ``name`` is what appears on the slider tick, so keep it short and
    quantitative: "t=0.50", "rho=-0.7", "u=95%".

    ``data`` is a list of plotly traces (go.Scatter, go.Surface, ...) that
    replace traces in the base figure for this step.

    ``targets`` says which base-figure trace indices those replacements
    apply to. Leave it None and the frame updates traces 0, 1, 2, ... in
    order, which requires ``data`` to cover every trace in the figure.

    Setting ``targets`` matters more than it looks. Animation payload is
    frames x traces x points, so re-sending a hundred static background
    traces sixty times is how a 200 KB figure becomes a 50 MB one. Draw the
    unchanging context once in the base figure, animate only what moves,
    and name those indices here.

    ``layout`` is an optional dict of layout updates for this step, useful
    for a moving annotation or a title reporting the current parameter.
    """

    name: str
    data: Sequence[Any]
    targets: Sequence[int] | None = None
    layout: dict = field(default_factory=dict)


# --------------------------------------------------------------------------
# Scene -- what a visual returns
# --------------------------------------------------------------------------

@dataclass
class Scene:
    """The complete description of one visual.

    ``figure`` is a plotly ``go.Figure``. Build it however you like; the
    house theme is applied by the harness afterwards, so you do not need to
    set colours, fonts or margins.

    ``frames`` turns the scene into an animation. Leave empty for a static
    figure. The base figure should show the *first* frame's state so the
    HTML looks right before anyone presses play.

    ``axis_label`` names what the slider sweeps ("Time t", "Correlation rho").
    It is shown as the slider prefix and in the video's corner overlay.

    ``caption`` is one or two sentences printed under the figure. Use it for
    the thing you want to notice, not for restating the title.
    """

    figure: Any
    frames: Sequence[Frame] = field(default_factory=list)
    axis_label: str = ""
    caption: str = ""

    @property
    def animated(self) -> bool:
        return len(self.frames) > 0


# --------------------------------------------------------------------------
# Context -- what a visual receives
# --------------------------------------------------------------------------

class Context:
    """Paths and data access handed to ``scene.build``.

    Never construct this yourself -- the harness does it.
    """

    def __init__(self, visual_dir: Path, meta: dict):
        self.visual_dir = Path(visual_dir)
        self.data_dir = self.visual_dir / "data"
        self.out_dir = self.visual_dir / "out"
        self.meta = meta

    # -- identity ---------------------------------------------------------

    @property
    def id(self) -> str:
        return self.meta.get("id", self.visual_dir.name)

    @property
    def title(self) -> str:
        return self.meta.get("title", self.id)

    @property
    def seed(self) -> int:
        """The recorded seed. Always use this rather than a literal, so the
        figure you studied from can be regenerated exactly."""
        return int(self.meta.get("seed", 0))

    @property
    def params(self) -> dict:
        """Free-form parameter block from meta.yaml. Use it for model
        constants (sigma, kappa, n_paths) so they are visible next to the
        figure instead of buried in code."""
        return dict(self.meta.get("params", {}))

    def param(self, name: str, default=None):
        return self.params.get(name, default)

    # -- data -------------------------------------------------------------

    def load(self, name: str):
        """Load an artifact from ``data/`` by filename.

        Dispatches on extension: .csv and .tsv and .parquet return a pandas
        DataFrame, .json returns the parsed object, .npy returns an array.
        This is the boundary that lets a model be written in R and a scene
        in Python.
        """
        path = self.data_dir / name
        if not path.exists():
            raise FileNotFoundError(
                f"{path} not found. Run the model step first:\n"
                f"    python _lib/viz.py render {self.visual_dir.name}\n"
                f"which runs model.py or model.R before building the scene."
            )
        suffix = path.suffix.lower()
        if suffix in (".csv", ".tsv"):
            import pandas as pd
            sep = "\t" if suffix == ".tsv" else ","
            return pd.read_csv(path, sep=sep)
        if suffix == ".parquet":
            import pandas as pd
            return pd.read_parquet(path)
        if suffix == ".json":
            return json.loads(path.read_text(encoding="utf-8"))
        if suffix == ".npy":
            import numpy as np
            return np.load(path)
        raise ValueError(
            f"No loader for '{suffix}'. Supported: .csv .tsv .parquet .json .npy"
        )

    def has(self, name: str) -> bool:
        return (self.data_dir / name).exists()

    def list_data(self) -> list[str]:
        if not self.data_dir.exists():
            return []
        return sorted(p.name for p in self.data_dir.iterdir() if p.is_file())


# --------------------------------------------------------------------------
# Model-side helpers -- for use inside model.py
# --------------------------------------------------------------------------

def rng(seed: int):
    """The one blessed random source. Using this everywhere means every
    figure in the gallery is reproducible from its recorded seed."""
    import numpy as np
    return np.random.default_rng(seed)


def save(obj, path: Path) -> Path:
    """Write a model artifact, dispatching on extension.

    Prefer .csv for anything a human might want to open, or anything that
    might later be read from R. Use .parquet only for large arrays where
    the size actually matters, and .npy for raw numeric grids.
    """
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    suffix = path.suffix.lower()
    if suffix in (".csv", ".tsv"):
        sep = "\t" if suffix == ".tsv" else ","
        obj.to_csv(path, sep=sep, index=False)
    elif suffix == ".parquet":
        obj.to_parquet(path, index=False)
    elif suffix == ".json":
        path.write_text(json.dumps(obj, indent=2, default=str), encoding="utf-8")
    elif suffix == ".npy":
        import numpy as np
        np.save(path, obj)
    else:
        raise ValueError(f"No writer for '{suffix}'")
    return path

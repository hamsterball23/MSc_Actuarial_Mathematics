# Extending without editing `_lib`

Read this before concluding the harness is missing something. Almost every
"the harness can't do X" turns out to be "X belongs in the visual folder".

## Why the constraint exists

`_lib` is depended on by every visual in the project. A change made to fix one
figure can break others, and the breakage surfaces months later, cold, with no
memory of the change. Local code has a blast radius of one folder. Harness code
has a blast radius of the whole gallery.

The constraint is not about the harness being finished. It is about where the
cost of being wrong lands.

---

## The local-override pattern

Anything a scene needs can live next to it:

```
my-visual/
├── meta.yaml
├── model.py
├── scene.py
├── helpers.py      <-- local, imported by scene.py
└── notes.md
```

```python
# scene.py
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "_lib"))

from helpers import state_diagram          # local
from api import Scene                      # harness
```

`scene.py` may do anything to the figure before returning it. The harness
applies the theme and wires animation afterwards, and neither step prevents
custom work.

---

## Apparent gaps and their actual solutions

### "I need a plot type the harness doesn't support"

The harness never restricts plot types. `Scene.figure` is an ordinary plotly
`Figure` — surfaces, heatmaps, sankeys, polar plots, 3-D scatter, tables, all
work. There is nothing to add.

### "I need a different colour scheme for this one figure"

Set colours explicitly on the traces. `theme` provides defaults, it does not
enforce them. If a visual genuinely needs a different scale — a diverging scale
for a correlation matrix, say — pass it directly:

```python
go.Heatmap(z=corr, colorscale="RdBu", zmid=0)
```

Only reach for a new named colour in `theme.C` if it would carry the same
meaning across many future visuals. That is a real harness change, and it goes
through `study-visuals-init`.

### "I need custom layout the theme overrides"

It does not override. `theme.apply` sets `template` only; anything explicitly
set on the figure wins. Set your margins, annotations and axis ranges freely.

### "I need a second animation axis"

Plotly supports one slider natively. Two options, both local:

1. Flatten to one axis — sweep the parameter that matters and fix the other,
   or build a second visual for the second parameter. Usually the better answer,
   because two sliders are hard to read anyway.
2. Add a second slider in `scene.py` via `fig.update_layout(sliders=[...])`
   before returning. The harness appends its own slider; yours coexists. Test
   in the browser, since interaction between the two needs checking.

### "I need the model output in a format `ctx.load` doesn't handle"

Load it directly in `scene.py`:

```python
import pickle
obj = pickle.loads((ctx.data_dir / "fit.pkl").read_bytes())
```

`ctx.load` is a convenience for the common cases, not a gate. Prefer CSV where
you can, for the reasons in `lib-api.md`.

### "I need an interactive control that recomputes, not just replays frames"

This is the genuine limit. Plotly frames replay precomputed states; they do not
re-run a simulation.

Precompute the parameter grid first. Sixty frames over $\rho \in [-0.9, 0.9]$
covers essentially every study need and costs nothing at view time.

If live recomputation is truly the pedagogical point, that is a different tool
— marimo's WASM export or Shinylive — and it belongs as a standalone file in
the course folder, not in the gallery. Say so plainly rather than contorting
the harness.

### "The animation is too large"

Not a harness gap. Use `Frame(targets=[...])` so frames carry only what moves,
reduce frame count, or decimate points within frames. See `lib-api.md`.

### "I want a different page layout for this visual"

`out/index.html` is generated from a shared template, which is what keeps fifty
visuals consistent. For a genuinely different presentation, write a separate
HTML file in the visual folder and link it from `notes.md`. The gallery card
still points at the standard page.

### "I need a helper I'll use in many visuals"

Write it locally first and use it in two or three visuals. If it is still the
right abstraction after three real uses, it has earned a place in `_lib` — and
by then you know its actual shape rather than a guessed one.

Copying a helper between three visual folders is cheap. Committing a wrong
abstraction to shared infrastructure is not.

---

## If a harness change really is necessary

It happens. When it does:

1. Say so explicitly in the response — what was needed, why local code could
   not do it.
2. Make the change **additively**. Adding a field to `Frame` is safe. Renaming
   or repurposing one breaks every visual using it.
3. Re-render everything: `python _lib/viz.py build`. Any failure means the
   change was not additive.
4. Bump `_lib/VERSION` and run `python _lib/viz.py seal`.

Silent `_lib` edits are the failure this whole structure exists to prevent. An
acknowledged, sealed, re-tested change is fine. An unmentioned one is not.

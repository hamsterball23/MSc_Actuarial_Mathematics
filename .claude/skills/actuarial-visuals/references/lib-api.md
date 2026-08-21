# `_lib` API reference

Everything a visual may rely on. If something is not here, it is not part of
the contract — see `extending.md` before assuming the harness is missing it.

## Contents

- [Folder contract](#folder-contract)
- [`Context` — what a scene receives](#context)
- [`Scene` — what a scene returns](#scene)
- [`Frame` — animation steps](#frame)
- [`theme` — palette and annotation](#theme)
- [Model-side helpers](#model-side-helpers)
- [The R model contract](#the-r-model-contract)
- [CLI](#cli)
- [Failure modes](#failure-modes)

---

## Folder contract

```
<visual-id>/
├── meta.yaml     identity, courses, topics, seed, params, formats
├── model.py      computation  (or model.R)
├── scene.py      drawing — must define build(ctx) -> Scene
├── notes.md      the maths and what to notice
├── data/         model artifacts; harness writes .meta.json and .meta.csv here
└── out/          generated: index.html, thumb.png, clip.mp4
```

The harness runs `model` only when `model.py` / `model.R`, the `seed`, or the
`params` block have changed. Force it with `--force`.

`scene.py` and `model.py` both need this preamble to import from `_lib`:

```python
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "_lib"))
```

---

## Context

Passed to `build(ctx)`. Never construct it.

| Member | Type | Notes |
|---|---|---|
| `ctx.load(name)` | DataFrame / obj / array | reads from `data/`; dispatches on extension |
| `ctx.has(name)` | bool | does the artifact exist |
| `ctx.list_data()` | list[str] | filenames in `data/` |
| `ctx.seed` | int | the recorded seed — use this, never a literal |
| `ctx.params` | dict | the `params` block from `meta.yaml` |
| `ctx.param(k, default)` | any | single parameter with fallback |
| `ctx.meta` | dict | full parsed `meta.yaml` |
| `ctx.id`, `ctx.title` | str | identity |
| `ctx.visual_dir`, `ctx.data_dir`, `ctx.out_dir` | Path | rarely needed |

`load` handles `.csv`, `.tsv`, `.parquet`, `.json`, `.npy`. A missing file
raises with the command that would produce it.

---

## Scene

```python
Scene(figure, frames=(), axis_label="", caption="")
```

| Field | Meaning |
|---|---|
| `figure` | a plotly `go.Figure`. Theme applied automatically afterwards. |
| `frames` | list of `Frame`. Empty means a static figure. |
| `axis_label` | what the slider sweeps — `"t ="`, `"rho ="`. Shown on the slider and in the video overlay. |
| `caption` | one or two sentences under the figure. Say what to notice, not what it is. |

The base figure should show the state you want visible before anyone presses
play — usually the final frame, so a still screenshot is informative.

---

## Frame

```python
Frame(name, data, targets=None, layout={})
```

| Field | Meaning |
|---|---|
| `name` | slider tick label. Short and quantitative: `"t=0.50"`, `"rho=-0.7"`. |
| `data` | plotly traces replacing base-figure traces for this step. |
| `targets` | which base trace **indices** those replacements apply to. |
| `layout` | optional layout updates for this step. |

### Why `targets` matters

Payload is frames × traces × points. With `targets=None` every frame must
carry every trace, so sixty frames over a figure with a hundred background
traces re-sends the background sixty times. That is how a 4 MB figure becomes
a 50 MB one that takes ten seconds to open.

The pattern that works:

```python
targets = []

# static context — drawn once, never re-sent
for c in background_cols:
    fig.add_trace(go.Scatter(x=t, y=df[c], line=dict(color="rgba(13,148,136,0.16)"),
                             hoverinfo="skip", showlegend=False))

# animated traces — remember their indices as you add them
for i, c in enumerate(highlight_cols):
    targets.append(len(fig.data))
    fig.add_trace(go.Scatter(x=t, y=df[c], line=dict(color=C.paths[i])))

frames = [
    Frame(name=f"{t[k]:.2f}",
          data=[go.Scatter(x=t[:k+1], y=df[c].to_numpy()[:k+1],
                           line=dict(color=C.paths[i]))
                for i, c in enumerate(highlight_cols)],
          targets=targets)
    for k in step_indices
]
```

The harness rounds frame floats (default 5 dp, set `precision:` in
`meta.yaml`) and warns past ~2,000,000 points. Treat the warning as a bug.

Keep `data` and `targets` the same length and in the same order in every frame.

---

## theme

```python
from theme import C, annotate
```

Semantic palette — use the names, not hex values, so a colour means the same
thing across the whole gallery.

| Name | Role |
|---|---|
| `C.drift` | deterministic part, mean, trend |
| `C.diffusion` | the noise / Brownian part |
| `C.jump` | jumps, shocks, discontinuities |
| `C.theoretical` | closed form, limit, target |
| `C.empirical` | simulated or observed |
| `C.tail` | exceedances, the bad region |
| `C.threshold` | VaR level, barrier, retention |
| `C.body` | the uninteresting bulk |
| `C.paths[i]` | ramp for multiple comparable series |
| `C.surface`, `C.diverging` | colourscale names |
| `C.grid`, `C.axis`, `C.ink`, `C.muted` | chrome |

```python
annotate(fig, f"{n} paths  n={steps} steps  seed={ctx.seed}")
```

Small monospace corner note. Always worth adding — six months later you will
want to know what `n` was.

Do **not** set fonts, margins, background or `template`. The harness does it.

---

## Model-side helpers

```python
from api import rng, save
```

- `rng(seed)` → `numpy.random.Generator`. The one blessed random source; use
  `ctx.seed` / the meta seed so figures regenerate exactly.
- `save(obj, path)` → writes by extension: `.csv`, `.tsv`, `.parquet`, `.json`,
  `.npy`.

Prefer CSV. Readable, diffable, portable, loadable from R. Use `.parquet` only
when size genuinely matters.

---

## The R model contract

The harness writes `data/.meta.csv` — flat `key,value` rows, with nested
parameters as `params.<name>` — so `model.R` needs **no packages at all**.

```r
meta <- read.csv("data/.meta.csv", stringsAsFactors = FALSE)
getp <- function(key, default) {
  hit <- meta$value[meta$key == key]
  if (length(hit) == 0 || is.na(hit[1]) || hit[1] == "") default else hit[1]
}

set.seed(as.integer(getp("seed", 0)))
n <- as.integer(getp("params.n_origin", 10))

write.csv(df, "data/triangle.csv", row.names = FALSE)
```

Keep it dependency-free. A model that needs nothing still runs in three years.
`scene.py` then reads those CSVs through `ctx.load` exactly as if Python had
produced them — that boundary is the whole cross-language story.

---

## CLI

```bash
python _lib/viz.py new <name> --course <Course> [--lang r] [--title "..."]
python _lib/viz.py render <id> [--formats html,png,mp4] [--force] [--traceback]
python _lib/viz.py render --all
python _lib/viz.py site          # rebuild gallery only
python _lib/viz.py build         # render everything, then gallery
python _lib/viz.py doctor        # environment + _lib integrity
python _lib/viz.py seal          # re-record hashes after a sanctioned upgrade
python _lib/viz.py vendor        # localise js/css for offline use
```

---

## Failure modes

| Symptom | Cause | Fix |
|---|---|---|
| `skip out/thumb.png -- needs a headless browser` | kaleido has no Chrome | `plotly_get_chrome`. Not a failure; HTML is unaffected. |
| `skip out/clip.mp4` | no browser or no ffmpeg | install both, or drop `mp4` from `formats` |
| `warn animation carries ~N points` | frames re-sending static traces | use `Frame(targets=[...])` |
| `FileNotFoundError` from `ctx.load` | model did not run or wrote a different name | check `model.py` output names; `--force` |
| `build(ctx) must define...` | `scene.py` has no `build` | define `build(ctx) -> Scene` |
| `_lib integrity  N change(s)` | someone edited the harness | investigate before re-sealing |
| model changes ignored | stamp unchanged | `--force` |

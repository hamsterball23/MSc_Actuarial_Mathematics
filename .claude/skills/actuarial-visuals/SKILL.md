---
name: study-visuals-author
description: Create, edit and re-render individual study visuals inside an existing Visuals/ project — interactive figures for maths, probability, statistics and quantitative finance, rendered to HTML, PNG and MP4 with a shared harness. Use this skill whenever the user asks to visualise, plot, animate, illustrate or "show me" a mathematical or statistical object — Brownian motion, Itô's formula, SDE paths, option payoffs and Greeks, volatility surfaces, Poisson and counting processes, chain ladder triangles, survival curves, copulas, VaR and expected shortfall, extreme value fits, term structures, Markov models, convergence results — or wants to add, update, fix or re-render a visual in their Visuals folder, or rebuild the gallery. Use it even when they do not mention the project by name, as long as a Visuals/_lib exists. Do NOT use this skill to set up the project or install the harness — that is study-visuals-init.
---

# Study visuals: authoring

A visual here is not a plot. It is a small, self-contained study artifact: a
figure, the maths behind it, the parameters that produced it, and a note about
what is worth noticing. It has to still make sense in eighteen months, opened
cold, the night before an exam.

## The one rule

**`_lib/` is read-only.** Every visual in the project depends on it. An edit
made to fix one figure can silently break forty others, and the breakage
surfaces months later when the person has no memory of the change.

This is not a rule about obedience — it is about blast radius. Before
considering any change to `_lib`, read `references/extending.md`. It lists the
handful of things that look like harness gaps and shows the local solution for
each. In practice the escape hatch below covers essentially everything.

**Escape hatch.** If a visual genuinely needs behaviour the harness lacks,
write it *in that visual's own folder* — a helper module next to `scene.py`, a
post-processing step inside `build`. Then tell the user plainly: "this needed
X, which `_lib` doesn't provide; I've kept it local. If it comes up again, it's
a candidate for a harness upgrade via `study-visuals-init`." Local code is
cheap and reversible. Harness changes are neither.

If you do end up changing `_lib` because there was truly no alternative, say so
explicitly, explain why, and run `python _lib/viz.py seal` afterwards so the
drift is recorded rather than silent.

## Before writing anything

Read `references/lib-api.md`. It is the full surface you can rely on:
`Scene`, `Frame`, `Context`, the theme palette, and the model/scene contract.
Do not guess at the API from the scaffold alone.

Then read `references/patterns.md` for the recurring visual families in this
domain — path simulation, distributional diagnostics, payoff structures,
actuarial processes, risk measures — and the plotting approach each one wants.

## Workflow

### 1. Understand what the picture should argue

Ask, if it is not obvious: what claim should this figure make? "Plot Brownian
motion" is underspecified; "show that quadratic variation converges pathwise
while the paths themselves fan out" is a visual. The second version determines
the panels, the annotations and the animation axis.

One good question is enough. Do not interview them.

### 2. Scaffold

```bash
cd <ProjectRoot>/Visuals
python _lib/viz.py new "<descriptive name>" --course <Course> [--lang r]
```

The id is slugified from the name. Choose something searchable and specific:
`heston-vol-surface-rho-sweep`, not `plot3`.

Use `--lang r` when the maths is naturally R-flavoured — anything the StatIns
course does in R, survival analysis, GLM fits. The R model is package-free by
design: the harness writes `data/.meta.csv` as flat key/value rows so base R
reads parameters without `jsonlite`. Keep it that way.

### 3. Fill in `meta.yaml`

This is not bookkeeping, it is what makes the gallery navigable and the figure
reproducible.

- `summary` — one line, stating what the picture shows. It appears on the card.
- `courses` — every course it is relevant to, not just the one that prompted it.
- `topics` — the terms future-you will search for. Be generous: these are the
  gallery filters.
- `source` — lecture, chapter, exercise number. Six months later this is the
  difference between a figure you trust and one you re-derive.
- `seed` — never hard-code a seed in `model.py`; read `ctx.seed`.
- `params` — every model constant. They are displayed next to the figure, which
  keeps them honest.
- `formats` — `[html, png]` normally; add `mp4` only when there are frames.

### 4. Write `model.py` (or `model.R`)

Computation only. No plotting, no colours, no output paths. It reads parameters
from the meta file the harness writes into `data/`, and saves tidy artifacts
into `data/`.

Prefer CSV. It is readable, portable, diffable, and readable from R. Reach for
`.parquet` only when the file would otherwise be tens of megabytes, and `.npy`
only for raw numeric grids.

Comment the *mathematics*, not the Python. A line explaining that squared
increments have variance $2(\Delta t)^2$ is worth ten explaining that `cumsum`
accumulates.

### 5. Write `scene.py`

Drawing only. No simulation. Return a `Scene`.

The house theme is applied automatically, so do not set fonts, margins or
background. Do use the semantic palette from `theme.C` — `drift`, `diffusion`,
`jump`, `theoretical`, `empirical`, `tail`, `threshold`. A colour meaning the
same thing across fifty figures is the single highest-value convention in the
project.

**Animation payload is the failure mode to watch.** Cost is
frames × traces × points. Draw unchanging context once in the base figure and
animate only what moves, naming those trace indices in `Frame(targets=[...])`.
Getting this wrong is not subtle: a figure that should be 4 MB becomes 50 MB
and takes ten seconds to open. The harness warns past ~2M points, but design
for it rather than waiting for the warning.

Finish with `annotate(fig, ...)` carrying sample size, step count and seed.

### 6. Write `notes.md`

This is what separates a study tool from a plot dump, and it is the part most
worth spending effort on. Structure that works:

- **What this shows** — the setup in a sentence or two.
- **The maths** — the definition or theorem, in LaTeX. `$inline$` and `$$display$$`
  both render via KaTeX.
- **What to notice** — the observations worth being reminded of. This is the
  section future-you actually reads.
- **Why it matters downstream** — where this result gets used later. Connecting
  quadratic variation to the Itô correction term is more valuable than either
  fact alone.
- **Assumptions and limits** — where the picture misleads, what it quietly
  assumes, what kind of convergence is actually shown.

Write for someone who understands the course but has forgotten this specific
result. Not a textbook, not a reminder note — the level in between.

### 7. Render and check

```bash
python _lib/viz.py render <visual-id>
python _lib/viz.py build          # re-render everything, rebuild gallery
```

Read the output. `skip` lines about PNG or MP4 are normal on machines without a
headless browser and are not failures — say so rather than alarming the user.
A `warn` about animation payload is a real problem: fix the frames.

Report the output path so they can open it.

## Editing an existing visual

Change the narrowest thing that achieves the goal.

- Different parameters → edit `meta.yaml` only. The harness detects the change
  and re-runs the model automatically.
- Different picture, same data → edit `scene.py` only.
- Different computation → edit `model.py`, then re-render with `--force`.

Preserve the seed unless the user wants a different realisation. Changing it
silently means the figure they studied from no longer exists.

## Judgement calls

**When a request spans several ideas**, prefer several focused visuals over one
crowded figure. `ito-formula-correction-term` and `gbm-vs-arithmetic-drift` are
each findable in the gallery; a combined `stochastic-calculus-overview` is
neither.

**When the maths is genuinely static**, do not animate. A QQ-plot against a
fitted GPD tail is a still image. Animation earns its place when a parameter
sweep reveals something — how the Heston smile flattens as ρ → 0, how the chain
ladder reserve responds to a single outlying development factor.

**When you are unsure the maths is right**, say so in the response rather than
burying a hedge in `notes.md`. A confidently wrong figure is worse than no
figure, because it gets memorised.

## Reference files

- `references/lib-api.md` — the complete `_lib` surface. Read before writing code.
- `references/patterns.md` — visual families for this domain and how to build each.
- `references/extending.md` — things that look like harness gaps, and their local solutions. Read before ever considering an `_lib` edit.
- `references/example-brownian-motion/` — a fully worked visual. Read `scene.py`
  when you need to see the `Frame(targets=...)` pattern in real code, and
  `notes.md` for the depth and structure the notes should reach.

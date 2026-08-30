# MSc Actuarial Mathematics (2026–2028)

Coursework, exercises, and study visuals for the Master's programme in Actuarial
Mathematics. This does not include handwritten exercise solutions, lecture notes, or
Anki cards — those live elsewhere.

## Structure

```
11 MathFin/      Mathematical Finance — lecture notes, problem sheets, exercises
11 StatIns/      Statistics for Insurance — lecture notes, problem sheets, exercises
Visuals/         Interactive figures built with the study-visuals harness (see below)
```

Course folders are numbered by course code and contain the official lecture notes/PDFs
plus an `Exercises/` subfolder with problem sheets and per-week solution code (R
scripts, plots).

## Visuals

`Visuals/` is a self-contained project for building interactive study figures —
Brownian motion paths, convergence modes, isometries, and similar — rendered to HTML,
PNG, and MP4 from a shared Python harness (`Visuals/_lib`).

Each visual lives in its own folder (`Visuals/<id>/`) with a `meta.yaml` (title,
course, topics, params), `model.py` (the math/simulation), `scene.py` (the plot), and
`notes.md`. A browsable gallery (`Visuals/_site/index.html`) indexes them all, filterable
by course and topic.

To view: open `Visuals/_site/index.html` in a browser. To rebuild it or add a new
figure, use the `actuarial-visuals` skill (or the harness directly via
`Visuals/_lib/viz.py`) rather than editing the generated output by hand.

## Environments

- **R**: managed with [renv](https://rstudio.github.io/renv/) (`renv.lock`). Run
  `renv::restore()` from R in the project root to install the pinned package
  versions used by the exercise scripts.
- **Python**: the `Visuals/` project has its own virtual environment
  (`Visuals/.venv`, gitignored) with dependencies in `Visuals/_lib/requirements.txt`.

## Workflow

Changes land via pull request rather than direct commits to `main` — see
[CLAUDE.md](CLAUDE.md) for the branching/PR convention used throughout this repo.

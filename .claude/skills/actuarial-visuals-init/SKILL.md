---
name: study-visuals-init
description: One-time setup of a study-visuals project — creates the Visuals/ folder, installs the shared _lib render harness, seals it, and builds the gallery. Use this skill whenever the user wants to set up, bootstrap, scaffold, or initialise a visuals project for their studies, mentions creating a MSc_Actuarial_Mathematics or similar course-folder structure with a Visuals folder, asks to install or reinstall the visual harness or _lib, wants a gallery/website for their study figures, or needs to upgrade or repair an existing _lib. Also use it if the user asks to add the visuals system to an existing course folder. Do NOT use this skill to create individual visuals — that is study-visuals-author.
---

# Study visuals: project initialisation

This skill has one job: put a working, sealed `_lib` on disk and prove it
runs. It is the *installer*. Creating actual visuals is a different skill
(`study-visuals-author`) and a different mental mode.

Keeping these separate matters. Installation is a rare, careful, whole-system
act. Authoring is frequent and local. Conflating them is how shared
infrastructure gets casually edited to make one figure work, which breaks
the other forty.

## Before doing anything

Confirm two things with the user, because both are hard to change later:

1. **Where the project root goes.** Default `MSc_Actuarial_Mathematics/`, but
   let them name it. The harness derives the gallery title from this folder
   name.
2. **Which course subfolders to create.** For KU Actuarial Mathematics the
   natural set is `MathFin`, `StatIns`, `QRM`, `Liv2`, plus whichever
   restricted electives they take (`TermStructure`, `EVT`, `LargeDeviations`).
   These hold lectures, notes, PDFs and exercise code — the harness never
   touches them.

If a `Visuals/_lib` already exists, **stop and ask** whether this is a fresh
install, an upgrade, or a repair. Never silently overwrite: their `_lib` may
carry sanctioned local changes, and blowing those away without asking is the
worst thing this skill can do.

## Layout to create

```
<ProjectRoot>/
├── MathFin/            course material, untouched by the harness
├── StatIns/
├── QRM/
├── ...
└── Visuals/
    ├── _lib/           the harness — shared, sealed, read-only in practice
    ├── _site/          generated gallery; open _site/index.html
    └── <visual-id>/    one folder per visual (created by the author skill)
```

Visual folders sit **flat** under `Visuals/`, not nested by course. Poisson
processes appear in both StatIns and QRM; extreme value theory in both QRM and
EVT. A visual belongs to several courses at once, which `meta.yaml` handles
via `courses: [...]`. Nesting would force duplication.

## Steps

1. **Create the tree.** Project root, course subfolders, `Visuals/`.

2. **Install `_lib`.** Copy every file from this skill's `assets/lib/` into
   `<ProjectRoot>/Visuals/_lib/`, preserving the `templates/` and `vendor/`
   subfolders. Copy verbatim — do not "improve" anything on the way in. The
   harness has been tested as a unit.

3. **Check the environment.**

   ```bash
   cd <ProjectRoot>/Visuals && python _lib/viz.py doctor
   ```

   Read the output back to the user in plain terms. Only the four `required`
   rows matter for the system to work: numpy, pandas, plotly, pyyaml. If any
   are missing:

   ```bash
   pip install numpy pandas plotly pyyaml
   ```

   Everything else is genuinely optional and the harness degrades cleanly:

   | Warning | What is lost | Fix |
   |---|---|---|
   | `png export` | thumbnails, static figures | `pip install kaleido` then `plotly_get_chrome` |
   | `mp4 export` | video clips | the above, plus `ffmpeg` on PATH |
   | `pyarrow` | `.parquet` data files (CSV works fine) | `pip install pyarrow` |
   | `R models` | writing models in R | install R, only if they want it |
   | `offline assets` | works offline | `python _lib/viz.py vendor` |

   Do not present these as problems. Interactive HTML — the format that
   carries almost all the study value — needs none of them.

4. **Vendor the front-end assets** if the machine has internet:

   ```bash
   python _lib/viz.py vendor
   ```

   This downloads plotly.js, KaTeX and marked into `_lib/vendor/` so pages
   render with no network and no dependence on a CDN that may not exist in
   three years. Worth doing at install time; easy to forget later.

5. **Prove it works.** Scaffold and render a throwaway visual, confirm the
   HTML appears, then delete it:

   ```bash
   python _lib/viz.py new "install check" --course MathFin
   python _lib/viz.py render install-check
   ```

   A working render writes `install-check/out/index.html`. Delete the folder
   afterwards so the gallery starts clean.

6. **Install the seed visual.** Copy `assets/example/brownian-motion-paths/`
   into `<ProjectRoot>/Visuals/` and render it:

   ```bash
   python _lib/viz.py render brownian-motion-paths
   ```

   This is a fully worked visual — Brownian sample paths against the
   $\pm\sqrt{t}$ envelope, paired with running quadratic variation converging
   pathwise to $t$. It exists for two reasons: the gallery is not empty on day
   one, and it is the reference every later visual is patterned on. Ask before
   skipping it; a user who already has visuals may not want it.

7. **Seal `_lib`.**

   ```bash
   python _lib/viz.py seal
   ```

   This records a hash of every harness file. From now on `doctor` reports any
   drift. Seal *after* vendoring, so the vendored assets are accounted for.

8. **Build the gallery.**

   ```bash
   python _lib/viz.py build
   ```

   Give the user the absolute path to `Visuals/_site/index.html`. It opens by
   double-clicking — no server needed, because the manifest is inlined rather
   than fetched. That also means it works unchanged if they later push
   `Visuals/` to GitHub Pages.

9. **Write `Visuals/README.md`** — a short orientation note covering the four
   commands they will actually use (`new`, `render`, `build`, `doctor`), the
   three-layer split (model / scene / render), and the rule that `_lib` is not
   edited by hand. Keep it under a page; a README nobody reads is worse than
   none.

## Upgrading an existing install

When the user asks for new harness capability that genuinely cannot live in a
visual folder, this skill is where the upgrade happens — deliberately, with
the whole system in view.

1. Run `doctor` first and report any existing drift. Unexplained drift means
   someone edited `_lib` in passing; find out what and why before layering
   changes on top.
2. Make the change **additively**. Visuals across the project depend on the
   current `api.py` contract. Adding a field to `Frame` is safe; renaming one
   silently breaks every visual that used it.
3. Bump `_lib/VERSION`.
4. Re-render everything: `python _lib/viz.py build`. If any visual fails, the
   change was not additive.
5. Re-seal: `python _lib/viz.py seal`.

Tell the user what changed and why it needed to be in `_lib` rather than in a
single visual. That justification is the check on this path being overused.

## What this skill does not do

- It does not create real visuals. Hand off to `study-visuals-author`.
- It does not write course notes or organise PDFs into the course folders.
- It does not edit `_lib` to accommodate one figure. If a visual seems to need
  that, the author skill's local-override route almost always solves it, and
  a genuine harness gap should be raised explicitly rather than patched in.

## Closing

End by telling the user the one command that matters day to day:

```bash
cd <ProjectRoot>/Visuals && python _lib/viz.py new "<name>" --course <Course>
```

and that `python _lib/viz.py build` refreshes everything.

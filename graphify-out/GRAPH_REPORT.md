# Graph Report - MSc_Actuarial_Mathematics  (2026-09-02)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 277 nodes · 433 edges · 18 communities
- Extraction: 85% EXTRACTED · 15% INFERRED · 0% AMBIGUOUS · INFERRED: 64 edges (avg confidence: 0.89)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `33ec454f`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- build
- lib/render.py
- _lib/render.py
- Context
- Context
- _lib/theme.py
- lib/doctor.py
- lib/viz.py
- _lib/doctor.py
- _lib/viz.py
- lib/gallery.py
- _lib/gallery.py
- lib/templates/gallery.js
- _lib/templates/gallery.js
- lib/scaffold.py
- _lib/scaffold.py
- _lib/templates/page.js

## God Nodes (most connected - your core abstractions)
1. `Scene` - 19 edges
2. `Context` - 14 edges
3. `Context` - 13 edges
4. `render_visual()` - 11 edges
5. `render_visual()` - 11 edges
6. `build()` - 9 edges
7. `write_html()` - 9 edges
8. `write_html()` - 9 edges
9. `main()` - 8 edges
10. `main()` - 8 edges

## Surprising Connections (you probably didn't know these)
- `build()` --uses--> `Scene`  [INFERRED]
  Visuals/brownian-motion-paths/scene.py → .claude/skills/actuarial-visuals-init/assets/lib/api.py
- `build()` --uses--> `Scene`  [INFERRED]
  Visuals/gaussian-white-noise-as-an-isometry/scene.py → .claude/skills/actuarial-visuals-init/assets/lib/api.py
- `attach_animation()` --uses--> `Scene`  [INFERRED]
  Visuals/_lib/render.py → .claude/skills/actuarial-visuals-init/assets/lib/api.py
- `build_scene()` --uses--> `Scene`  [INFERRED]
  Visuals/_lib/render.py → .claude/skills/actuarial-visuals-init/assets/lib/api.py
- `compress()` --uses--> `Scene`  [INFERRED]
  Visuals/_lib/render.py → .claude/skills/actuarial-visuals-init/assets/lib/api.py

## Import Cycles
- None detected.

## Communities (18 total, 0 thin omitted)

### Community 0 - "build"
Cohesion: 0.07
Nodes (34): build(), scene.py -- two stacked panels sharing a time axis: top W_t sample paths…, Frame, One step of an animation. ``name`` is what appears on the slider tick, so keep…, annotate(), apply(), _build_template(), C (+26 more)

### Community 1 - "lib/render.py"
Cohesion: 0.11
Nodes (32): The complete description of one visual. ``figure`` is a plotly ``go.Figure``.…, Scene, attach_animation(), build_scene(), compress(), _esc(), _human(), _image_hint() (+24 more)

### Community 2 - "_lib/render.py"
Cohesion: 0.12
Nodes (30): attach_animation(), build_scene(), compress(), _esc(), _human(), _image_hint(), load_meta(), _model_stamp() (+22 more)

### Community 3 - "Context"
Cohesion: 0.07
Nodes (19): main(), model.py -- simulate standard Brownian motion and its running quadratic…, main(), mu(), model.py -- deterministic geometry behind Gaussian white noise with intensity…, mu([a, b]) = integral_a^b (lam0 + lam1 x) dx, for a <= b., Context, Path (+11 more)

### Community 4 - "Context"
Cohesion: 0.08
Nodes (15): main(), model.py -- simulate standard Brownian motion and its running quadratic…, Context, Path, api.py -- the contract between a visual and the render harness. A visual never…, The recorded seed. Always use this rather than a literal, so the figure you…, Free-form parameter block from meta.yaml. Use it for model constants (sigma,…, Load an artifact from ``data/`` by filename. Dispatches on extension: .csv and… (+7 more)

### Community 5 - "_lib/theme.py"
Cohesion: 0.18
Nodes (12): annotate(), apply(), _build_template(), C, install(), Figure, Template, theme.py -- one visual language for the whole gallery. The point of a shared… (+4 more)

### Community 6 - "lib/doctor.py"
Cohesion: 0.32
Nodes (11): check(), _check_import(), _hash(), _iter_lib_files(), Path, doctor.py -- is the environment healthy, and has _lib drifted? Two jobs. 1.…, Record current hashes. Run once at install, and again -- deliberately -- after…, _rversion() (+3 more)

### Community 7 - "lib/viz.py"
Cohesion: 0.32
Nodes (11): cmd_build(), cmd_doctor(), cmd_new(), cmd_render(), cmd_seal(), cmd_site(), cmd_vendor(), main() (+3 more)

### Community 8 - "_lib/doctor.py"
Cohesion: 0.32
Nodes (11): check(), _check_import(), _hash(), _iter_lib_files(), Path, doctor.py -- is the environment healthy, and has _lib drifted? Two jobs. 1.…, Record current hashes. Run once at install, and again -- deliberately -- after…, _rversion() (+3 more)

### Community 9 - "_lib/viz.py"
Cohesion: 0.32
Nodes (11): cmd_build(), cmd_doctor(), cmd_new(), cmd_render(), cmd_seal(), cmd_site(), cmd_vendor(), main() (+3 more)

### Community 10 - "lib/gallery.py"
Cohesion: 0.43
Nodes (7): build(), discover(), _entry(), _esc(), Path, gallery.py -- build the gallery index from whatever visuals exist on disk. The…, Every directory holding a meta.yaml, excluding underscore folders.

### Community 11 - "_lib/gallery.py"
Cohesion: 0.43
Nodes (7): build(), discover(), _entry(), _esc(), Path, gallery.py -- build the gallery index from whatever visuals exist on disk. The…, Every directory holding a meta.yaml, excluding underscore folders.

### Community 12 - "lib/templates/gallery.js"
Cohesion: 0.57
Nodes (6): buildFilters(), card(), esc(), matches(), render(), uniq()

### Community 13 - "_lib/templates/gallery.js"
Cohesion: 0.57
Nodes (6): buildFilters(), card(), esc(), matches(), render(), uniq()

### Community 14 - "lib/scaffold.py"
Cohesion: 0.50
Nodes (4): create(), Path, scaffold.py -- create a new visual folder with the contract already wired up.…, slugify()

### Community 15 - "_lib/scaffold.py"
Cohesion: 0.50
Nodes (4): create(), Path, scaffold.py -- create a new visual folder with the contract already wired up.…, slugify()

### Community 16 - "_lib/templates/page.js"
Cohesion: 0.50
Nodes (3): mathToken(), stashMath(), take()

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Scene` connect `lib/render.py` to `build`, `_lib/render.py`, `Context`?**
  _High betweenness centrality (0.188) - this node is a cross-community bridge._
- **Why does `Context` connect `Context` to `_lib/render.py`?**
  _High betweenness centrality (0.081) - this node is a cross-community bridge._
- **Why does `build()` connect `build` to `lib/render.py`, `_lib/theme.py`?**
  _High betweenness centrality (0.079) - this node is a cross-community bridge._
- **Are the 15 inferred relationships involving `Scene` (e.g. with `build()` and `attach_animation()`) actually correct?**
  _`Scene` has 15 INFERRED edges - model-reasoned connections that need verification._
- **Should `build` be split into smaller, more focused modules?**
  _Cohesion score 0.06707317073170732 - nodes in this community are weakly interconnected._
- **Should `lib/render.py` be split into smaller, more focused modules?**
  _Cohesion score 0.10952380952380952 - nodes in this community are weakly interconnected._
- **Should `_lib/render.py` be split into smaller, more focused modules?**
  _Cohesion score 0.11553030303030302 - nodes in this community are weakly interconnected._
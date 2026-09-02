# Working agreement — git workflow

This project is on GitHub at `hamsterball23/MSc_Actuarial_Mathematics`. Kasper reviews
changes via pull requests before they land, so:

- **Never push directly to `main`**, and never push anything to the remote without being
  explicitly asked to — this includes pushing a branch to open a PR.
- **After finishing a change or addition** (a new visual, a skill update, a fix, docs,
  anything), open a pull request for it rather than committing straight to `main`:
  1. Create a new branch off `main` (short, descriptive name).
  2. Commit the change there.
  3. Push the branch and open a PR against `main` (`gh pr create`, or hand Kasper the
     compare URL if `gh` isn't authenticated yet).
  4. Leave it for Kasper to review/merge — do not merge it yourself unless asked.
- Small, separate changes should get separate PRs rather than being bundled, unless
  Kasper asks for them together.
- This applies to everything in the repo, including `Visuals/` content and the
  `.claude/skills/` themselves.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).

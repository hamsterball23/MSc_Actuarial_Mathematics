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

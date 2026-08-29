"""
model.py -- three independent constructions, one per mode of convergence.

1. Almost sure convergence (SLLN).
   X_n = (1/n) sum_{i=1}^n U_i,  U_i iid Uniform(0,1).
   By the strong law, X_n(omega) -> 1/2 for almost every omega -- every
   *individual* sample path settles down, not just the distribution of X_n.

2. Convergence in probability but NOT almost surely (the "typewriter"
   / moving-block sequence). Fix omega = U ~ Uniform(0,1) once. Enumerate
   n = 1, 2, 3, ... by sweeping blocks k = 0, 1, 2, ...; within block k there
   are 2^k sub-intervals I_{k,j} = [j/2^k, (j+1)/2^k), j = 0, ..., 2^k - 1.
   Y_n = 1{U in I_n}. Then P(Y_n = 1) = 2^{-k(n)} -> 0, so Y_n -> 0 in
   probability. But every omega lies in exactly one interval of each block,
   so Y_n(omega) = 1 infinitely often for every omega: Y_n does not converge
   almost surely (it doesn't converge pointwise at all).

3. Convergence in distribution (CLT). S_n = sum_{i=1}^n U_i, U_i iid
   Uniform(0,1), Var(U_i) = 1/12. The standardised sum
   Z_n = (S_n - n/2) / sqrt(n/12) converges in distribution to N(0,1) --
   the *law* of Z_n stabilises even though no single realisation of Z_n
   converges to anything (Z_n does not even live on a fixed probability
   space in a way that makes pointwise convergence meaningful here).
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
P = META.get("params", {})
SEED = int(META.get("seed", 0))


def main():
    r = rng(SEED)

    # ---- 1. almost sure convergence: SLLN running average ---------------
    n_hi = int(P.get("n_paths", 6))
    n_faint = int(P.get("n_faint_paths", 60))
    n_steps = int(P.get("n_steps_as", 500))

    u = r.random(size=(n_steps, n_hi + n_faint))
    running_mean = np.cumsum(u, axis=0) / np.arange(1, n_steps + 1)[:, None]

    as_df = pd.DataFrame(running_mean,
                          columns=[f"hi_{i}" for i in range(n_hi)]
                          + [f"faint_{i}" for i in range(n_faint)])
    as_df.insert(0, "n", np.arange(1, n_steps + 1))
    save(as_df, DATA / "almost_sure.csv")

    # ---- 2. in probability but not a.s.: typewriter sequence ------------
    K = int(P.get("n_blocks_k", 8))
    U = float(P.get("u_point", 0.37))

    rows = []
    n = 0
    for k in range(K):
        for j in range(2 ** k):
            n += 1
            lo, hi = j / 2 ** k, (j + 1) / 2 ** k
            hit = int(lo <= U < hi)
            rows.append((n, k, j, lo, hi, hit))
    prob_df = pd.DataFrame(rows, columns=["n", "k", "j", "lo", "hi", "hit"])
    prob_df["mid"] = 0.5 * (prob_df["lo"] + prob_df["hi"])
    prob_df["half_width"] = 0.5 * (prob_df["hi"] - prob_df["lo"])
    prob_df["p_hit"] = 2.0 ** (-prob_df["k"])  # P(Y_n = 1) for this block
    save(prob_df, DATA / "in_probability.csv")

    # ---- 3. convergence in distribution: CLT for standardised sums -----
    n_values = P.get("n_values", [2, 4, 8, 16, 32, 64, 128, 256, 512, 1024])
    reps = int(P.get("n_replications", 20000))
    n_bins = int(P.get("n_bins", 50))
    edges = np.linspace(-4.0, 4.0, n_bins + 1)
    centers = 0.5 * (edges[:-1] + edges[1:])
    width = edges[1] - edges[0]

    dist_rows = []
    for n_i in n_values:
        u = r.random(size=(reps, int(n_i)))
        s = u.sum(axis=1)
        z = (s - n_i / 2) / np.sqrt(n_i / 12)
        counts, _ = np.histogram(z, bins=edges)
        density = counts / (reps * width)
        for c, d in zip(centers, density):
            dist_rows.append((int(n_i), c, d))
    dist_df = pd.DataFrame(dist_rows, columns=["n", "z", "density"])
    save(dist_df, DATA / "in_distribution.csv")


if __name__ == "__main__":
    main()

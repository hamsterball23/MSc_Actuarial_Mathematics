"""
model.py -- simulate a P-Brownian motion B, form the drifted process
X_t = B_t + c*t, and the exponential (density) martingale

    D_t = E(-c B)_t = exp(-c B_t - (c^2/2) t) ,

which is the Radon-Nikodym derivative dQ/dP restricted to F_t for the
measure Q = D_infinity . P. Girsanov's theorem says that under Q,
beta_t = B_t + c*t = X_t is a (driftless) Q-Brownian motion.

So D_T is the per-path importance weight that turns the P-ensemble of
X-paths (which visibly drifts) into a Q-ensemble (which should not).
Nothing here knows about colours or plotting -- just the simulation and
the weighted/unweighted empirical means that the picture will compare.
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

    n_paths = int(P.get("n_paths", 400))
    n_steps = int(P.get("n_steps", 300))
    T = float(P.get("T", 1.0))
    c = float(P.get("c", 0.75))

    dt = T / n_steps
    t = np.linspace(0.0, T, n_steps + 1)

    # P-Brownian motion: independent N(0, dt) increments, exact at grid points.
    increments = r.normal(loc=0.0, scale=np.sqrt(dt), size=(n_paths, n_steps))
    B = np.zeros((n_paths, n_steps + 1))
    B[:, 1:] = np.cumsum(increments, axis=1)

    # The drifted process under P: X_t = B_t + c*t.
    X = B + c * t[None, :]

    # The exponential martingale D_t = exp(-c*B_t - (c^2/2)*t), the density
    # process of Q w.r.t. P on F_t. It is itself a P-martingale with D_0 = 1.
    D = np.exp(-c * B - 0.5 * c ** 2 * t[None, :])

    # Per-path importance weight (terminal density), normalised to average 1
    # so that mean_Q(t) = mean_i [ weight_i * X_i(t) ] is a direct Q-estimate.
    weight = D[:, -1]
    weight_norm = weight * n_paths / weight.sum()

    mean_P = X.mean(axis=0)
    sd_P = X.std(axis=0, ddof=1)

    mean_Q = (weight_norm[:, None] * X).mean(axis=0)
    # Weighted variance of X under the empirical Q-measure.
    var_Q = (weight_norm[:, None] * (X - mean_Q[None, :]) ** 2).mean(axis=0)
    sd_Q = np.sqrt(np.maximum(var_Q, 0.0))

    cols = [f"p{i}" for i in range(n_paths)]
    save(pd.DataFrame(X.T, columns=cols).assign(t=t), DATA / "paths_X.csv")
    save(pd.DataFrame(D.T, columns=cols).assign(t=t), DATA / "paths_D.csv")
    save(pd.DataFrame({"path": cols, "weight": weight, "weight_norm": weight_norm}),
         DATA / "weights.csv")
    save(pd.DataFrame({
        "t": t,
        "drift_line": c * t,
        "mean_P": mean_P,
        "sd_P": sd_P,
        "mean_Q": mean_Q,
        "sd_Q": sd_Q,
    }), DATA / "means.csv")


if __name__ == "__main__":
    main()

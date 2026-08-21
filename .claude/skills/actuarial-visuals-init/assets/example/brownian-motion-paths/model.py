"""
model.py -- simulate standard Brownian motion and its running quadratic
variation on a fixed partition.

Nothing here knows about colours or output formats. It produces tidy
artifacts in data/ and stops.
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

    n_paths = int(P.get("n_paths", 60))
    n_steps = int(P.get("n_steps", 500))
    T = float(P.get("T", 1.0))

    dt = T / n_steps
    t = np.linspace(0.0, T, n_steps + 1)

    # W_{t_{k+1}} - W_{t_k} ~ N(0, dt), independent across k and across paths.
    increments = r.normal(loc=0.0, scale=np.sqrt(dt), size=(n_paths, n_steps))
    paths = np.zeros((n_paths, n_steps + 1))
    paths[:, 1:] = np.cumsum(increments, axis=1)

    # Running quadratic variation on the same partition:
    #   [W]^{(n)}_t = sum_{t_k <= t} (W_{t_{k+1}} - W_{t_k})^2
    qv = np.zeros((n_paths, n_steps + 1))
    qv[:, 1:] = np.cumsum(increments ** 2, axis=1)

    cols = [f"p{i}" for i in range(n_paths)]
    save(pd.DataFrame(paths.T, columns=cols).assign(t=t), DATA / "paths.csv")
    save(pd.DataFrame(qv.T, columns=cols).assign(t=t), DATA / "qv.csv")

    # The sqrt(t) envelope the cross-section should fill.
    save(pd.DataFrame({
        "t": t,
        "mean": paths.mean(axis=0),
        "sd": paths.std(axis=0, ddof=1),
        "band": np.sqrt(t),
    }), DATA / "envelope.csv")


if __name__ == "__main__":
    main()

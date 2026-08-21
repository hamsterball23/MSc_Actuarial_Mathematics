"""
model.py -- deterministic geometry behind Gaussian white noise with
intensity mu.

Nothing here is random: mu(A) = E[W(A)^2] and mu(A n B) = E[W(A)W(B)] are
exact integrals of the intensity density, computed on a grid of set
positions. That is the whole point -- the isometry is an algebraic identity
between measures, not something that needs simulating to see.

The base space is E = [0, domain_max] with intensity measure

    mu(dx) = (lambda0 + lambda1 * x) dx,

a mildly increasing density chosen so mu(A) is visibly *not* just the
length of A -- the same picture with a flat density would collapse the
distinction between "intensity measure" and "Lebesgue measure".

Two sweeps are produced:

  left  -- A = [split_a, split_b] is cut at a moving point c into
           A1 = [split_a, c], A2 = [c, split_b]. mu(A1) + mu(A2) = mu(A)
           for every c: splitting a set never changes the variance of its
           white noise, only how that variance is distributed.

  right -- A = [overlap_a_lo, overlap_a_hi] is fixed; B is a same-width
           interval sliding across E at offset s. mu(A n B) is the
           isometry's covariance Cov(W(A), W(B)) directly.
"""

import json
import sys
from pathlib import Path

import numpy as np
import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "_lib"))
from api import save  # noqa: E402

HERE = Path(__file__).resolve().parent
DATA = HERE / "data"
META = json.loads((DATA / ".meta.json").read_text())
P = META.get("params", {})


def mu(a, b, lam0, lam1):
    """mu([a, b]) = integral_a^b (lam0 + lam1 x) dx, for a <= b."""
    a, b = np.asarray(a, dtype=float), np.asarray(b, dtype=float)
    width = np.clip(b - a, 0.0, None)
    return lam0 * width + 0.5 * lam1 * (b ** 2 - a ** 2)


def main():
    lam0 = float(P.get("lambda0", 1.0))
    lam1 = float(P.get("lambda1", 0.15))
    domain_max = float(P.get("domain_max", 16.0))

    # -- intensity density, for the background curve in both panels -------
    x = np.linspace(0.0, domain_max, 400)
    save(pd.DataFrame({"x": x, "lam": lam0 + lam1 * x}), DATA / "density.csv")

    # -- left sweep: A = A1 u A2, split point c moves ----------------------
    a, b = float(P.get("split_a", 0.0)), float(P.get("split_b", 6.0))
    c_lo, c_hi = float(P.get("split_c_lo", 1.0)), float(P.get("split_c_hi", 5.0))
    n_frames = int(P.get("n_frames", 21))
    c = np.linspace(c_lo, c_hi, n_frames)

    mu_a1 = mu(a, c, lam0, lam1)
    mu_a2 = mu(c, b, lam0, lam1)
    mu_a = mu(a, b, lam0, lam1)  # constant: independent of where c sits

    save(pd.DataFrame({
        "k": np.arange(n_frames), "t": np.linspace(0, 1, n_frames),
        "a": a, "b": b, "c": c,
        "mu_A1": mu_a1, "mu_A2": mu_a2, "mu_A": mu_a,
    }), DATA / "left.csv")

    # -- right sweep: A fixed, B slides, overlap = A n B --------------------
    a2 = float(P.get("overlap_a_lo", 5.0))
    b2 = float(P.get("overlap_a_hi", 11.0))
    w = float(P.get("overlap_b_width", 6.0))
    s_lo, s_hi = float(P.get("overlap_s_lo", -1.0)), float(P.get("overlap_s_hi", 11.0))
    s = np.linspace(s_lo, s_hi, n_frames)
    b_lo, b_hi = s, s + w

    ov_lo = np.maximum(a2, b_lo)
    ov_hi = np.minimum(b2, b_hi)
    has_overlap = ov_hi > ov_lo
    ov_lo_clip = np.where(has_overlap, ov_lo, 0.0)
    ov_hi_clip = np.where(has_overlap, ov_hi, 0.0)

    mu_A = mu(a2, b2, lam0, lam1) * np.ones(n_frames)
    mu_B = mu(b_lo, b_hi, lam0, lam1)
    mu_AB = np.where(has_overlap, mu(ov_lo_clip, ov_hi_clip, lam0, lam1), 0.0)
    rho = mu_AB / np.sqrt(mu_A * mu_B)

    save(pd.DataFrame({
        "k": np.arange(n_frames), "t": np.linspace(0, 1, n_frames),
        "a2": a2, "b2": b2, "s": s, "b_lo": b_lo, "b_hi": b_hi,
        "ov_lo": ov_lo_clip, "ov_hi": ov_hi_clip, "has_overlap": has_overlap.astype(int),
        "mu_A": mu_A, "mu_B": mu_B, "mu_AB": mu_AB, "rho": rho,
    }), DATA / "right.csv")


if __name__ == "__main__":
    main()

"""
scene.py -- three stacked panels sharing a time axis:
  top     X_t = B_t + c*t sample paths under P, against the drift line c*t
  middle  the density process D_t = dQ/dP|F_t for the same highlighted paths
  bottom  the weighted (Q) vs unweighted (P) empirical mean of X_t, +/- 1 sd

Animation design note: as in the Brownian-motion example, the ensemble is
static context drawn once. Only the highlighted paths/densities and the two
time cursors move, via Frame(targets=...). The bottom panel is the "proof"
panel -- it uses the whole ensemble, not just the highlighted paths, and
does not need to animate: the claim it makes (mean_Q stays flat at 0 while
mean_P tracks c*t) holds over the whole time axis at once.
"""

import sys
from pathlib import Path

import numpy as np
import plotly.graph_objects as go
from plotly.subplots import make_subplots

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "_lib"))
from api import Frame, Scene  # noqa: E402
from theme import C, annotate  # noqa: E402

N_FRAMES = 60


def build(ctx):
    X = ctx.load("paths_X.csv")
    D = ctx.load("paths_D.csv")
    means = ctx.load("means.csv")
    weights = ctx.load("weights.csv")

    t = X["t"].to_numpy()
    cols = [c for c in X.columns if c != "t"]
    n_hi = int(ctx.param("highlight", 4))
    c = float(ctx.param("c", 0.75))
    T = float(t[-1])

    # Highlight the paths with the largest terminal weight -- these are the
    # ones Q leans on, so the picture should foreground exactly the paths
    # that explain where the reweighted mean comes from.
    order = np.argsort(-weights["weight_norm"].to_numpy())
    hi = [cols[i] for i in order[:n_hi]]

    # The full ensemble (n_paths, often several hundred) is what the bottom
    # panel's weighted/unweighted means are computed from in model.py, but
    # drawing all of it as background context on rows 1-2 bloats the page
    # for no visual gain -- a few hundred faint lines read as one texture.
    # Cap the drawn background at a fixed size, chosen once per render.
    bg_rng = np.random.default_rng(ctx.seed)
    bg_pool = [c_ for c_ in cols if c_ not in hi]
    n_bg = min(120, len(bg_pool))
    rest = list(bg_rng.choice(bg_pool, size=n_bg, replace=False))

    x_lim = float(np.nanmax(np.abs(X[cols].to_numpy()))) * 1.08
    d_lim = float(np.nanmax(D[cols].to_numpy())) * 1.08

    fig = make_subplots(
        rows=3, cols=1, shared_xaxes=True, vertical_spacing=0.08,
        row_heights=[0.38, 0.27, 0.35],
        subplot_titles=(
            "Sample paths of Xₜ = Bₜ + ct, under P",
            "Density process Dₜ = exp(−cBₜ − ½c²t) (= dQ/dP|ℱₜ)",
            "Empirical mean of Xₜ: unweighted (P) vs weighted by Dₜ (Q)",
        ),
    )

    # ---- row 1: static context -------------------------------------------
    for col in rest:
        fig.add_trace(go.Scatter(
            x=t, y=X[col].to_numpy(), mode="lines",
            line=dict(color="rgba(13,148,136,0.12)", width=0.9),
            hoverinfo="skip", showlegend=False,
        ), row=1, col=1)

    fig.add_trace(go.Scatter(
        x=t, y=c * t, mode="lines",
        line=dict(color=C.drift, width=2, dash="dash"),
        name="ct  (P-drift)", hoverinfo="skip",
    ), row=1, col=1)

    # ---- row 2: static context -------------------------------------------
    for col in rest:
        fig.add_trace(go.Scatter(
            x=t, y=D[col].to_numpy(), mode="lines",
            line=dict(color="rgba(13,148,136,0.10)", width=0.9),
            hoverinfo="skip", showlegend=False,
        ), row=2, col=1)

    fig.add_trace(go.Scatter(
        x=t, y=np.ones_like(t), mode="lines",
        line=dict(color=C.theoretical, width=1.6, dash="dash"),
        name="E_P[Dₜ] = 1", hoverinfo="skip",
    ), row=2, col=1)

    # ---- row 3: static, the whole claim in one panel ----------------------
    m = means
    fig.add_trace(go.Scatter(
        x=np.concatenate([m["t"], m["t"][::-1]]),
        y=np.concatenate([m["mean_P"] + m["sd_P"], (m["mean_P"] - m["sd_P"])[::-1]]),
        fill="toself", fillcolor="rgba(244,114,182,0.14)", line=dict(width=0),
        hoverinfo="skip", showlegend=False,
    ), row=3, col=1)
    fig.add_trace(go.Scatter(
        x=np.concatenate([m["t"], m["t"][::-1]]),
        y=np.concatenate([m["mean_Q"] + m["sd_Q"], (m["mean_Q"] - m["sd_Q"])[::-1]]),
        fill="toself", fillcolor="rgba(13,148,136,0.16)", line=dict(width=0),
        hoverinfo="skip", showlegend=False,
    ), row=3, col=1)
    fig.add_trace(go.Scatter(
        x=m["t"], y=m["drift_line"], mode="lines",
        line=dict(color=C.drift, width=1.6, dash="dot"),
        name="ct  (reference)", hoverinfo="skip",
    ), row=3, col=1)
    fig.add_trace(go.Scatter(
        x=m["t"], y=np.zeros_like(m["t"]), mode="lines",
        line=dict(color=C.theoretical, width=1.6, dash="dot"),
        name="0  (reference)", hoverinfo="skip",
    ), row=3, col=1)
    fig.add_trace(go.Scatter(
        x=m["t"], y=m["mean_P"], mode="lines",
        line=dict(color=C.drift, width=2.4),
        name="mean under P", hovertemplate="t=%{x:.3f}<br>mean_P=%{y:.3f}<extra></extra>",
    ), row=3, col=1)
    fig.add_trace(go.Scatter(
        x=m["t"], y=m["mean_Q"], mode="lines",
        line=dict(color=C.empirical, width=2.4),
        name="mean under Q (D-weighted)",
        hovertemplate="t=%{x:.3f}<br>mean_Q=%{y:.3f}<extra></extra>",
    ), row=3, col=1)

    # ---- animated traces: remember their indices ---------------------------
    targets = []

    for i, col in enumerate(hi):
        targets.append(len(fig.data))
        w = weights.loc[weights["path"] == col, "weight_norm"].iloc[0]
        fig.add_trace(go.Scatter(
            x=t, y=X[col].to_numpy(), mode="lines",
            line=dict(color=C.paths[i % len(C.paths)], width=2.1),
            name=f"path {i + 1}  (D_T={w:.2f})",
            hovertemplate="t=%{x:.3f}<br>X=%{y:.3f}<extra></extra>",
        ), row=1, col=1)

    for i, col in enumerate(hi):
        targets.append(len(fig.data))
        fig.add_trace(go.Scatter(
            x=t, y=D[col].to_numpy(), mode="lines",
            line=dict(color=C.paths[i % len(C.paths)], width=2.1),
            showlegend=False,
            hovertemplate="t=%{x:.3f}<br>D=%{y:.3f}<extra></extra>",
        ), row=2, col=1)

    targets.append(len(fig.data))
    fig.add_trace(go.Scatter(
        x=[T, T], y=[-x_lim, x_lim], mode="lines",
        line=dict(color=C.threshold, width=1.2, dash="dot"),
        hoverinfo="skip", showlegend=False,
    ), row=1, col=1)

    targets.append(len(fig.data))
    fig.add_trace(go.Scatter(
        x=[T, T], y=[0, d_lim], mode="lines",
        line=dict(color=C.threshold, width=1.2, dash="dot"),
        hoverinfo="skip", showlegend=False,
    ), row=2, col=1)

    fig.update_xaxes(range=[0, T], row=1, col=1)
    fig.update_xaxes(range=[0, T], row=2, col=1)
    fig.update_xaxes(range=[0, T], title_text="t", row=3, col=1)
    fig.update_yaxes(range=[-x_lim, x_lim], title_text="Xₜ", row=1, col=1)
    fig.update_yaxes(range=[0, d_lim], title_text="Dₜ", row=2, col=1)
    fig.update_yaxes(title_text="mean Xₜ", row=3, col=1)
    fig.update_layout(
        height=980,
        legend=dict(orientation="h", y=1.08, x=1, xanchor="right", font=dict(size=10)),
    )
    annotate(fig, f"{len(cols)} paths   n={len(t) - 1} steps   c={c}   seed={ctx.seed}")

    # ---- frames: only what moves -------------------------------------------
    idx = np.unique(np.linspace(2, len(t) - 1, N_FRAMES).astype(int))
    frames = []
    for k in idx:
        s = slice(0, k + 1)
        data = []
        for i, col in enumerate(hi):
            data.append(go.Scatter(
                x=t[s], y=X[col].to_numpy()[s], mode="lines",
                line=dict(color=C.paths[i % len(C.paths)], width=2.1)))
        for i, col in enumerate(hi):
            data.append(go.Scatter(
                x=t[s], y=D[col].to_numpy()[s], mode="lines",
                line=dict(color=C.paths[i % len(C.paths)], width=2.1)))
        data.append(go.Scatter(
            x=[t[k], t[k]], y=[-x_lim, x_lim], mode="lines",
            line=dict(color=C.threshold, width=1.2, dash="dot")))
        data.append(go.Scatter(
            x=[t[k], t[k]], y=[0, d_lim], mode="lines",
            line=dict(color=C.threshold, width=1.2, dash="dot")))
        frames.append(Frame(name=f"{t[k]:.2f}", data=data, targets=targets))

    return Scene(
        figure=fig, frames=frames, axis_label="t =",
        caption=(
            "Every path here is a genuine P-Brownian path with drift c added on top "
            "-- nothing about an individual path changes. What changes is which paths "
            "matter: Dₜ is large exactly on the paths that drifted less than ct, "
            "so weighting by D_T down-weights the ones that drifted with the crowd and "
            "up-weights the ones that look driftless. The bottom panel shows the "
            "payoff -- the unweighted mean tracks ct, the D-weighted mean sits at 0, "
            "which is Girsanov's theorem: X is a driftless Q-Brownian motion."
        ),
    )

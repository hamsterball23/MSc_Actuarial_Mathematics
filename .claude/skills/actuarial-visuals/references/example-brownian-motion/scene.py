"""
scene.py -- two stacked panels sharing a time axis:
  top     W_t sample paths against the +/- sqrt(t) envelope
  bottom  running quadratic variation against the diagonal [W]_t = t

Animation design note: the ensemble is context and never changes, so it is
drawn once in the base figure. Only the highlighted paths and the time
cursors are animated, via Frame(targets=...). That keeps the page small
enough to open instantly, which is the difference between a tool you use
and one you avoid.
"""

import sys
from pathlib import Path

import numpy as np
import plotly.graph_objects as go
from plotly.subplots import make_subplots

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "_lib"))
from api import Frame, Scene  # noqa: E402
from theme import C, annotate  # noqa: E402

N_FRAMES = 70
W = "\u0057"
SUB_T = "\u209c"


def build(ctx):
    paths = ctx.load("paths.csv")
    qv = ctx.load("qv.csv")
    env = ctx.load("envelope.csv")

    t = paths["t"].to_numpy()
    cols = [c for c in paths.columns if c != "t"]
    n_hi = int(ctx.param("highlight", 3))
    hi, rest = cols[:n_hi], cols[n_hi:]
    T = float(t[-1])
    lim = float(np.nanmax(np.abs(paths[cols].to_numpy()))) * 1.08

    fig = make_subplots(
        rows=2, cols=1, shared_xaxes=True, vertical_spacing=0.10,
        subplot_titles=(f"Sample paths of {W}{SUB_T}",
                        f"Running quadratic variation [{W}]{SUB_T}"),
    )

    # ---- static context: drawn once, never re-sent in frames -------------
    fig.add_trace(go.Scatter(
        x=np.concatenate([t, t[::-1]]),
        y=np.concatenate([env["band"].to_numpy(), -env["band"].to_numpy()[::-1]]),
        fill="toself", fillcolor="rgba(148,163,184,0.18)", line=dict(width=0),
        name="\u00b1\u221at", hoverinfo="skip",
    ), row=1, col=1)

    for c in rest:
        fig.add_trace(go.Scatter(
            x=t, y=paths[c].to_numpy(), mode="lines",
            line=dict(color="rgba(13,148,136,0.16)", width=0.9),
            hoverinfo="skip", showlegend=False,
        ), row=1, col=1)

    fig.add_trace(go.Scatter(
        x=t, y=t, mode="lines",
        line=dict(color=C.theoretical, width=2, dash="dash"),
        name=f"[{W}]{SUB_T} = t", hoverinfo="skip",
    ), row=2, col=1)

    for c in rest:
        fig.add_trace(go.Scatter(
            x=t, y=qv[c].to_numpy(), mode="lines",
            line=dict(color="rgba(13,148,136,0.16)", width=0.9),
            hoverinfo="skip", showlegend=False,
        ), row=2, col=1)

    # ---- animated traces: remember their indices -------------------------
    targets = []

    for i, c in enumerate(hi):
        targets.append(len(fig.data))
        fig.add_trace(go.Scatter(
            x=t, y=paths[c].to_numpy(), mode="lines",
            line=dict(color=C.paths[i % len(C.paths)], width=2.1),
            name=f"path {i + 1}",
            hovertemplate="t=%{x:.3f}<br>W=%{y:.3f}<extra></extra>",
        ), row=1, col=1)

    for i, c in enumerate(hi):
        targets.append(len(fig.data))
        fig.add_trace(go.Scatter(
            x=t, y=qv[c].to_numpy(), mode="lines",
            line=dict(color=C.paths[i % len(C.paths)], width=2.1),
            showlegend=False,
            hovertemplate="t=%{x:.3f}<br>[W]=%{y:.3f}<extra></extra>",
        ), row=2, col=1)

    targets.append(len(fig.data))
    fig.add_trace(go.Scatter(
        x=[T, T], y=[-lim, lim], mode="lines",
        line=dict(color=C.threshold, width=1.2, dash="dot"),
        hoverinfo="skip", showlegend=False,
    ), row=1, col=1)

    targets.append(len(fig.data))
    fig.add_trace(go.Scatter(
        x=[T, T], y=[0, T * 1.35], mode="lines",
        line=dict(color=C.threshold, width=1.2, dash="dot"),
        hoverinfo="skip", showlegend=False,
    ), row=2, col=1)

    fig.update_xaxes(range=[0, T], row=1, col=1)
    fig.update_xaxes(range=[0, T], title_text="t", row=2, col=1)
    fig.update_yaxes(range=[-lim, lim], title_text=f"{W}{SUB_T}", row=1, col=1)
    fig.update_yaxes(range=[0, T * 1.35], title_text=f"[{W}]{SUB_T}", row=2, col=1)
    fig.update_layout(
        height=700,
        legend=dict(orientation="h", y=1.11, x=1, xanchor="right"),
    )
    annotate(fig, f"{len(cols)} paths   n={len(t) - 1} steps   seed={ctx.seed}")

    # ---- frames: only what moves ----------------------------------------
    idx = np.unique(np.linspace(2, len(t) - 1, N_FRAMES).astype(int))
    frames = []
    for k in idx:
        s = slice(0, k + 1)
        data = []
        for i, c in enumerate(hi):
            data.append(go.Scatter(
                x=t[s], y=paths[c].to_numpy()[s], mode="lines",
                line=dict(color=C.paths[i % len(C.paths)], width=2.1)))
        for i, c in enumerate(hi):
            data.append(go.Scatter(
                x=t[s], y=qv[c].to_numpy()[s], mode="lines",
                line=dict(color=C.paths[i % len(C.paths)], width=2.1)))
        data.append(go.Scatter(
            x=[t[k], t[k]], y=[-lim, lim], mode="lines",
            line=dict(color=C.threshold, width=1.2, dash="dot")))
        data.append(go.Scatter(
            x=[t[k], t[k]], y=[0, T * 1.35], mode="lines",
            line=dict(color=C.threshold, width=1.2, dash="dot")))
        frames.append(Frame(name=f"{t[k]:.2f}", data=data, targets=targets))

    return Scene(
        figure=fig, frames=frames, axis_label="t =",
        caption=("The ensemble fans out like \u221at, but every individual path's "
                 "quadratic variation tracks the same diagonal. That pathwise "
                 f"rigidity is what makes d{W}\u00b7d{W} = dt a usable rule rather "
                 "than a statement about averages."),
    )
